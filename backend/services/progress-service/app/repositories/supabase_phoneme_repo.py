"""
supabase_phoneme_repo.py

Supabase Phoneme Repository

Purpose:
- Implement PhonemeRepo using Supabase PostgREST.
- Handle all persistence for the 'user_phoneme_scores' table.

Architecture:
Router → Service → Repository (this layer) → Supabase client → Database

Ownership:
- This service owns the 'user_phoneme_scores' table.
- Only this service should write to it (per architecture rules).

Security:
- Uses SUPABASE_SERVICE_ROLE_KEY (bypasses RLS).
- Safe because this service is only accessed via the API Gateway.
"""

import httpx
from app.clients.supabase import supabase
from app.repositories.phoneme_repo import PhonemeRepo

TABLE = "user_phoneme_metrics"


class SupabasePhonemeRepo(PhonemeRepo):
    """
    Supabase-backed implementation of PhonemeRepo.

    Responsibilities:
    - Fetch a user's existing phoneme scores from Supabase.
    - Upsert merged phoneme score rows back to Supabase.
    """

    async def get_scores_for_user(self, user_id: str) -> dict[str, dict]:
        """
        Fetch all phoneme score rows for the given user.

        Flow:
        1. Query user_phoneme_scores filtered by user_id.
        2. Select only the columns needed for merging (phoneme, score, attempts).
        3. Return as a dict keyed by phoneme symbol.

        Returns:
        - Dict keyed by phoneme symbol, e.g.:
          {"iy": {"score": 82.5, "attempts": 14}, "p": {"score": 71.0, "attempts": 6}}
        - Empty dict if no rows exist yet.
        """
        try:
            rows = await supabase.get(
                TABLE,
                params={
                    "select": "phoneme,current_avg_accuracy,total_attempts",
                    "user_id": f"eq.{user_id}",
                },
            )
        except httpx.HTTPStatusError:
            return {}

        return {
            row["phoneme"]: {
                "score": float(row["current_avg_accuracy"]),
                "attempts": int(row["total_attempts"]),
            }
            for row in rows
        }

    async def upsert_scores(self, rows: list[dict]) -> None:
        """
        Insert or update phoneme score rows in Supabase.

        Flow:
        1. Send all rows to Supabase with merge-duplicates resolution.
        2. Supabase upserts on (user_id, phoneme) unique constraint.

        Args:
        - rows: List of dicts each with keys: user_id, phoneme,
               current_avg_accuracy, total_attempts
        """
        if not rows:
            return

        await supabase.upsert(TABLE, rows, on_conflict="user_id,phoneme")

    async def get_cached_overall_accuracy(self, user_id: str) -> float | None:
        try:
            rows = await supabase.get(
                "user_stats",
                params={
                    "select": "overall_accuracy",
                    "user_id": f"eq.{user_id}",
                    "limit": "1",
                },
            )
        except httpx.HTTPStatusError:
            return None

        if not rows:
            return None

        value = rows[0].get("overall_accuracy")
        if value is None:
            return None
        return float(value)

    async def upsert_cached_overall_accuracy(self, user_id: str, overall_accuracy: float) -> None:
        await supabase.upsert(
            "user_stats",
            [
                {
                    "user_id": user_id,
                    "overall_accuracy": round(overall_accuracy, 2),
                }
            ],
        )
