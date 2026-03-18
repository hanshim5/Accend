"""
course_repo.py

Course Repository Interface (Contract)

Purpose:
- Define the data access methods required for course-related operations.
- Decouple the service layer from any specific database implementation.
- Enable easy swapping of persistence layers (e.g., Supabase → SQLAlchemy).

Architecture:
Router → Service → Repository (this interface) → Database

Why Protocol:
- Protocol acts like an interface in Python (structural typing).
- Any class implementing these methods is considered a valid CourseRepo.
- Allows flexible dependency injection and easier testing (mock repos).

Design Notes:
- This layer defines *what* operations are available, not *how* they are implemented.
- Concrete implementations (e.g., SupabaseCourseRepo) handle actual data access.
"""

from typing import Protocol
from uuid import UUID
from app.schemas.course_schema import CourseCreate, CourseOut


class CourseRepo(Protocol):
    """
    Contract for course data access.

    Responsibilities:
    - Provide methods for reading and writing course data.
    - Abstract away database details from the service layer.

    Used by:
    - CourseService (business logic layer)

    Implemented by:
    - SupabaseCourseRepo (current)
    - Future implementations (e.g., SQLAlchemy, test mocks)
    """

    def list_courses(self, user_id: UUID) -> list[CourseOut]: ...
    """
    Return all courses belonging to a specific user.

    Expected Behavior:
    - Filter courses by user_id.
    - Return results in a consistent order (e.g., newest first or by creation time).
    """

    def create_course(self, user_id: UUID, data: CourseCreate) -> CourseOut: ...
    """
    Create a new course for a user.

    Expected Behavior:
    - Insert a new course row linked to user_id.
    - Initialize default fields (e.g., progress_percent = 0, status = 'not_started').
    - Return the created course.
    """