"""
course_service.py

Service layer (business logic).

Purpose:
- Where "domain logic" lives (validation rules, permissions, workflows).
- Calls repository methods to access data.
- Keeps routers thin and repositories dumb.

Right now it's mostly pass-through, which is fine for Sprint 1.
Later you might add rules like:
- enforce title uniqueness per user
- sanitize titles
- create default lesson structure
"""

from uuid import UUID
from app.repositories.course_repo import CourseRepo
from app.schemas.course_schema import CourseCreate, CourseOut


class CourseService:
    """
    The service depends on the abstract CourseRepo (interface),
    so we can swap the repo implementation later.
    """

    def __init__(self, repo: CourseRepo):
        self.repo = repo

    def list_courses(self, user_id: UUID) -> list[CourseOut]:
        """Return courses owned by the user."""
        return self.repo.list_courses(user_id)

    def create_course(self, user_id: UUID, data: CourseCreate) -> CourseOut:
        """Create a course for a user and return it."""
        return self.repo.create_course(user_id, data)