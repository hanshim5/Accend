"""
lesson_schema.py
"""

from __future__ import annotations

from pydantic import BaseModel, Field
from datetime import datetime
from uuid import UUID


class LessonItemCreate(BaseModel):
    """
    One phrase/word/sentence prompt inside a lesson.
    """
    text: str = Field(min_length=1, max_length=300)
    ipa: str | None = Field(default=None, max_length=300)
    hint: str | None = Field(default=None, max_length=500)


class LessonCreate(BaseModel):
    """
    Create a lesson with items in one call (used by AI service).
    """
    title: str = Field(min_length=1, max_length=200)
    position: int = Field(ge=1)

    # Items are ordered as provided; we will assign position 1..N
    items: list[LessonItemCreate] = Field(min_length=1, max_length=200)


class LessonItemOut(BaseModel):
    id: UUID
    lesson_id: UUID
    position: int
    text: str
    ipa: str | None = None
    hint: str | None = None
    created_at: datetime


class LessonOut(BaseModel):
    id: UUID
    course_id: UUID
    position: int
    title: str
    is_completed: bool
    created_at: datetime


class LessonWithItemsOut(LessonOut):
    items: list[LessonItemOut] = []