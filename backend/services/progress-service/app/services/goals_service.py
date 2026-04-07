from __future__ import annotations

from datetime import date

from app.repositories.goals_repo import GoalsRepo
from app.schemas.goals_schema import GoalProgressResponse


class GoalsService:
    def __init__(self, repo: GoalsRepo):
        self.repo = repo

    async def get_goal_progress(self, user_id: str) -> GoalProgressResponse:
        current_minutes = await self.repo.get_today_minutes(user_id=user_id, day=date.today())
        current_streak, longest_streak = await self.repo.get_streak(user_id=user_id)
        return GoalProgressResponse(
            current_streak=current_streak,
            longest_streak=longest_streak,
            current_minutes=current_minutes,
            goal_minutes=10,
        )
