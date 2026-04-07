from __future__ import annotations

from datetime import date
from typing import Protocol


class GoalsRepo(Protocol):
    async def get_today_minutes(self, user_id: str, day: date) -> int: ...

    async def get_streak(self, user_id: str) -> tuple[int, int]: ...

    async def upsert_today_minutes(self, user_id: str, day: date, minutes: int) -> int: ...
