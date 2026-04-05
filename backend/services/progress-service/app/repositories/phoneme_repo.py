"""
phoneme_repo.py

Phoneme Repository Interface

Purpose:
- Define the abstract contract for phoneme data persistence.
- Decouple service logic from any specific database implementation.

Architecture:
Service → Repository (this interface) → Implementation → Supabase
"""

from abc import ABC, abstractmethod


class PhonemeRepo(ABC):
    """
    Abstract repository for user phoneme score data.

    Implementations:
    - SupabasePhonemeRepo: backed by Supabase PostgREST
    """

    @abstractmethod
    async def get_scores_for_user(self, user_id: str) -> dict[str, dict]:
        """
        Fetch all existing phoneme score rows for a user.

        Args:
        - user_id: Supabase user UUID

        Returns:
        - Dict keyed by phoneme symbol → row dict with 'score' and 'attempts'
          e.g. {"iy": {"score": 82.5, "attempts": 14}, ...}
        """

    @abstractmethod
    async def upsert_scores(self, rows: list[dict]) -> None:
        """
        Insert or update phoneme score rows.

        Each row must include: user_id, phoneme, score, attempts.

        Args:
        - rows: List of dicts representing rows to upsert
        """
