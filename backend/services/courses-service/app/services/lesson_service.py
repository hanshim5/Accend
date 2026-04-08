"""
lesson_service.py

Lesson Service (Business Logic Layer)

Purpose:
- Act as the intermediary between API routes and the repository layer.
- Encapsulate business logic related to lessons and curriculum management.
- Provide a clean abstraction so routers do not directly depend on data access.

Architecture:
Router → Service (this layer) → Repository → Database (Supabase)

Design Notes:
- Currently acts mostly as a thin pass-through to the repository.
- This is intentional for Sprint 1 to keep things simple.
- Future logic (authorization, validation, analytics, etc.) should be added here,
  not in the router or repository.

Why this layer matters:
- Keeps routers lightweight and focused on HTTP concerns.
- Keeps repositories focused only on data persistence.
- Central place to evolve business rules without breaking other layers.
"""

from uuid import UUID
from app.repositories.lesson_repo import LessonRepo
from app.schemas.lesson_schema import LessonCreate, LessonWithItemsOut, LessonOut, CurriculumCreate


class LessonService:
    """
    Service layer for lesson-related operations.

    Responsibilities:
    - Coordinate lesson operations between API and repository.
    - Serve as the future home for business rules (e.g., ownership checks,
      validation, feature flags, analytics hooks).
    """

    def __init__(self, repo: LessonRepo):
        """
        Initialize service with a repository implementation.

        Dependency Injection:
        - Allows swapping implementations (e.g., Supabase, mock, test repo).
        """
        self.repo = repo

    def list_lessons_with_items(self, course_id: UUID) -> list[LessonWithItemsOut]:
        """
        Retrieve full curriculum (lessons + items) for a course.

        Currently:
        - Direct pass-through to repository.

        Future:
        - Could enforce user access or transform response data.
        """
        return self.repo.list_lessons_with_items(course_id)

    def create_lesson_with_items(self, course_id: UUID, data: LessonCreate) -> LessonWithItemsOut:
        """
        Create a lesson and its items.

        Currently:
        - Delegates directly to repository.

        Future:
        - Could validate constraints (e.g., max lessons per course).
        - Could log creation events or trigger side effects.
        """
        return self.repo.create_lesson_with_items(course_id, data)

    def complete_lesson_and_update_course(self, course_id: UUID, lesson_id: UUID) -> LessonOut:
        """
        Mark a lesson as complete and update course progress.

        Currently:
        - Repository handles both lesson update and course progress recalculation.

        Future:
        - Could enforce user ownership.
        - Could track completion analytics or streaks.
        """
        return self.repo.complete_lesson_and_update_course(course_id, lesson_id)

    def create_curriculum(self, course_id: UUID, data: CurriculumCreate) -> list[LessonWithItemsOut]:
        """
        Create a full curriculum (multiple lessons + items).

        Currently:
        - Delegates bulk creation to repository.

        Future:
        - Could validate curriculum size/structure.
        - Could integrate AI validation or post-processing.
        """
        return self.repo.create_curriculum(course_id, data)

    def get_completed_lessons_count(self, user_id: UUID) -> int:
        """
        Return completed lesson count across all user-owned courses.
        """
        return self.repo.get_completed_lessons_count(user_id)