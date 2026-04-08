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

      @abstractmethod
      async def get_cached_overall_accuracy(self, user_id: str) -> float | None:
        """
        Fetch precomputed overall_accuracy from user_stats for a user.

        Returns:
        - float value if present
        - None when no user_stats row or value exists
        """

      @abstractmethod
      async def upsert_cached_overall_accuracy(self, user_id: str, overall_accuracy: float) -> None:
        """
        Persist precomputed overall_accuracy into user_stats.
        """
