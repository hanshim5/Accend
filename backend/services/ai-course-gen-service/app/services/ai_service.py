"""
ai_service.py

AI Course Generation Service

Purpose:
- Contain the business logic for generating structured course content from a prompt.
- Use Gemini as the primary generation engine.
- Optionally fall back to a deterministic stub when configured to do so.

Architecture:
Gateway → AI Course Gen Router → AI Service (this file) → Gemini API

Role in the system:
- This service generates course structure only.
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

from ..schemas.generate_schema import Lesson, LessonItem

from google import genai
from google.genai import types

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

    # Fixed lesson sections used to create a minimal curriculum structure.
    for i, section in enumerate(
        ["Intro & key vocabulary", "Pronunciation practice", "Practice phrases"],
        start=1,
    ):
        lesson_title = f"Lesson {i}: {section}"

        # Extract a few usable words from the prompt to seed fake lesson items.
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

# Instructions sent to Gemini so the model returns a strict JSON shape
# that matches the expected API response structure.
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

Rules:
- 3 to 6 lessons
- 3 to 8 items per lesson
- Keep item text short and practical (phrases/words/sentences)
- Use null for ipa/hint when not provided
- No extra keys anywhere
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
            normalized_lessons.append({"title": lt.strip(), "items": normalized_items})

    if not normalized_lessons:
        raise ValueError("No valid lessons/items after normalization")

    return {"title": title.strip(), "lessons": normalized_lessons}


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

    Error Behavior:
    - Raises if the API key is missing.
    - Raises if generation/parsing/validation fails.
    """
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not set")

    model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    client = genai.Client(api_key=api_key)

    # Prompt combines system-like instructions with the user's request.
    # Goal: maximize the chance of receiving clean structured JSON.
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

    # Extract text output and defensively strip markdown fences if present.
    text = _strip_code_fences((getattr(resp, "text", "") or "").strip())

    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        # If Gemini returns invalid JSON, give it one repair pass by feeding
        # back the invalid output and restating the exact required schema.
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
        # If fallback is disabled, fail hard so we do not silently
        # create low-quality or misleading course content.
        if not allow_fallback:
            print("Gemini failed and fallback disabled:", repr(e), flush=True)
            raise

        # Fallback path for local/dev resilience.
        print("Gemini failed, falling back to stub:", repr(e), flush=True)
        title = f"[STUB] {prompt_clean[:60]}".strip() or "[STUB] New Course"
        lessons = stub_generate_lessons(prompt_clean)
        return {"title": title, "lessons": [lesson.dict() for lesson in lessons]}