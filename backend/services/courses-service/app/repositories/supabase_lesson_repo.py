"""
supabase_lesson_repo.py
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
)


LESSON_SELECT = "id,course_id,position,title,is_completed,created_at"
ITEM_SELECT = "id,lesson_id,position,text,ipa,hint,created_at"


class SupabaseLessonRepo:
    """
    Supabase implementation for lessons + lesson_items, and cached course progress updates.
    """

    def list_lessons_with_items(self, course_id: UUID) -> list[LessonWithItemsOut]:
        lessons_rows = rest_get(
            table="lessons",
            params={
                "select": LESSON_SELECT,
                "course_id": f"eq.{str(course_id)}",
                "order": "position.asc",
            },
        )

        lessons = [LessonOut.model_validate(r) for r in lessons_rows]
        if not lessons:
            return []

        lesson_ids = [str(l.id) for l in lessons]
        # PostgREST "in" syntax: in.(a,b,c)
        ids_csv = ",".join(lesson_ids)

        items_rows = rest_get(
            table="lesson_items",
            params={
                "select": ITEM_SELECT,
                "lesson_id": f"in.({ids_csv})",
                "order": "lesson_id.asc,position.asc",
            },
        )
        items = [LessonItemOut.model_validate(r) for r in items_rows]

        items_by_lesson: dict[UUID, list[LessonItemOut]] = {}
        for it in items:
            items_by_lesson.setdefault(it.lesson_id, []).append(it)

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
        # Create lesson row
        lesson_row = rest_post(
            table="lessons",
            payload={
                "course_id": str(course_id),
                "position": data.position,
                "title": data.title,
                "is_completed": False,
            },
            select=LESSON_SELECT,
        )
        lesson = LessonOut.model_validate(lesson_row)

        # Bulk insert items
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

        item_rows = rest_post(
            table="lesson_items",
            payload=items_payload,   # <- bulk
            select=ITEM_SELECT,
        )

        created_items = [LessonItemOut.model_validate(r) for r in item_rows]

        return LessonWithItemsOut(**lesson.model_dump(), items=created_items)

    def complete_lesson_and_update_course(self, course_id: UUID, lesson_id: UUID) -> LessonOut:
        # 1) Mark lesson complete (also ensures lesson belongs to course by filtering both)
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

        # 2) Recompute cached progress/status on the course (based on completed lessons)
        total_rows = rest_get(
            table="lessons",
            params={
                "select": "id",
                "course_id": f"eq.{str(course_id)}",
            },
        )
        total = len(total_rows)

        done_rows = rest_get(
            table="lessons",
            params={
                "select": "id",
                "course_id": f"eq.{str(course_id)}",
                "is_completed": "eq.true",
            },
        )
        done = len(done_rows)

        if total <= 0:
            progress = 0
        else:
            # floor keeps it stable and avoids 100 unless truly done
            progress = floor(done * 100 / total)

        if progress <= 0:
            status = "not_started"
        elif progress >= 100:
            status = "completed"
            progress = 100
        else:
            status = "in_progress"

        # 3) Update course cached fields
        rest_patch(
            table="courses",
            match={"id": f"eq.{str(course_id)}"},
            payload={"progress_percent": progress, "status": status},
            select="id",
        )

        return lesson