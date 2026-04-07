from __future__ import annotations

from datetime import date, datetime, timezone

import httpx

from app.clients.supabase import supabase
from app.repositories.goals_repo import GoalsRepo


class SupabaseGoalsRepo(GoalsRepo):
    def _utc_now_iso(self) -> str:
        return datetime.now(timezone.utc).isoformat()

    async def get_today_minutes(self, user_id: str, day: date) -> int:
        try:
            rows = await supabase.get(
                "daily_minutes",
                params={
                    "select": "minutes",
                    "user_id": f"eq.{user_id}",
                    "day": f"eq.{day.isoformat()}",
                    "limit": "1",
                },
            )
        except httpx.HTTPStatusError:
            return 0

        if not rows:
            return 0
        return int(rows[0].get("minutes", 0) or 0)

    async def get_streak(self, user_id: str) -> tuple[int, int]:
        try:
            rows = await supabase.get(
                "streaks",
                params={
                    "select": "current_streak,longest_streak",
                    "user_id": f"eq.{user_id}",
                    "limit": "1",
                },
            )
        except httpx.HTTPStatusError:
            return 0, 0

        if not rows:
            return 0, 0

        row = rows[0]
        return int(row.get("current_streak", 0) or 0), int(row.get("longest_streak", 0) or 0)

    async def upsert_today_minutes(self, user_id: str, day: date, minutes: int) -> int:
        minutes = max(0, int(minutes))
        try:
            await supabase.upsert(
                "daily_minutes",
                [
                    {
                        "user_id": user_id,
                        "day": day.isoformat(),
                        "minutes": minutes,
                        "updated_at": self._utc_now_iso(),
                    }
                ],
            )
        except httpx.HTTPStatusError:
            # If write fails, return the current value we attempted.
            return minutes
        return minutes

    async def list_daily_minutes(self, user_id: str) -> list[tuple[date, int]]:
        try:
            rows = await supabase.get(
                "daily_minutes",
                params={
                    "select": "day,minutes",
                    "user_id": f"eq.{user_id}",
                    "order": "day.asc",
                },
            )
        except httpx.HTTPStatusError:
            return []

        result: list[tuple[date, int]] = []
        for row in rows:
            day_raw = row.get("day")
            if not day_raw:
                continue
            try:
                parsed_day = date.fromisoformat(str(day_raw))
            except ValueError:
                continue
            result.append((parsed_day, int(row.get("minutes", 0) or 0)))
        return result

    async def upsert_streak(self, user_id: str, current_streak: int, longest_streak: int) -> None:
        try:
            await supabase.upsert(
                "streaks",
                [
                    {
                        "user_id": user_id,
                        "current_streak": max(0, int(current_streak)),
                        "longest_streak": max(0, int(longest_streak)),
                        "updated_at": self._utc_now_iso(),
                    }
                ],
            )
        except httpx.HTTPStatusError:
            return
