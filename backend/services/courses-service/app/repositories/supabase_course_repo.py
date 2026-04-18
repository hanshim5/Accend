"""
supabase_course_repo.py

Supabase Course Repository

Purpose:
- Implement CourseRepo using Supabase Postgres via PostgREST HTTP.
- Handle all persistence for the 'courses' table.
- Convert raw database rows into typed schema objects.

Architecture:
Router → Service → Repository (this layer) → Supabase REST client → Database

Rules:
- This is the ONLY layer that should directly call Supabase REST helpers.
- No database access should occur in routers or services.

Security:
- Uses SUPABASE_SERVICE_ROLE_KEY (bypasses RLS).
- Safe because this service is only accessible behind the API Gateway.
- Never expose this repository or its key directly to clients.
"""

from uuid import UUID
from app.clients.supabase import rest_delete, rest_get, rest_post
from app.schemas.course_schema import CourseCreate, CourseOut


class SupabaseCourseRepo:
    """
    Supabase-backed implementation of CourseRepo.

    Responsibilities:
    - Read course data for a user.
    - Insert new courses.
    - Map raw database responses into validated schema objects.

    Notes:
    - Uses backend service role key (no RLS enforcement).
    - Assumes upstream layers (gateway/service) handle authentication.
    """

    def list_courses(self, user_id: UUID) -> list[CourseOut]:
        """
        Fetch all courses for a given user.

        Flow:
        1. Query the 'courses' table filtered by user_id.
        2. Order results by newest first (created_at descending).
        3. Convert raw rows into CourseOut schema objects.

        Returns:
        - List of CourseOut objects (empty if no courses exist).
        """
        rows = rest_get(
            table="courses",
            params={
                "select": "id,user_id,title,image_url,created_at,progress_percent,status",
                "user_id": f"eq.{str(user_id)}",
                "order": "created_at.desc",
            },
        )

        # Validate and convert raw JSON rows into typed schema objects.
        return [CourseOut.model_validate(row) for row in rows]

    def create_course(self, user_id: UUID, data: CourseCreate) -> CourseOut:
        """
        Create a new course for a user.

        Flow:
        1. Build insert payload from input data.
        2. Insert row into 'courses' table.
        3. Return inserted row as CourseOut.

        Notes:
        - progress_percent and status are initialized by database defaults.
        """

        # Construct payload for insertion.
        payload = {
            "user_id": str(user_id),
            "title": data.title,
            "image_url": data.image_url,
        }

        # Perform insert via Supabase REST.
        rows = rest_post(
            table="courses",
            payload=payload,
            select="id,user_id,title,image_url,created_at,progress_percent,status",
        )
        if not rows:
            raise RuntimeError("Supabase REST POST returned no row")

        # Return validated schema object.
        return CourseOut.model_validate(rows[0])

    def delete_course(self, user_id: UUID, course_id: UUID) -> None:
        """
        Delete a course belonging to the specified user.

        Flow:
        1. Fetch the course row to verify it exists and is owned by this user.
        2. Raise LookupError if not found; PermissionError if owned by someone else.
        3. Delete the courses row — ON DELETE CASCADE in the database automatically
           removes all child lessons and lesson_items in the same transaction.
        """
        rows = rest_get(
            table="courses",
            params={
                "select": "id,user_id",
                "id": f"eq.{str(course_id)}",
            },
        )

        if not rows:
            raise LookupError(f"Course {course_id} not found")

        if rows[0]["user_id"] != str(user_id):
            raise PermissionError("Course does not belong to this user")

        rest_delete(
            table="courses",
            match={"id": f"eq.{str(course_id)}"},
        )

    def delete_account(self, user_id: UUID) -> None:
        """
        Delete all courses for a user.

        Flow:
        1. Delete all course rows where user_id matches.
        2. ON DELETE CASCADE automatically removes all child lessons and lesson_items.
        """
        rest_delete(
            table="courses",
            match={"user_id": f"eq.{str(user_id)}"},
        )