from __future__ import annotations

from datetime import date
import math

from app.repositories.goals_repo import GoalsRepo
from app.schemas.goals_schema import GoalProgressResponse, DailyMinutesLogResponse


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

    async def log_daily_minutes(self, user_id: str, seconds_delta: int) -> DailyMinutesLogResponse:
        if seconds_delta <= 0:
            today = date.today()
            current = await self.repo.get_today_minutes(user_id=user_id, day=today)
            return DailyMinutesLogResponse(ok=True, day=today.isoformat(), total_minutes=current)

        # Convert elapsed seconds into minute increments.
        minutes_delta = max(1, int(math.ceil(seconds_delta / 60.0)))
        today = date.today()
        current = await self.repo.get_today_minutes(user_id=user_id, day=today)
        updated = await self.repo.upsert_today_minutes(
            user_id=user_id,
            day=today,
            minutes=current + minutes_delta,
        )
        return DailyMinutesLogResponse(ok=True, day=today.isoformat(), total_minutes=updated)
