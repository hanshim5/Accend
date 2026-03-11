"""
lessons.py
"""

from fastapi import APIRouter, Depends, Header, HTTPException
from uuid import UUID

from app.dependencies import get_lesson_service
from app.schemas.lesson_schema import LessonCreate, LessonWithItemsOut, LessonOut
from app.services.lesson_service import LessonService


router = APIRouter(tags=["lessons"])


def _get_user_id(x_user_id: str | None) -> UUID:
    if not x_user_id:
        raise HTTPException(status_code=401, detail="Missing X-User-Id")
    try:
        return UUID(x_user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid X-User-Id")


@router.get("/courses/{course_id}/lessons", response_model=list[LessonWithItemsOut])
def list_lessons(
    course_id: UUID,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: LessonService = Depends(get_lesson_service),
):
    # We trust auth, but keeping the pattern consistent. (We don't use user_id here yet.)
    _get_user_id(x_user_id)
    return svc.list_lessons_with_items(course_id)


@router.post("/courses/{course_id}/lessons", response_model=LessonWithItemsOut)
def create_lesson(
    course_id: UUID,
    body: LessonCreate,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: LessonService = Depends(get_lesson_service),
):
    # Used by AI service via gateway; user_id could be used later to enforce ownership.
    _get_user_id(x_user_id)
    return svc.create_lesson_with_items(course_id, body)


@router.post("/courses/{course_id}/lessons/{lesson_id}/complete", response_model=LessonOut)
def complete_lesson(
    course_id: UUID,
    lesson_id: UUID,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: LessonService = Depends(get_lesson_service),
):
    _get_user_id(x_user_id)
    return svc.complete_lesson_and_update_course(course_id, lesson_id)