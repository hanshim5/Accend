"""
Supabase implementation of CourseRepo.

Purpose:
- Actually talk to the database (Supabase Postgres via PostgREST).
- This is the ONLY layer that should call get_supabase() / sb.table(...).

Architecture rule:
routers -> services -> repositories -> supabase
(no DB calls in routers)
"""

from uuid import UUID
from app.clients.supabase import get_supabase
from app.schemas.course_schema import CourseCreate, CourseOut


class SupabaseCourseRepo:
    """
    Repository that reads/writes the 'courses' table using Supabase client.

    Notes:
    - Uses service role key, so it bypasses RLS.
      (That’s fine for Sprint 1, but don’t expose this service publicly
       except via gateway.)
    """

    def list_courses(self, user_id: UUID) -> list[CourseOut]:
        """
        Fetch all courses belonging to a user, sorted newest first.

        Supabase query breakdown:
        - table("courses")               -> target table
        - select("id,user_id,title,...") -> only fetch columns we need
        - eq("user_id", ...)             -> filter by user ownership
        - order("created_at", desc=True) -> newest first
        - execute()                      -> run the query
        """
        sb = get_supabase()

        res = (
            sb.table("courses")
            .select("id,user_id,title,created_at")
            .eq("user_id", str(user_id))
            .order("created_at", desc=True)
            .execute()
        )

        # res.data is typically a list[dict]. If empty, it may be [] or None.
        rows = res.data or []

        # Convert each dict row into a strongly-typed CourseOut
        return [CourseOut.model_validate(row) for row in rows]

    def create_course(self, user_id: UUID, data: CourseCreate) -> CourseOut:
        """
        Insert a new course row and return the inserted row.

        payload:
        - user_id: enforced by gateway-derived user id
        - title: validated already by CourseCreate schema

        Why select(...) after insert:
        - So we get the generated id + created_at back in the response.
        """
        sb = get_supabase()

        payload = {
            "user_id": str(user_id),
            "title": data.title,
        }

        res = (
            sb.table("courses")
            .insert(payload)
            .select("id,user_id,title,created_at")
            .execute()
        )

        # Supabase returns inserted rows as a list, usually length 1.
        row = (res.data or [None])[0]

        # If we didn't get a row back, something went wrong (db error, etc.)
        if not row:
            raise RuntimeError("Failed to create course")

        return CourseOut.model_validate(row)