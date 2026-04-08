from __future__ import annotations

from datetime import date, timedelta
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
        goal_minutes = 10
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
        await self._recompute_and_store_streak(user_id=user_id, goal_minutes=goal_minutes)
        return DailyMinutesLogResponse(ok=True, day=today.isoformat(), total_minutes=updated)

    async def log_daily_minutes_with_goal(
        self, user_id: str, seconds_delta: int, goal_minutes: int
    ) -> DailyMinutesLogResponse:
        goal_minutes = max(1, int(goal_minutes))
        if seconds_delta <= 0:
            today = date.today()
            current = await self.repo.get_today_minutes(user_id=user_id, day=today)
            await self._recompute_and_store_streak(user_id=user_id, goal_minutes=goal_minutes)
            return DailyMinutesLogResponse(ok=True, day=today.isoformat(), total_minutes=current)

        minutes_delta = max(1, int(math.ceil(seconds_delta / 60.0)))
        today = date.today()
        current = await self.repo.get_today_minutes(user_id=user_id, day=today)
        updated = await self.repo.upsert_today_minutes(
            user_id=user_id,
            day=today,
            minutes=current + minutes_delta,
        )
        await self._recompute_and_store_streak(user_id=user_id, goal_minutes=goal_minutes)
        return DailyMinutesLogResponse(ok=True, day=today.isoformat(), total_minutes=updated)

    async def _recompute_and_store_streak(self, user_id: str, goal_minutes: int) -> None:
        rows = await self.repo.list_daily_minutes(user_id=user_id)
        qualified_days = {day for day, minutes in rows if int(minutes) >= goal_minutes}

        if not qualified_days:
            await self.repo.upsert_streak(user_id=user_id, current_streak=0, longest_streak=0)
            return

        today = date.today()
        current_streak = self._current_streak_with_intraday_grace(
            qualified_days=qualified_days,
            today=today,
        )

        sorted_days = sorted(qualified_days)
        longest_streak = 0
        run = 0
        prev: date | None = None
        for d in sorted_days:
            if prev is None or d.toordinal() == prev.toordinal() + 1:
                run += 1
            else:
                run = 1
            if run > longest_streak:
                longest_streak = run
            prev = d

        await self.repo.upsert_streak(
            user_id=user_id,
            current_streak=current_streak,
            longest_streak=longest_streak,
        )

    @staticmethod
    def _current_streak_with_intraday_grace(
        *,
        qualified_days: set[date],
        today: date,
    ) -> int:
        """
        Current streak counts consecutive goal-met days ending at the latest
        "active" day: today if already met, otherwise yesterday (so a new
        calendar day still shows yesterday's streak until the full day is
        missed or broken).
        """
        if today in qualified_days:
            cursor = today
        else:
            yesterday = today - timedelta(days=1)
            if yesterday not in qualified_days:
                return 0
            cursor = yesterday

        streak = 0
        while cursor in qualified_days:
            streak += 1
            cursor = cursor - timedelta(days=1)
        return streak
