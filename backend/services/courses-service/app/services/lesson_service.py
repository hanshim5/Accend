"""
lesson_service.py
"""

from uuid import UUID
from app.repositories.lesson_repo import LessonRepo
from app.schemas.lesson_schema import LessonCreate, LessonWithItemsOut, LessonOut


class LessonService:
    def __init__(self, repo: LessonRepo):
        self.repo = repo

    def list_lessons_with_items(self, course_id: UUID) -> list[LessonWithItemsOut]:
        return self.repo.list_lessons_with_items(course_id)

    def create_lesson_with_items(self, course_id: UUID, data: LessonCreate) -> LessonWithItemsOut:
        return self.repo.create_lesson_with_items(course_id, data)

    def complete_lesson_and_update_course(self, course_id: UUID, lesson_id: UUID) -> LessonOut:
        return self.repo.complete_lesson_and_update_course(course_id, lesson_id)