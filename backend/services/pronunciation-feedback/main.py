"""
Pronunciation feedback microservice.

Uses Azure Speech Services (scripted pronunciation assessment) to score a learner's
audio against reference text. Accepts WAV uploads and reference text; returns the
full Azure pronunciation assessment JSON (scores, words, phonemes, etc.).

Prosody assessment is enabled for every /assess call. The prosody data is cached
server-side (keyed by feedback_session_id) for use by /ai-feedback, but is never
included in the /assess response sent to the app.

/ai-feedback accepts the assessment JSON plus a feedback_session_id, looks up
cached prosody, and calls Gemini to produce 2–3 actionable improvement sentences.
"""

import json
import os
import tempfile
import uuid
import wave
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional

import azure.cognitiveservices.speech as speechsdk
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from google import genai
from google.genai import types
from pydantic import BaseModel
from pydantic_settings import BaseSettings

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
MAX_AUDIO_DURATION_SECONDS = 10
LOCALE = "en-US"
CACHE_TTL_MINUTES = 10

# ---------------------------------------------------------------------------
# In-memory prosody cache:  session_id → { "prosody": dict|None, "expires": datetime }
# Entries are pruned on every /assess call to avoid unbounded growth.
# ---------------------------------------------------------------------------
_session_cache: dict[str, dict] = {}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _prune_cache() -> None:
    """Remove expired entries from the in-memory session cache."""
    now = datetime.now(tz=timezone.utc)
    expired = [k for k, v in _session_cache.items() if v["expires"] < now]
    for k in expired:
        del _session_cache[k]


def _extract_prosody(raw: dict) -> Optional[dict]:
    """
    Pull prosody scores out of the raw Azure JSON.

    Azure places prosody inside PronunciationAssessment.Prosody when
    enable_prosody_assessment() is active.  Returns None when absent.
    """
    nbest = (raw or {}).get("NBest") or []
    best = nbest[0] if nbest else {}
    pa = best.get("PronunciationAssessment") or {}
    return pa.get("Prosody")


def _clean_pronunciation_result(raw: dict) -> dict:
    """
    Transform the raw Azure pronunciation JSON into a compact, easy-to-consume
    structure focused on word- and phoneme-level scores.

    Prosody is intentionally excluded from this output — it is cached
    separately via _session_cache and used only by /ai-feedback.

    Output format:
    {
        "summary": {
            "accuracy": float | None,
            "fluency": float | None,
            "completeness": float | None,
            "pronScore": float | None,
        },
        "words": [
            {
                "text": str,
                "accuracy": float | None,
                "errorType": str | None,
                "phonemes": [
                    {
                        "symbol": str,
                        "accuracy": float | None,
                        "user_said": str | None,
                    },
                    ...
                ],
            },
            ...
        ],
    }
    """
    nbest = (raw or {}).get("NBest") or []
    best = nbest[0] if nbest else {}

    pa = best.get("PronunciationAssessment") or {}
    summary = {
        "accuracy": pa.get("AccuracyScore"),
        "fluency": pa.get("FluencyScore"),
        "completeness": pa.get("CompletenessScore"),
        "pronScore": pa.get("PronScore"),
    }

    words_clean = []
    for w in best.get("Words") or []:
        w_pa = w.get("PronunciationAssessment") or {}
        phonemes_clean = []
        for p in w.get("Phonemes") or []:
            p_pa = p.get("PronunciationAssessment") or {}
            nbest_phonemes = p_pa.get("NBestPhonemes") or []
            user_said = nbest_phonemes[0].get("Phoneme") if nbest_phonemes else None
            phonemes_clean.append(
                {
                    "symbol": p.get("Phoneme"),
                    "accuracy": p_pa.get("AccuracyScore"),
                    "user_said": user_said,
                }
            )
        words_clean.append(
            {
                "text": w.get("Word"),
                "accuracy": w_pa.get("AccuracyScore"),
                "errorType": w_pa.get("ErrorType"),
                "phonemes": phonemes_clean,
            }
        )

    return {"summary": summary, "words": words_clean}


# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------

class Settings(BaseSettings):
    """
    Application settings loaded from environment variables and optional .env file.
    """
    azure_speech_key: str = ""
    azure_speech_region: str = ""
    gemini_api_key: str = ""
    gemini_model: str = "gemini-2.5-flash"

    class Config:
        env_prefix = ""
        env_file = ".env"


app = FastAPI(
    title="Pronunciation Feedback",
    description="Microservice for pronunciation assessment and feedback (Azure Speech, scripted, en-US).",
    version="0.2.0",
)
settings = Settings()


# ---------------------------------------------------------------------------
# Audio helpers
# ---------------------------------------------------------------------------

def get_wav_duration_seconds(path: Path) -> float:
    """Read the duration of a WAV file in seconds using the standard library wave module."""
    with wave.open(str(path), "rb") as wav:
        frames = wav.getnframes()
        rate = wav.getframerate()
        return frames / float(rate)


# How much silence (in seconds) to prepend and append to the audio before
# sending to Azure.  Azure's acoustic model scores each phoneme using
# neighbouring-phoneme context (coarticulation); without any context the
# first and last phonemes in an utterance are systematically under-scored.
# 250 ms of silence on each side is enough to give the model that context
# window without meaningfully affecting fluency or duration metrics.
SILENCE_PAD_SECONDS = 0.25


def pad_wav_with_silence(src: Path, dst: Path, pad_seconds: float = SILENCE_PAD_SECONDS) -> None:
    """
    Copy *src* WAV to *dst*, prepending and appending *pad_seconds* of silence.

    The silence is generated as zero-valued PCM frames matching the source
    file's sample width, channels, and frame rate, so Azure sees a valid,
    consistently-formatted file.
    """
    with wave.open(str(src), "rb") as r:
        params = r.getparams()
        frames = r.readframes(r.getnframes())

    pad_frame_count = int(params.framerate * pad_seconds)
    silent_frames = b"\x00" * pad_frame_count * params.nchannels * params.sampwidth

    with wave.open(str(dst), "wb") as w:
        w.setparams(params)
        w.writeframes(silent_frames + frames + silent_frames)


# ---------------------------------------------------------------------------
# Azure assessment
# ---------------------------------------------------------------------------

def run_pronunciation_assessment(audio_path: Path, reference_text: str) -> tuple[dict, Optional[dict]]:
    """
    Run Azure Speech scripted pronunciation assessment on an audio file.

    Returns a tuple of:
      - cleaned result dict (summary + words, no prosody)
      - raw prosody dict (or None if absent / not supported)
    """
    speech_config = speechsdk.SpeechConfig(
        subscription=settings.azure_speech_key,
        region=settings.azure_speech_region,
    )

    # Pad the audio with silence so boundary phonemes (first / last in the
    # utterance) receive the coarticulation context the acoustic model needs.
    # Without this, Azure consistently under-scores them — an artefact of the
    # model, not the learner's actual pronunciation.
    padded_path = audio_path.with_suffix(".padded.wav")
    pad_wav_with_silence(audio_path, padded_path)

    try:
        audio_config = speechsdk.audio.AudioConfig(filename=str(padded_path))
        speech_recognizer = speechsdk.SpeechRecognizer(
            speech_config=speech_config,
            language=LOCALE,
            audio_config=audio_config,
        )
        pronunciation_config = speechsdk.PronunciationAssessmentConfig(
            reference_text=reference_text.strip(),
            grading_system=speechsdk.PronunciationAssessmentGradingSystem.HundredMark,
            granularity=speechsdk.PronunciationAssessmentGranularity.Phoneme,
            enable_miscue=True,
        )
        pronunciation_config.nbest_phoneme_count = 5
        # Enable prosody — enriches the raw result used by Gemini, but is NOT
        # forwarded to the app.
        pronunciation_config.enable_prosody_assessment()
        pronunciation_config.apply_to(speech_recognizer)

        result = speech_recognizer.recognize_once()
        if result.reason != speechsdk.ResultReason.RecognizedSpeech:
            raise HTTPException(
                status_code=422,
                detail={
                    "reason": str(result.reason),
                    "error": result.properties.get(
                        speechsdk.PropertyId.SpeechServiceResponse_JsonResult, ""
                    )
                    or getattr(result, "error_details", None)
                    or "Speech recognition failed.",
                },
            )
        json_str = result.properties.get(
            speechsdk.PropertyId.SpeechServiceResponse_JsonResult, "{}"
        )
        raw = json.loads(json_str)
        return _clean_pronunciation_result(raw), _extract_prosody(raw)
    finally:
        padded_path.unlink(missing_ok=True)


# ---------------------------------------------------------------------------
# Gemini AI feedback
# ---------------------------------------------------------------------------

def _build_feedback_prompt(
    summary: dict,
    words: list,
    prosody: Optional[dict],
    reference_text: Optional[str],
) -> str:
    """Build a prompt for Gemini based on the full pronunciation assessment data."""
    assessment_payload: dict = {
        "summary": summary,
        "words": words,
    }
    if prosody:
        assessment_payload["prosody"] = prosody

    assessment_json = json.dumps(assessment_payload, indent=2)

    reference_line = (
        f'The learner was asked to say: "{reference_text}"\n\n'
        if reference_text
        else ""
    )

    return f"""You are an English pronunciation coach giving brief, encouraging feedback.

A learner just completed a pronunciation assessment.
{reference_line}Key for the JSON below (use this to understand the data only — never output these codes):
- Phoneme symbols are ARPAbet (e.g. "th", "dh", "ae", "iy"). "symbol" is the target phoneme; "user_said" is what the learner actually produced. Use these to understand what went wrong, but describe the issue in plain English in your output.
- Scores are 0–100: ≥85 is good, 60–84 is borderline, <60 is poor.
- errorType values: "None" = correct, "Omission" = word skipped, "Insertion" = extra word, "Mispronunciation" = wrong sounds.

Full assessment JSON:
{assessment_json}

Identify the ACTUAL errors in the data, then give exactly 2 to 3 short, actionable sentences addressing them.

Error priority — address in this order, stopping once you have 2–3 tips:
1. Substitutions on stressed vowels or word-medial phonemes — these change how the word sounds most noticeably to a listener (e.g. saying "prEEshure" instead of "prEshure" because the vowel was wrong).
2. Omissions: words with errorType "Omission" — skipped words.
3. Other substitutions: user_said differs from symbol on consonants or unstressed positions.
4. Low-accuracy phonemes: accuracy < 60 that are NOT substitutions.
5. Weak final consonants or unstressed phonemes: only if no higher-priority errors remain — these are the least perceptually impactful.

CRITICAL — errors only:
- Only mention phonemes or words that have a real problem in the data (accuracy < 85, substitution, or omission).
- Do NOT mention phonemes or words that scored ≥ 85 or have no errorType — do not invent problems.
- Focus on the 2–3 worst issues maximum. Do not try to cover everything.

CRITICAL OUTPUT RULES:
- NEVER use ARPAbet or IPA symbols in your output (no "ae", "dh", "th", "iy", slashes, brackets, etc.).
- Describe sounds using plain everyday English: "the 'uh' sound in 'cup'", "the 'sh' in 'pressure'", "the long 'ee' in 'feet'".
- Always reference the actual word from the sentence, not just the sound in isolation.
- Each sentence must be under 20 words.
- Be encouraging but direct.
- Do not use markdown, bullet points, or numbering — just plain sentences.

Return ONLY valid JSON in exactly this shape, with no extra text:
{{"suggestions": ["sentence 1", "sentence 2", "sentence 3"]}}"""


def generate_ai_feedback(
    summary: dict,
    words: list,
    prosody: Optional[dict],
    reference_text: Optional[str] = None,
) -> list[str]:
    """Call Gemini and return 2–3 feedback suggestion strings."""
    api_key = settings.gemini_api_key
    if not api_key:
        raise HTTPException(status_code=503, detail="GEMINI_API_KEY is not configured")

    client = genai.Client(api_key=api_key)
    prompt = _build_feedback_prompt(summary, words, prosody, reference_text)

    resp = client.models.generate_content(
        model=settings.gemini_model,
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            temperature=0.4,
        ),
    )

    try:
        text = resp.text.strip()
        # Strip optional markdown fences
        if text.startswith("```"):
            text = text.split("```")[1]
            if text.startswith("json"):
                text = text[4:]
        data = json.loads(text)
        suggestions = data.get("suggestions") or []
        if not suggestions:
            raise ValueError("Empty suggestions list")
        return [str(s) for s in suggestions[:3]]
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Failed to parse Gemini response: {exc}",
        ) from exc


# ---------------------------------------------------------------------------
# Request / response schemas
# ---------------------------------------------------------------------------

class PhonemeItem(BaseModel):
    symbol: str
    accuracy: Optional[float] = None
    user_said: Optional[str] = None


class WordItem(BaseModel):
    text: str
    accuracy: Optional[float] = None
    errorType: Optional[str] = None
    phonemes: list[PhonemeItem] = []


class AssessmentSummary(BaseModel):
    accuracy: Optional[float] = None
    fluency: Optional[float] = None
    completeness: Optional[float] = None
    pronScore: Optional[float] = None


class AiFeedbackRequest(BaseModel):
    feedback_session_id: str
    summary: AssessmentSummary
    words: list[WordItem] = []


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.get("/")
def root():
    """Simple service info for discovery or load balancer checks."""
    return {"service": "pronunciation-feedback", "status": "ok"}


@app.get("/health")
def health():
    """Health check endpoint."""
    return {"status": "healthy"}


@app.post("/assess")
async def assess(
    audio: UploadFile = File(..., description="WAV audio file (max 10 seconds)"),
    reference_text: str = Form(..., description="Ground truth text the learner should say"),
):
    """
    Assess pronunciation of uploaded audio against reference text.

    Returns the cleaned assessment JSON plus a feedback_session_id that can be
    passed to /ai-feedback.  Prosody data is cached server-side under that ID
    but is NOT included in this response.
    """
    if not reference_text or not reference_text.strip():
        raise HTTPException(status_code=400, detail="reference_text is required")
    if not audio.filename or not audio.filename.lower().endswith(".wav"):
        raise HTTPException(
            status_code=400,
            detail="Audio file must be WAV (filename must end with .wav)",
        )
    if not settings.azure_speech_key or not settings.azure_speech_region:
        raise HTTPException(
            status_code=503,
            detail="Azure Speech is not configured (AZURE_SPEECH_KEY, AZURE_SPEECH_REGION)",
        )

    # Prune stale cache entries before adding new ones.
    _prune_cache()

    content = await audio.read()
    suffix = Path(audio.filename).suffix or ".wav"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        tmp.write(content)
        tmp_path = Path(tmp.name)

    try:
        try:
            duration = get_wav_duration_seconds(tmp_path)
        except Exception as e:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid WAV file or unable to read duration: {e!s}",
            ) from e
        if duration > MAX_AUDIO_DURATION_SECONDS:
            raise HTTPException(
                status_code=400,
                detail=f"Audio duration {duration:.1f}s exceeds maximum {MAX_AUDIO_DURATION_SECONDS}s",
            )

        cleaned, prosody = run_pronunciation_assessment(tmp_path, reference_text)

        # Cache prosody + reference text for use by /ai-feedback.
        session_id = str(uuid.uuid4())
        _session_cache[session_id] = {
            "prosody": prosody,
            "reference_text": reference_text.strip(),
            "expires": datetime.now(tz=timezone.utc) + timedelta(minutes=CACHE_TTL_MINUTES),
        }

        return {**cleaned, "feedback_session_id": session_id}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Assessment failed: {e!s}")
    finally:
        tmp_path.unlink(missing_ok=True)


@app.post("/ai-feedback")
async def ai_feedback(body: AiFeedbackRequest):
    """
    Generate 2–3 actionable AI feedback sentences for a completed assessment.

    Looks up prosody data from the in-memory cache using feedback_session_id
    (best-effort — feedback is still generated if the session has expired).
    Calls Gemini and returns the suggestions.
    """
    cached = _session_cache.get(body.feedback_session_id)
    prosody: Optional[dict] = None
    reference_text: Optional[str] = None
    if cached and cached["expires"] > datetime.now(tz=timezone.utc):
        prosody = cached.get("prosody")
        reference_text = cached.get("reference_text")

    summary_dict = body.summary.model_dump()
    words_list = [w.model_dump() for w in body.words]

    suggestions = generate_ai_feedback(summary_dict, words_list, prosody, reference_text)
    return {"suggestions": suggestions}
