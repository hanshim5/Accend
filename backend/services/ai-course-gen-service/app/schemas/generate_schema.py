"""
generate_schema.py
"""

from pydantic import BaseModel, Field
from typing import List, Optional


class LessonItem(BaseModel):
    text: str
    ipa: Optional[str] = None
    hint: Optional[str] = None


class Lesson(BaseModel):
    title: str
    items: List[LessonItem] = Field(default_factory=list)


class GenerateCourseReq(BaseModel):
    prompt: str = Field(..., min_length=1, max_length=5000)


class GenerateCourseRes(BaseModel):
    title: str
    lessons: List[Lesson] = Field(default_factory=list)