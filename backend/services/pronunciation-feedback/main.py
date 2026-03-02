"""
Pronunciation feedback microservice.

Uses Azure Speech Services (scripted pronunciation assessment) to score a learner's
audio against reference text. Accepts WAV uploads and reference text; returns the
full Azure pronunciation assessment JSON (scores, words, phonemes, etc.).
"""

import json
import tempfile
import wave
from pathlib import Path

import azure.cognitiveservices.speech as speechsdk
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from pydantic_settings import BaseSettings

# Maximum allowed duration for uploaded audio (seconds). Longer clips are rejected.
MAX_AUDIO_DURATION_SECONDS = 10
# Locale used for Azure Speech; scripted assessment is en-US only for this service.
LOCALE = "en-US"


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables and optional .env file.
    Used for Azure Speech credentials; empty defaults allow the app to start
    and return 503 if /assess is called without config.
    """
    azure_speech_key: str = ""
    azure_speech_region: str = ""

    class Config:
        env_prefix = ""
        # Load .env from the current working directory when the app starts.
        env_file = ".env"


app = FastAPI(
    title="Pronunciation Feedback",
    description="Microservice for pronunciation assessment and feedback (Azure Speech, scripted, en-US).",
    version="0.1.0",
)
settings = Settings()


def get_wav_duration_seconds(path: Path) -> float:
    """
    Read the duration of a WAV file in seconds using the standard library wave module.
    Raises if the file is not valid WAV or cannot be read.
    """
    with wave.open(str(path), "rb") as wav:
        frames = wav.getnframes()
        rate = wav.getframerate()
        return frames / float(rate)


def run_pronunciation_assessment(audio_path: Path, reference_text: str) -> dict:
    """
    Run Azure Speech scripted pronunciation assessment on an audio file.

    Configures the Speech SDK with credentials, creates a recognizer with
    pronunciation assessment (reference text, 0-100 grading, phoneme-level detail),
    runs recognize_once(), and returns the full JSON result from Azure.
    """
    speech_config = speechsdk.SpeechConfig(
        subscription=settings.azure_speech_key,
        region=settings.azure_speech_region,
    )
    audio_config = speechsdk.audio.AudioConfig(filename=str(audio_path))
    speech_recognizer = speechsdk.SpeechRecognizer(
        speech_config=speech_config,
        language=LOCALE,
        audio_config=audio_config,
    )
    pronunciation_config = speechsdk.PronunciationAssessmentConfig(
        reference_text=reference_text.strip(),
        grading_system=speechsdk.PronunciationAssessmentGradingSystem.HundredMark,
        granularity=speechsdk.PronunciationAssessmentGranularity.Phoneme,
        enable_miscue=False,
    )
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
    return json.loads(json_str)


@app.get("/")
def root():
    """Simple service info for discovery or load balancer checks."""
    return {"service": "pronunciation-feedback", "status": "ok"}


@app.get("/health")
def health():
    """Health check endpoint (e.g. for Kubernetes or Docker healthchecks)."""
    return {"status": "healthy"}


@app.post("/assess")
async def assess(
    audio: UploadFile = File(..., description="WAV audio file (max 10 seconds)"),
    reference_text: str = Form(..., description="Ground truth text the learner should say"),
):
    """
    Assess pronunciation of uploaded audio against reference text.

    Validates: reference_text non-empty, audio is WAV, duration <= 10s, Azure
    config present. Writes upload to a temp file, runs Azure assessment, returns
    the full Azure JSON (AccuracyScore, FluencyScore, Words, Phonemes, etc.).
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
        return run_pronunciation_assessment(tmp_path, reference_text)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Assessment failed: {e!s}")
    finally:
        tmp_path.unlink(missing_ok=True)
