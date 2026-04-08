"""
lesson_repo.py

Repository Interface for Lesson Persistence

Purpose:
- Define the contract for lesson-related data access in the courses service.
- Standardize how the service layer interacts with lesson storage.
- Keep business logic decoupled from the concrete database implementation.

Architecture:
- Routers call services.
- Services depend on repository interfaces like this one.
- Concrete repository implementations satisfy this protocol
  (for example, a Supabase-backed lesson repository).

Why use a Protocol:
- Allows the service layer to depend on behavior instead of a specific class.
- Makes testing easier because mock or alternate repository implementations
  can follow the same method signatures.
"""

from typing import Protocol
from uuid import UUID

from app.schemas.lesson_schema import LessonCreate, LessonWithItemsOut, LessonOut, CurriculumCreate


class LessonRepo(Protocol):
    """
    Contract for lesson repository implementations.

    Any class that implements these methods can be used by the lesson service.
    This creates a clean boundary between business logic and data persistence.
    """

    def list_lessons_with_items(self, course_id: UUID) -> list[LessonWithItemsOut]: ...
    """
    Return all lessons for a course, including their lesson items.

    Used when the API needs the full curriculum structure for a course.
    """

    def create_lesson_with_items(self, course_id: UUID, data: LessonCreate) -> LessonWithItemsOut: ...
    """
    Create a single lesson and its associated lesson items for a course.

    Used when adding one lesson at a time.
    """

    def complete_lesson_and_update_course(self, user_id: UUID, course_id: UUID, lesson_id: UUID) -> LessonOut: ...
    """
    Mark a lesson as completed and update the parent course's progress/status.

    This reflects the rule that lesson completion can affect course-level
    progress metadata.
    """

    def create_curriculum(self, course_id: UUID, data: CurriculumCreate) -> list[LessonWithItemsOut]: ...
    """
    Create a full curriculum for a course in one operation.

    Typically used when generating or inserting multiple lessons and their
    items together.
    """

    def get_completed_lessons_count(self, user_id: UUID) -> int: ...
    """
    Return the number of completed lessons across all courses owned by a user.
    """

    def get_learning_stats(self, user_id: UUID) -> dict[str, int]: ...
    """
    Return cached lesson-driven profile stats for a user.

    Includes lessons_completed and meters_climbed.
    """

    def backfill_profile_levels(self) -> dict[str, int]: ...
    """
    Backfill profiles.level for existing users based on user_stats.
    """