from datetime import date, timedelta
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
    if body.goal_minutes is not None and body.goal_minutes <= 0:
        raise HTTPException(status_code=400, detail="goal_minutes must be > 0")

    service = GoalsService(repo=SupabaseGoalsRepo())
    if body.goal_minutes is None:
        return await service.log_daily_minutes(
            user_id=x_user_id,
            seconds_delta=body.seconds_delta,
        )
    return await service.log_daily_minutes_with_goal(
        user_id=x_user_id,
        seconds_delta=body.seconds_delta,
        goal_minutes=body.goal_minutes,
    )


@router.get("/daily-activity")
async def get_daily_activity(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
):
    """
    Get the user's activity for the last 5 calendar days.
    Returns all 5 days, with 0 minutes for days with no activity.
    Response: [{"date": "YYYY-MM-DD", "minutes": int}, ...]
    """
    if not x_user_id:
        raise HTTPException(status_code=401, detail="X-User-Id header required")

    repo = SupabaseGoalsRepo()
    all_daily = await repo.list_daily_minutes(user_id=x_user_id)
    
    # Create a map of dates to minutes
    daily_map = {day: int(minutes) for day, minutes in all_daily}
    
    # Generate the last 5 calendar days
    today = date.today()
    days_range = [today - timedelta(days=i) for i in range(4, -1, -1)]  # Last 5 days in chronological order
    
    # Build activity list with all 5 days
    activity_list = [
        {"date": day.isoformat(), "minutes": daily_map.get(day, 0)}
        for day in days_range
    ]
    
    return activity_list
