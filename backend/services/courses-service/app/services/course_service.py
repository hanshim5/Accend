"""
course_service.py

Course Service (Business Logic Layer)

Purpose:
- Encapsulate business logic for course-related operations.
- Act as the intermediary between API routes and the repository layer.
- Keep routers thin (HTTP concerns only) and repositories focused on data access.

Architecture:
Router → Service (this layer) → Repository → Database (Supabase)

Design Notes:
- Currently acts as a thin pass-through to the repository (Sprint 1).
- This is intentional to establish clean separation of concerns early.
- Future business rules should be implemented here, not in routers or repositories.

Examples of future logic:
- Enforce unique course titles per user
- Sanitize or normalize input data
- Initialize default lesson structures
- Add analytics, logging, or side effects
"""

from uuid import UUID
from app.repositories.course_repo import CourseRepo
from app.schemas.course_schema import CourseCreate, CourseOut


class CourseService:
    """
    Service layer for course operations.

    Responsibilities:
    - Coordinate course-related workflows.
    - Provide a stable interface for routers.
    - Serve as the central place for business rules.

    Dependency:
    - Relies on the abstract CourseRepo, not a concrete implementation.
    - Enables easy swapping (Supabase, SQLAlchemy, mock repos for testing).
    """

    def __init__(self, repo: CourseRepo):
        """
        Initialize service with a repository implementation.

        Dependency Injection:
        - Repository is injected so this service is decoupled from persistence details.
        """
        self.repo = repo

    def list_courses(self, user_id: UUID) -> list[CourseOut]:
        """
        Retrieve all courses owned by a user.

        Currently:
        - Direct pass-through to repository.

        Future:
        - Could enforce access control or transform results.
        """
        return self.repo.list_courses(user_id)

    def create_course(self, user_id: UUID, data: CourseCreate) -> CourseOut:
        """
        Create a new course for a user.

        Currently:
        - Delegates directly to repository.

        Future:
        - Could enforce validation rules (e.g., unique titles per user).
        - Could trigger downstream actions (e.g., auto-generate curriculum).
        """
        return self.repo.create_course(user_id, data)

    def delete_course(self, user_id: UUID, course_id: UUID) -> None:
        """
        Delete a course owned by the authenticated user.

        Raises:
        - LookupError if the course does not exist.
        - PermissionError if the course belongs to a different user.

        The repository handles the ownership check and deletion.
        Cascade FK constraints in the database remove child lessons and
        lesson_items atomically.
        """
        self.repo.delete_course(user_id, course_id)