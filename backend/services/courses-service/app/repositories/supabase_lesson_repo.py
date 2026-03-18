"""
supabase_lesson_repo.py

Supabase Lesson Repository

Purpose:
- Implement lesson-related persistence for the courses service using Supabase REST.
- Manage lesson and lesson_items reads/writes.
- Recompute and update cached course progress when lesson completion changes.

Architecture:
- Service layer depends on the LessonRepo contract.
- This class is the concrete Supabase-backed implementation of that contract.
- It talks to Supabase through shared REST helper functions.

Data Flow:
- lessons table stores lesson-level metadata for a course.
- lesson_items table stores the ordered items/questions inside each lesson.
- courses table stores cached progress/status fields that are updated when lessons are completed.

Notes:
- Ordering matters for both lessons and lesson items.
- Progress is cached on the course for faster reads on the Courses page.
- This repository handles both persistence and the related progress recalculation workflow.
"""

from __future__ import annotations

from uuid import UUID
from math import floor

from app.clients.supabase import rest_get, rest_post, rest_patch
from app.schemas.lesson_schema import (
    LessonCreate,
    LessonOut,
    LessonItemOut,
    LessonWithItemsOut,
    CurriculumCreate,
)

# Shared select strings used in Supabase REST calls.
# Keeping these in constants makes queries easier to reuse and maintain.
LESSON_SELECT = "id,course_id,position,title,is_completed,created_at"
ITEM_SELECT = "id,lesson_id,position,text,ipa,hint,created_at"


class SupabaseLessonRepo:
    """
    Supabase implementation for lessons, lesson items, and cached course progress.

    Responsibilities:
    - Read a course curriculum with nested lesson items.
    - Create one lesson and its items.
    - Create an entire curriculum in bulk.
    - Mark a lesson complete and update cached course progress/status.
    """

    def list_lessons_with_items(self, course_id: UUID) -> list[LessonWithItemsOut]:
        """
        Return all lessons for a course, each with its associated lesson items.

        Flow:
        1. Fetch lessons for the given course in position order.
        2. Fetch all lesson items for those lessons in one query.
        3. Group items by lesson_id.
        4. Rebuild the nested response shape expected by the API.
        """

        # Fetch all lessons for the course, ordered by curriculum position.
        lessons_rows = rest_get(
            table="lessons",
            params={
                "select": LESSON_SELECT,
                "course_id": f"eq.{str(course_id)}",
                "order": "position.asc",
            },
        )

        # Validate raw rows into typed schema objects.
        lessons = [LessonOut.model_validate(r) for r in lessons_rows]
        if not lessons:
            return []

        # Collect lesson IDs so all items can be fetched in one bulk query.
        lesson_ids = [str(l.id) for l in lessons]
        ids_csv = ",".join(lesson_ids)

        # Fetch all items belonging to the previously fetched lessons.
        items_rows = rest_get(
            table="lesson_items",
            params={
                "select": ITEM_SELECT,
                "lesson_id": f"in.({ids_csv})",
                "order": "lesson_id.asc,position.asc",
            },
        )
        items = [LessonItemOut.model_validate(r) for r in items_rows]

        # Group lesson items by their parent lesson so we can rebuild
        # LessonWithItemsOut objects.
        items_by_lesson: dict[UUID, list[LessonItemOut]] = {}
        for it in items:
            items_by_lesson.setdefault(it.lesson_id, []).append(it)

        # Ensure stable ordering within each lesson.
        # Even if the database query returns items in order, this keeps
        # the output deterministic and safe.
        for lesson_id, arr in items_by_lesson.items():
            arr.sort(key=lambda x: x.position)

        # Reconstruct the nested API response:
        # each lesson object includes its list of items.
        out: list[LessonWithItemsOut] = []
        for l in lessons:
            out.append(
                LessonWithItemsOut(
                    **l.model_dump(),
                    items=items_by_lesson.get(l.id, []),
                )
            )

        return out

    def create_lesson_with_items(self, course_id: UUID, data: LessonCreate) -> LessonWithItemsOut:
        """
        Create one lesson and all of its lesson items.

        Flow:
        1. Insert the lesson row.
        2. Insert all lesson items in bulk.
        3. Return the created lesson with nested items.
        """

        # Create the parent lesson row first so we get its generated lesson ID.
        lesson_rows = rest_post(
            table="lessons",
            payload={
                "course_id": str(course_id),
                "position": data.position,
                "title": data.title,
                "is_completed": False,
            },
            select=LESSON_SELECT,
        )
        if not lesson_rows:
            raise RuntimeError("Supabase REST POST returned no lesson row")

        lesson = LessonOut.model_validate(lesson_rows[0])

        # Build the bulk payload for all lesson items.
        # Item positions are assigned by list order starting at 1.
        items_payload = [
            {
                "lesson_id": str(lesson.id),
                "position": idx,
                "text": item.text,
                "ipa": item.ipa,
                "hint": item.hint,
            }
            for idx, item in enumerate(data.items, start=1)
        ]

        # A lesson must contain at least one item.
        if not items_payload:
            raise RuntimeError("Lesson contains no items")

        # Insert all lesson items in one request.
        item_rows = rest_post(
            table="lesson_items",
            payload=items_payload,
            select=ITEM_SELECT,
        )

        created_items = [LessonItemOut.model_validate(r) for r in item_rows]
        created_items.sort(key=lambda x: x.position)

        # Return the created lesson in nested API response shape.
        return LessonWithItemsOut(**lesson.model_dump(), items=created_items)

    def complete_lesson_and_update_course(self, course_id: UUID, lesson_id: UUID) -> LessonOut:
        """
        Mark a lesson as completed and recompute cached course progress.

        Flow:
        1. Mark the lesson complete.
        2. Count total lessons in the course.
        3. Count completed lessons in the course.
        4. Derive progress_percent and status.
        5. Patch the parent course's cached progress fields.
        """

        # 1) Mark lesson complete.
        # Filtering by both lesson_id and course_id ensures the lesson belongs
        # to the provided course.
        updated = rest_patch(
            table="lessons",
            match={
                "id": f"eq.{str(lesson_id)}",
                "course_id": f"eq.{str(course_id)}",
            },
            payload={"is_completed": True},
            select=LESSON_SELECT,
        )
        if not updated:
            raise RuntimeError("Lesson not found for course (or update returned no rows).")

        lesson = LessonOut.model_validate(updated[0])

        # 2) Count how many lessons exist for this course.
        total_rows = rest_get(
            table="lessons",
            params={
                "select": "id",
                "course_id": f"eq.{str(course_id)}",
            },
        )
        total = len(total_rows)

        # 3) Count how many lessons are completed for this course.
        done_rows = rest_get(
            table="lessons",
            params={
                "select": "id",
                "course_id": f"eq.{str(course_id)}",
                "is_completed": "eq.true",
            },
        )
        done = len(done_rows)

        # 4) Compute integer progress percentage.
        # floor() keeps this as a whole-number percent for simple UI display.
        if total <= 0:
            progress = 0
        else:
            progress = floor(done * 100 / total)

        # Derive course status from progress/completion counts.
        if progress <= 0:
            status = "not_started"
        elif done >= total and total > 0:
            status = "completed"
            progress = 100
        else:
            status = "in_progress"

        # 5) Update cached course fields.
        # These cached values let the Courses page load quickly without
        # recomputing progress on every read.
        rest_patch(
            table="courses",
            match={"id": f"eq.{str(course_id)}"},
            payload={"progress_percent": progress, "status": status},
            select="id",
        )

        return lesson

    def create_curriculum(self, course_id: UUID, data: CurriculumCreate) -> list[LessonWithItemsOut]:
        """
        Create an entire curriculum for a course in bulk.

        Flow:
        1. Bulk insert all lessons.
        2. Map inserted lesson positions to generated lesson IDs.
        3. Bulk insert all lesson items across all lessons.
        4. Group items by lesson_id.
        5. Return nested lessons-with-items in position order.
        """

        # 1) Build the bulk lesson payload.
        # Lesson positions are assigned by their order in data.lessons.
        lessons_payload = [
            {
                "course_id": str(course_id),
                "position": i,
                "title": lesson.title,
                "is_completed": False,
            }
            for i, lesson in enumerate(data.lessons, start=1)
        ]

        if not lessons_payload:
            raise RuntimeError("Curriculum contains no lessons")

        # Insert all lessons in one request.
        lesson_rows = rest_post(
            table="lessons",
            payload=lessons_payload,
            select=LESSON_SELECT,
        )
        if not lesson_rows:
            raise RuntimeError("Bulk insert lessons returned no rows")

        inserted_lessons = [LessonOut.model_validate(r) for r in lesson_rows]

        # Map lesson position -> generated lesson_id.
        # This lets us attach lesson items to the correct inserted lesson.
        lesson_id_by_position = {l.position: l.id for l in inserted_lessons}

        # 2) Build a single bulk payload for all lesson items across
        # the entire curriculum.
        items_payload: list[dict[str, object]] = []
        for lesson_pos, lesson in enumerate(data.lessons, start=1):
            lesson_id = lesson_id_by_position[lesson_pos]
            for item_pos, item in enumerate(lesson.items, start=1):
                items_payload.append(
                    {
                        "lesson_id": str(lesson_id),
                        "position": item_pos,
                        "text": item.text,
                        "ipa": item.ipa,
                        "hint": item.hint,
                    }
                )

        if not items_payload:
            raise RuntimeError("Curriculum contains no lesson items")

        # Insert all lesson items in one request.
        item_rows = rest_post(
            table="lesson_items",
            payload=items_payload,
            select=ITEM_SELECT,
        )
        inserted_items = [LessonItemOut.model_validate(r) for r in item_rows]

        # Group inserted items by parent lesson_id so we can return the nested shape.
        items_by_lesson: dict[UUID, list[LessonItemOut]] = {}
        for it in inserted_items:
            items_by_lesson.setdefault(it.lesson_id, []).append(it)

        # Ensure deterministic ordering of items within each lesson.
        for lesson_id, arr in items_by_lesson.items():
            arr.sort(key=lambda x: x.position)

        # Return lessons in curriculum order, each with its corresponding items.
        out: list[LessonWithItemsOut] = []
        for l in sorted(inserted_lessons, key=lambda x: x.position):
            out.append(
                LessonWithItemsOut(
                    **l.model_dump(),
                    items=items_by_lesson.get(l.id, []),
                )
            )

        return out