"""
lessons.py

Lesson Routes (API Layer)

Purpose:
- Expose HTTP endpoints for lesson-related operations.
- Handle request validation, authentication headers, and response shaping.
- Delegate all business logic to the LessonService.

Architecture:
Client (Flutter) → Gateway → Lessons Service (this router) → Service → Repository → Supabase

Auth Model:
- Gateway validates JWT and injects X-User-Id header.
- This service trusts the gateway but still validates presence/format of X-User-Id.
- Ownership/authorization checks can be added later using this user_id.

Endpoints:
- GET    /courses/{course_id}/lessons
- POST   /courses/{course_id}/lessons
- POST   /courses/{course_id}/lessons/{lesson_id}/complete
- POST   /courses/{course_id}/curriculum
"""

from fastapi import APIRouter, Depends, Header, HTTPException
from uuid import UUID

from app.dependencies import get_lesson_service
from app.schemas.lesson_schema import LessonCreate, LessonWithItemsOut, LessonOut, CurriculumCreate
from app.services.lesson_service import LessonService


# Router for all lesson-related endpoints.
router = APIRouter(tags=["lessons"])


def _get_user_id(x_user_id: str | None) -> UUID:
    """
    Validate and parse X-User-Id header into a UUID.

    Purpose:
    - Ensure requests include a valid user identifier from the gateway.
    - Maintain a consistent validation pattern across all routes.

    Notes:
    - We trust the gateway for auth, but still validate structure.
    - This can later be used for ownership checks (e.g., course belongs to user).
    """
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
    """
    Get full curriculum for a course (lessons + lesson items).

    Flow:
    1. Validate user header (ensures request came through gateway).
    2. Delegate to service layer.
    3. Return structured lessons with nested items.

    Note:
    - user_id is not currently used, but kept for consistency and future authorization.
    """
    _get_user_id(x_user_id)
    return svc.list_lessons_with_items(course_id)


@router.get("/lessons/completed-count")
def completed_lessons_count(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: LessonService = Depends(get_lesson_service),
):
    """
    Return lesson-driven stats across all courses owned by the authenticated user.
    """
    user_id = _get_user_id(x_user_id)
    return svc.get_learning_stats(user_id)


@router.post("/lessons/backfill-levels")
def backfill_levels(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: LessonService = Depends(get_lesson_service),
):
    """
    Backfill profile levels for existing users.

    Requires authenticated caller, then performs a service-side migration.
    """
    _get_user_id(x_user_id)
    return svc.backfill_profile_levels()


@router.post("/courses/{course_id}/lessons", response_model=LessonWithItemsOut)
def create_lesson(
    course_id: UUID,
    body: LessonCreate,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: LessonService = Depends(get_lesson_service),
):
    """
    Create a single lesson and its items for a course.

    Flow:
    1. Validate user header.
    2. Pass request body to service layer.
    3. Return created lesson with items.

    Usage:
    - Typically called by the AI service via the gateway.
    - Could later enforce that the course belongs to the user.
    """
    _get_user_id(x_user_id)
    return svc.create_lesson_with_items(course_id, body)


@router.post("/courses/{course_id}/lessons/{lesson_id}/complete", response_model=LessonOut)
def complete_lesson(
    course_id: UUID,
    lesson_id: UUID,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: LessonService = Depends(get_lesson_service),
):
    """
    Mark a lesson as completed and update course progress.

    Flow:
    1. Validate user header.
    2. Delegate completion logic to service layer.
    3. Return updated lesson.

    Side Effects:
    - Triggers recalculation of course progress_percent and status.
    """
    user_id = _get_user_id(x_user_id)
    return svc.complete_lesson_and_update_course(user_id, course_id, lesson_id)


@router.post("/courses/{course_id}/curriculum", response_model=list[LessonWithItemsOut])
def create_curriculum(
    course_id: UUID,
    body: CurriculumCreate,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: LessonService = Depends(get_lesson_service),
):
    """
    Create a full curriculum (multiple lessons + items) in one request.

    Flow:
    1. Validate user header.
    2. Pass structured curriculum data to service layer.
    3. Return full curriculum with lessons and items.

    Usage:
    - Primarily used by AI course generation flow.
    - Enables bulk creation instead of multiple single lesson calls.
    """
    _get_user_id(x_user_id)
    return svc.create_curriculum(course_id, body)