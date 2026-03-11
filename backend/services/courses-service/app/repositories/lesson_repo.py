"""
lesson_repo.py
"""

from typing import Protocol
from uuid import UUID

from app.schemas.lesson_schema import LessonCreate, LessonWithItemsOut, LessonOut


class LessonRepo(Protocol):
    def list_lessons_with_items(self, course_id: UUID) -> list[LessonWithItemsOut]: ...
    def create_lesson_with_items(self, course_id: UUID, data: LessonCreate) -> LessonWithItemsOut: ...
    def complete_lesson_and_update_course(self, course_id: UUID, lesson_id: UUID) -> LessonOut: ...