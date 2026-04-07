from fastapi import APIRouter, Header, HTTPException

from app.repositories.supabase_goals_repo import SupabaseGoalsRepo
from app.schemas.goals_schema import (
    GoalProgressResponse,
    DailyMinutesLogRequest,
    DailyMinutesLogResponse,
)
from app.services.goals_service import GoalsService

router = APIRouter()


@router.get("/goals/progress", response_model=GoalProgressResponse)
async def get_goals_progress(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
):
    if not x_user_id:
        raise HTTPException(status_code=401, detail="X-User-Id header required")

    service = GoalsService(repo=SupabaseGoalsRepo())
    return await service.get_goal_progress(user_id=x_user_id)


@router.post("/daily-minutes", response_model=DailyMinutesLogResponse)
async def post_daily_minutes(
    body: DailyMinutesLogRequest,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
):
    if not x_user_id:
        raise HTTPException(status_code=401, detail="X-User-Id header required")
    if body.seconds_delta < 0:
        raise HTTPException(status_code=400, detail="seconds_delta must be >= 0")

    service = GoalsService(repo=SupabaseGoalsRepo())
    return await service.log_daily_minutes(
        user_id=x_user_id,
        seconds_delta=body.seconds_delta,
    )
