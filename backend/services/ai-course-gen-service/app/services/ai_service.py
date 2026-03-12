"""
ai_service.py

Business logic for AI course generation.

Currently contains a sprint-1 stubbed generator. Replace with real LLM call here later.
"""

from typing import List
from ..schemas.generate_schema import Lesson, LessonItem
import textwrap


def stub_generate_lessons(prompt: str) -> List[Lesson]:
    """
    Produce a list[Lesson] from a prompt.
    Keep this function small and deterministic for easy unit testing.
    Replace contents with LLM integration later.
    """
    # simple heuristic to create 3 lessons with 2 items each
    base_title = prompt.strip()[:120]
    lessons = []

    # create three general-purpose lessons
    for i, section in enumerate(["Intro & key vocabulary", "Pronunciation practice", "Practice phrases"], start=1):
        lesson_title = f"Lesson {i}: {section}"
        # item examples derived from prompt words
        words = [w for w in textwrap.shorten(prompt, width=60).split() if len(w) > 2][:4]
        if not words:
            words = ["phrase", "word"]

        items = []
        for j, w in enumerate(words[:2], start=1):
            items.append(LessonItem(
                text=f"{w} — example phrase using {w}",
                ipa=None,
                hint=None
            ))
        lessons.append(Lesson(title=lesson_title, items=items))

    return lessons


def generate_course_from_prompt(prompt: str) -> dict:
    """
    Single entrypoint the router uses.
    Returns dict that matches GenerateCourseRes.
    """
    prompt_clean = prompt.strip()
    title = f"{prompt_clean[:60]}".strip() or "New Course"

    lessons = stub_generate_lessons(prompt_clean)

    return {
        "title": title,
        "lessons": [lesson.dict() for lesson in lessons]
    }