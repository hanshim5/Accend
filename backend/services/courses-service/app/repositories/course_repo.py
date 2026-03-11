"""
course_repo.py

Repository interface (contract).

Purpose:
- Define the methods our service layer expects for course data.
- Allows us to swap implementations later (Supabase now, SQLAlchemy later)
  without changing business logic.

Why Protocol:
- Protocol is like an "interface" in Python.
- Any class that implements these methods is considered a CourseRepo.
"""

from typing import Protocol
from uuid import UUID
from app.schemas.course_schema import CourseCreate, CourseOut


class CourseRepo(Protocol):
    """
    Data access contract for courses.

    The service layer (CourseService) depends on this abstraction,
    not on Supabase directly.

    That keeps our code modular and migration-friendly.
    """
    def list_courses(self, user_id: UUID) -> list[CourseOut]: ...
    def create_course(self, user_id: UUID, data: CourseCreate) -> CourseOut: ...