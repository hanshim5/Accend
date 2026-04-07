from fastapi import APIRouter, Header, HTTPException

from app.repositories.supabase_goals_repo import SupabaseGoalsRepo
from app.schemas.goals_schema import GoalProgressResponse
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
