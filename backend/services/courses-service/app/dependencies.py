"""
FastAPI dependency provider.

Purpose:
- Central place to construct and inject our CourseService.
- Lets routers "Depends(get_course_service)" without manually wiring things.

Today:
- Always returns CourseService(repo=SupabaseCourseRepo())

Later:
- Could swap repo based on env (Supabase vs SQLAlchemy)
- Could add caching, testing mocks, etc.
"""

from app.repositories.supabase_course_repo import SupabaseCourseRepo
from app.services.course_service import CourseService


def get_course_service() -> CourseService:
    """FastAPI dependency that returns a ready-to-use CourseService."""
    return CourseService(repo=SupabaseCourseRepo())