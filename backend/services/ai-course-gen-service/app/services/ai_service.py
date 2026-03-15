"""
ai_service.py

Business logic for AI course generation.

Uses Gemini via google-genai and requests JSON output.
Falls back to the deterministic stub ONLY if ALLOW_STUB_FALLBACK is enabled.

Env:
- GEMINI_API_KEY
- GEMINI_MODEL (default: gemini-2.5-flash)
- ALLOW_STUB_FALLBACK (default: true)   # set to false in prod to fail hard
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

Rules:
- 3 to 6 lessons
- 3 to 8 items per lesson
- Keep item text short and practical (phrases/words/sentences)
- Use null for ipa/hint when not provided
- No extra keys anywhere
""".strip()


def _strip_code_fences(s: str) -> str:
    s = s.strip()
    if s.startswith("```"):
        s = re.sub(r"^```[a-zA-Z0-9_-]*\s*", "", s)
        s = re.sub(r"\s*```$", "", s)
    return s.strip()


def _validate_and_normalize(payload: dict) -> dict:
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
    val = os.getenv(name)
    if val is None:
        return default
    return val.strip().lower() in ("1", "true", "yes", "y", "on")


def generate_course_from_prompt(prompt: str) -> dict:
    """
    Primary: Gemini LLM
    Fallback: deterministic stub ONLY if ALLOW_STUB_FALLBACK is true
    """
    prompt_clean = prompt.strip()
    if not prompt_clean:
        raise ValueError("Prompt must be non-empty")

    allow_fallback = _env_truthy("ALLOW_STUB_FALLBACK", default=True)

    try:
        return _gemini_generate(prompt_clean)
    except Exception as e:
        # If fallback disabled, fail hard so we don't silently create junk courses
        if not allow_fallback:
            print("Gemini failed and fallback disabled:", repr(e), flush=True)
            raise

        print("Gemini failed, falling back to stub:", repr(e), flush=True)
        title = f"[STUB] {prompt_clean[:60]}".strip() or "[STUB] New Course"
        lessons = stub_generate_lessons(prompt_clean)
        return {"title": title, "lessons": [lesson.dict() for lesson in lessons]}