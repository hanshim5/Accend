"""
Supabase implementation of CourseRepo.

Purpose:
- Talk to the database (Supabase Postgres via PostgREST HTTP).
- This is the ONLY layer that should call the Supabase REST client helpers.

Architecture rule:
routers -> services -> repositories -> supabase client
(no DB calls in routers)
"""

from uuid import UUID
from app.clients.supabase import rest_get, rest_post
from app.schemas.course_schema import CourseCreate, CourseOut


class SupabaseCourseRepo:
    """
    Repository that reads/writes the 'courses' table using Supabase PostgREST.

    Notes:
    - Uses backend key, so it bypasses RLS.
      (That’s fine for Sprint 1, but don’t expose this service publicly
       except via gateway.)
    """

    def list_courses(self, user_id: UUID) -> list[CourseOut]:
        """
        Fetch all courses belonging to a user, sorted newest first.
        """
        rows = rest_get(
            table="courses",
            params={
                "select": "id,user_id,title,created_at,progress_percent,status",
                "user_id": f"eq.{str(user_id)}",
                "order": "created_at.desc",
            },
        )

        return [CourseOut.model_validate(row) for row in rows]

    def create_course(self, user_id: UUID, data: CourseCreate) -> CourseOut:
        """
        Insert a new course row and return the inserted row.
        """
        payload = {
            "user_id": str(user_id),
            "title": data.title,
        }

        rows = rest_post(
            table="courses",
            payload=payload,
            select="id,user_id,title,created_at,progress_percent,status",
        )
        if not rows:
            raise RuntimeError("Supabase REST POST returned no row")
        
        return CourseOut.model_validate(rows[0])
