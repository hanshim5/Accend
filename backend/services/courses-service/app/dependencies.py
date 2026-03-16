"""
dependencies.py

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
from app.repositories.supabase_lesson_repo import SupabaseLessonRepo
from app.services.course_service import CourseService
from app.services.lesson_service import LessonService

def get_course_service() -> CourseService:
    return CourseService(repo=SupabaseCourseRepo())


def get_lesson_service() -> LessonService:
    return LessonService(repo=SupabaseLessonRepo())
