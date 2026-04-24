"""
ai_service.py

AI Course Generation Service

Purpose:
- Contain the business logic for generating structured course content from a prompt.
- Use Gemini as the primary generation engine.
- Optionally fall back to a deterministic stub when configured to do so.
- Select a representative course image URL based on the generated title.

Architecture:
Gateway → AI Course Gen Router → AI Service (this file) → Gemini API

Role in the system:
- This service generates course structure.
- This service also selects a course image URL using local service logic.
- It does NOT own database tables and does NOT persist courses, lessons, or items.
- Persistence should be handled by the courses service, which owns that data.

Environment Variables:
- GEMINI_API_KEY
- GEMINI_MODEL (default: gemini-2.5-flash)
- ALLOW_STUB_FALLBACK (default: true)

Design Notes:
- Gemini is the primary path.
- Stub fallback exists for local development and resilience during Sprint 1.
- In production, ALLOW_STUB_FALLBACK can be disabled so failures surface clearly.
"""

from __future__ import annotations

import json
import os
import re
import textwrap
from typing import List

from google import genai
from google.genai import types

from ..schemas.generate_schema import Lesson, LessonItem
from .image_selection_service import select_course_image
from ..clients.supabase import rest_get


# Maximum number of weak phonemes to include in one targeted course.
_MAX_TARGET_PHONEMES = 5

# Minimum practice attempts required for a phoneme to be considered meaningful data.
# Phonemes below this threshold are excluded unless no others are available.
_MIN_ATTEMPTS_PREFERRED = 3


# -------------------------
# Stub (fallback)
# -------------------------

def stub_generate_lessons(prompt: str) -> List[Lesson]:
    """
    Deterministically generate simple lesson content from a prompt.

    Purpose:
    - Provide a non-LLM fallback path for development or temporary outages.
    - Return predictable lesson structure that still matches the API schema.

    Notes:
    - This is intentionally simple and low-quality compared to Gemini.
    - It should be used only when fallback is enabled.
    """
    lessons: List[Lesson] = []

    for i, section in enumerate(
        ["Intro & key vocabulary", "Pronunciation practice", "Practice phrases"],
        start=1,
    ):
        lesson_title = f"Lesson {i}: {section}"

        words = [w for w in textwrap.shorten(prompt, width=60).split() if len(w) > 2][:4]
        if not words:
            words = ["phrase", "word"]

        items: List[LessonItem] = []
        for w in words[:2]:
            items.append(LessonItem(text=f"{w} — example phrase using {w}", ipa=None, hint=None))

        lessons.append(Lesson(title=lesson_title, items=items))

    return lessons


# -------------------------
# Gemini (primary)
# -------------------------

_JSON_SHAPE_INSTRUCTIONS = """
Return ONLY valid JSON (no markdown, no backticks, no explanation) in EXACTLY this shape:

{
  "title": string,
  "lessons": [
    {
      "title": string,
      "items": [
        { "text": string, "ipa": string|null, "hint": string|null }
      ]
    }
  ]
}

Non-negotiable Rules:
- 3 to 6 lessons
- 3 to 8 items per lesson
- Keep item text short and practical (phrases/words/sentences)
- Use null for ipa/hint when not provided
- No extra keys anywhere
- Always use the English language
- Avoid any acronyms
- No placeholders for lessons
""".strip()


def _strip_code_fences(s: str) -> str:
    """
    Remove surrounding markdown code fences from model output.

    Why:
    - Even when asked for raw JSON, LLMs sometimes wrap results in ```json fences.
    - Stripping fences improves JSON parsing robustness.
    """
    s = s.strip()
    if s.startswith("```"):
        s = re.sub(r"^```[a-zA-Z0-9_-]*\s*", "", s)
        s = re.sub(r"\s*```$", "", s)
    return s.strip()


def _validate_and_normalize(payload: dict) -> dict:
    """
    Validate and normalize model output into the exact response shape.

    Responsibilities:
    - Ensure the top-level payload is a dict.
    - Validate presence and basic types of title and lessons.
    - Filter out malformed lessons/items instead of trusting raw model output.
    - Normalize whitespace and coerce invalid ipa/hint values to None.

    Why this matters:
    - LLM output is probabilistic and may not fully match the requested schema.
    - This function acts as a guardrail before returning data to the router.
    """
    if not isinstance(payload, dict):
        raise ValueError("Gemini output is not a JSON object")

    title = payload.get("title")
    lessons = payload.get("lessons")

    if not isinstance(title, str) or not title.strip():
        raise ValueError("Missing/invalid title")

    if not isinstance(lessons, list) or len(lessons) == 0:
        raise ValueError("Missing/invalid lessons")

    normalized_lessons = []
    for l in lessons:
        if not isinstance(l, dict):
            continue

        lt = l.get("title")
        items = l.get("items")

        if not isinstance(lt, str) or not lt.strip():
            continue
        if not isinstance(items, list) or len(items) == 0:
            continue

        normalized_items = []
        for it in items:
            if not isinstance(it, dict):
                continue

            text = it.get("text")
            if not isinstance(text, str) or not text.strip():
                continue

            ipa = it.get("ipa")
            hint = it.get("hint")

            normalized_items.append(
                {
                    "text": text.strip(),
                    "ipa": ipa if ipa is None or isinstance(ipa, str) else None,
                    "hint": hint if hint is None or isinstance(hint, str) else None,
                }
            )

        if normalized_items:
            normalized_lessons.append(
                {
                    "title": lt.strip(),
                    "items": normalized_items,
                }
            )

    if not normalized_lessons:
        raise ValueError("No valid lessons/items after normalization")

    normalized_title = title.strip()
    return {
        "title": normalized_title,
        "image_url": select_course_image(normalized_title),
        "lessons": normalized_lessons,
    }


def _gemini_generate(prompt: str) -> dict:
    """
    Generate course content using Gemini and return normalized JSON.

    Flow:
    1. Read API key and model name from environment.
    2. Build a strict prompt requesting exact JSON output.
    3. Call Gemini with response_mime_type set to application/json.
    4. Parse the response as JSON.
    5. If JSON is invalid, ask Gemini once to repair it.
    6. Validate and normalize the final payload.
    7. Select an image URL based on the generated title.

    Error Behavior:
    - Raises if the API key is missing.
    - Raises if generation/parsing/validation fails.
    """
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not set")

    model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    client = genai.Client(api_key=api_key)

    full_prompt = f"""
You are generating a structured course for a language learning app.

{_JSON_SHAPE_INSTRUCTIONS}

User request:
{prompt.strip()}
""".strip()

    resp = client.models.generate_content(
        model=model_name,
        contents=full_prompt,
        config=types.GenerateContentConfig(response_mime_type="application/json"),
    )

    text = _strip_code_fences((getattr(resp, "text", "") or "").strip())

    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        repair_prompt = f"""
You returned INVALID JSON.

Fix it and return ONLY valid JSON matching EXACTLY this shape (no markdown, no extra text):
{_JSON_SHAPE_INSTRUCTIONS}

Here is your invalid output:
{text}
""".strip()

        resp2 = client.models.generate_content(
            model=model_name,
            contents=repair_prompt,
            config=types.GenerateContentConfig(response_mime_type="application/json"),
        )
        text2 = _strip_code_fences((getattr(resp2, "text", "") or "").strip())
        data = json.loads(text2)

    return _validate_and_normalize(data)


# -------------------------
# Public entrypoint
# -------------------------

def _env_truthy(name: str, default: bool = True) -> bool:
    """
    Interpret an environment variable as a boolean.

    Truthy values:
    - 1, true, yes, y, on

    Used for:
    - Feature flags like ALLOW_STUB_FALLBACK
    """
    val = os.getenv(name)
    if val is None:
        return default
    return val.strip().lower() in ("1", "true", "yes", "y", "on")


def generate_course_from_prompt(prompt: str) -> dict:
    """
    Public entrypoint for course generation.

    Strategy:
    - Primary path: Gemini LLM
    - Fallback path: deterministic stub, only if ALLOW_STUB_FALLBACK is enabled

    Flow:
    1. Clean and validate prompt.
    2. Read fallback flag from environment.
    3. Try Gemini generation.
    4. If Gemini fails:
       - Raise immediately if fallback is disabled
       - Otherwise log failure and return stub-generated content
    5. Select an image URL based on the generated or stub title.

    Notes:
    - Stub output is intentionally lower quality and meant mainly for development.
    - In production, disabling fallback can help catch real failures early.
    """
    prompt_clean = prompt.strip()
    if not prompt_clean:
        raise ValueError("Prompt must be non-empty")

    allow_fallback = _env_truthy("ALLOW_STUB_FALLBACK", default=True)

    try:
        return _gemini_generate(prompt_clean)
    except Exception as e:
        if not allow_fallback:
            print("Gemini failed and fallback disabled:", repr(e), flush=True)
            raise RuntimeError(str(e)) from e

        print("Gemini failed, falling back to stub:", repr(e), flush=True)
        title = f"[STUB] {prompt_clean[:60]}".strip() or "[STUB] New Course"
        lessons = stub_generate_lessons(prompt_clean)

        return {
            "title": title,
            "image_url": select_course_image(title),
            "lessons": [lesson.dict() for lesson in lessons],
        }


# -------------------------
# Group session items
# -------------------------

_SESSION_ITEMS_SHAPE = """
Return ONLY valid JSON (no markdown, no backticks, no explanation) in EXACTLY this shape:

{
  "items": [
    { "text": string, "ipa": string|null, "hint": string|null }
  ]
}

Non-negotiable Rules:
- Exactly 20 items
- Each item text must be a short, practical phrase or sentence (phrases/words/sentences)
- Keep item text concise (3 to 12 words)
- Vary the difficulty and sentence structure across the 20 items
- Use null for ipa/hint when not provided
- No extra keys anywhere
- Always use the English language
- Avoid any acronyms
- No placeholders
""".strip()


def _validate_session_items(payload: dict) -> list[dict]:
    """
    Validate and normalize a flat list of session items from Gemini output.

    Filters out any items missing valid text. Returns at most 20 items.
    """
    if not isinstance(payload, dict):
        raise ValueError("Gemini output is not a JSON object")

    raw = payload.get("items")
    if not isinstance(raw, list) or len(raw) == 0:
        raise ValueError("Missing/invalid items list")

    normalized = []
    for it in raw:
        if not isinstance(it, dict):
            continue
        text = it.get("text")
        if not isinstance(text, str) or not text.strip():
            continue
        ipa = it.get("ipa")
        hint = it.get("hint")
        normalized.append({
            "text": text.strip(),
            "ipa": ipa if ipa is None or isinstance(ipa, str) else None,
            "hint": hint if hint is None or isinstance(hint, str) else None,
        })

    if not normalized:
        raise ValueError("No valid items after normalization")

    return normalized[:20]


def generate_session_items(topic: str) -> list[dict]:
    """
    Generate 20 short phrases/sentences for a group pronunciation session.

    Args:
    - topic: A short topic string to guide the LLM (e.g. "Daily routines").

    Returns:
    - List of up to 20 dicts, each with keys: text, ipa (nullable), hint (nullable).

    Falls back to simple stub items if Gemini fails and ALLOW_STUB_FALLBACK is enabled.
    """
    topic_clean = topic.strip()
    if not topic_clean:
        raise ValueError("Topic must be non-empty")

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not set")

    model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    client = genai.Client(api_key=api_key)

    full_prompt = f"""
You are generating pronunciation practice content for a group language learning session.

{_SESSION_ITEMS_SHAPE}

Topic to base the items on: {topic_clean}
""".strip()

    allow_fallback = _env_truthy("ALLOW_STUB_FALLBACK", default=True)

    try:
        resp = client.models.generate_content(
            model=model_name,
            contents=full_prompt,
            config=types.GenerateContentConfig(response_mime_type="application/json"),
        )
        text = _strip_code_fences((getattr(resp, "text", "") or "").strip())

        try:
            data = json.loads(text)
        except json.JSONDecodeError:
            repair_prompt = f"""
You returned INVALID JSON.

Fix it and return ONLY valid JSON matching EXACTLY this shape (no markdown, no extra text):
{_SESSION_ITEMS_SHAPE}

Here is your invalid output:
{text}
""".strip()
            resp2 = client.models.generate_content(
                model=model_name,
                contents=repair_prompt,
                config=types.GenerateContentConfig(response_mime_type="application/json"),
            )
            text2 = _strip_code_fences((getattr(resp2, "text", "") or "").strip())
            data = json.loads(text2)

        return _validate_session_items(data)

    except Exception as e:
        if not allow_fallback:
            print("Gemini session items failed and fallback disabled:", repr(e), flush=True)
            raise RuntimeError(str(e)) from e

        print("Gemini session items failed, falling back to stub:", repr(e), flush=True)
        stub_phrases = [
            f"Practice phrase {i + 1} about {topic_clean}." for i in range(20)
        ]
        return [{"text": p, "ipa": None, "hint": None} for p in stub_phrases]


# -------------------------
# Metrics-based generation
# -------------------------

def _fetch_weak_phonemes(user_id: str) -> list[dict]:
    """
    Fetch the user's weakest phonemes from user_phoneme_metrics.

    Strategy:
    1. Query all phoneme rows for the user, ordered by accuracy ascending.
    2. Prefer phonemes with at least _MIN_ATTEMPTS_PREFERRED attempts.
    3. Fall back to any phoneme with at least 1 attempt if not enough preferred rows exist.
    4. Return up to _MAX_TARGET_PHONEMES rows.

    Each returned dict has:
    - phoneme: str (ARPAbet symbol, e.g. "iy", "p")
    - current_avg_accuracy: float (0–100)
    - total_attempts: int

    Raises:
    - ValueError if the user has no phoneme data at all.
    """
    rows = rest_get(
        table="user_phoneme_metrics",
        params={
            "select": "phoneme,current_avg_accuracy,total_attempts",
            "user_id": f"eq.{user_id}",
            "order": "current_avg_accuracy.asc",
        },
    )

    if not rows:
        raise ValueError(
            "No phoneme practice data found. Complete at least one pronunciation "
            "session before generating a metrics-based course."
        )

    # Prefer phonemes with sufficient attempts for statistical reliability.
    preferred = [r for r in rows if int(r.get("total_attempts", 0)) >= _MIN_ATTEMPTS_PREFERRED]
    candidates = preferred if preferred else rows

    return candidates[:_MAX_TARGET_PHONEMES]


def _build_phoneme_prompt(phonemes: list[dict]) -> str:
    """
    Build the "User request:" section for a phoneme-targeted course.

    This string is inserted into _gemini_generate's full prompt template,
    which already prepends _JSON_SHAPE_INSTRUCTIONS and the system context.
    Therefore this function must describe only WHAT to generate (which
    phonemes to target and why) — never HOW to format the output, since
    that is fully controlled by _JSON_SHAPE_INSTRUCTIONS.

    Format:
    - Lists phonemes ranked lowest-accuracy-first with their scores.
    - Instructs the model to focus lessons on those specific sounds.
    """
    lines = []
    for p in phonemes:
        symbol = p.get("phoneme", "?")
        accuracy = float(p.get("current_avg_accuracy", 0))
        lines.append(f"  - /{symbol}/ (accuracy: {accuracy:.0f}%)")

    phoneme_list = "\n".join(lines)

    return f"""
Pronunciation practice course for a learner who struggles with these English phonemes (lowest accuracy first):

{phoneme_list}

Each lesson should target one or two of these sounds using everyday words, phrases, and short sentences that prominently feature them.
""".strip()


def generate_course_from_metrics(user_id: str) -> dict:
    """
    Generate a pronunciation course targeting the user's weakest phonemes.

    Flow:
    1. Fetch the user's lowest-accuracy phonemes from user_phoneme_metrics.
    2. Build a phoneme-targeted prompt from those results.
    3. Call Gemini to generate the structured course.
    4. Fall back to a stub course if Gemini fails and fallback is enabled.

    Args:
    - user_id: The authenticated user's UUID string (from X-User-Id header).

    Returns:
    - Dict matching the GenerateCourseRes shape: {title, image_url, lessons}.

    Raises:
    - ValueError if the user has no phoneme data.
    - RuntimeError if Gemini fails and ALLOW_STUB_FALLBACK is disabled.
    """
    weak_phonemes = _fetch_weak_phonemes(user_id)
    prompt = _build_phoneme_prompt(weak_phonemes)

    allow_fallback = _env_truthy("ALLOW_STUB_FALLBACK", default=True)

    try:
        return _gemini_generate(prompt)
    except Exception as e:
        if not allow_fallback:
            print("Gemini failed and fallback disabled:", repr(e), flush=True)
            raise RuntimeError(str(e)) from e

        print("Gemini failed, falling back to stub:", repr(e), flush=True)

        # Build a descriptive title from the target phonemes for the stub.
        symbols = ", ".join(
            f"/{p.get('phoneme', '?')}/" for p in weak_phonemes
        )
        title = f"[STUB] Pronunciation Practice: {symbols}"
        lessons = stub_generate_lessons(prompt)

        return {
            "title": title,
            "image_url": select_course_image("pronunciation"),
            "lessons": [lesson.dict() for lesson in lessons],
        }