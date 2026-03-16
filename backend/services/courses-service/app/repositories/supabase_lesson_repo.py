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
    CurriculumCreate,
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

        # Ensure stable ordering within each lesson
        for lesson_id, arr in items_by_lesson.items():
            arr.sort(key=lambda x: x.position)

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

        if not items_payload:
            raise RuntimeError("Lesson contains no items")

        item_rows = rest_post(
            table="lesson_items",
            payload=items_payload,
            select=ITEM_SELECT,
        )

        created_items = [LessonItemOut.model_validate(r) for r in item_rows]
        created_items.sort(key=lambda x: x.position)

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
            progress = floor(done * 100 / total)

        if progress <= 0:
            status = "not_started"
        elif done >= total and total > 0:
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

    def create_curriculum(self, course_id: UUID, data: CurriculumCreate) -> list[LessonWithItemsOut]:
        # 1) Bulk insert lessons (server assigns positions by array order)
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

        lesson_rows = rest_post(
            table="lessons",
            payload=lessons_payload,
            select=LESSON_SELECT,
        )
        if not lesson_rows:
            raise RuntimeError("Bulk insert lessons returned no rows")

        inserted_lessons = [LessonOut.model_validate(r) for r in lesson_rows]

        # Map position -> lesson_id so we can attach items
        lesson_id_by_position = {l.position: l.id for l in inserted_lessons}

        # 2) Bulk insert ALL items across ALL lessons
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

        item_rows = rest_post(
            table="lesson_items",
            payload=items_payload,
            select=ITEM_SELECT,
        )
        inserted_items = [LessonItemOut.model_validate(r) for r in item_rows]

        # Group items by lesson_id for return shape
        items_by_lesson: dict[UUID, list[LessonItemOut]] = {}
        for it in inserted_items:
            items_by_lesson.setdefault(it.lesson_id, []).append(it)

        # Ensure stable ordering within each lesson
        for lesson_id, arr in items_by_lesson.items():
            arr.sort(key=lambda x: x.position)

        # Return lessons in order with their items
        out: list[LessonWithItemsOut] = []
        for l in sorted(inserted_lessons, key=lambda x: x.position):
            out.append(
                LessonWithItemsOut(
                    **l.model_dump(),
                    items=items_by_lesson.get(l.id, []),
                )
            )

        return out