"""
phoneme_service.py

Phoneme Service (Business Logic Layer)

Purpose:
- Encapsulate the weighted-average merge logic for phoneme score updates.
- Validate inputs before passing to the repository layer.
- Act as the intermediary between routers and repositories.

Architecture:
Router → Service (this layer) → Repository → Supabase

Weighted-average merge strategy:
- Existing persistent score for a phoneme is combined with the new session
  score using a true weighted average:

    merged_score = (existing_score * existing_attempts + session_score * session_count)
                   / (existing_attempts + session_count)

  This preserves historical performance over many sessions while still
  letting recent improvements shift the score appropriately.
"""

from app.repositories.phoneme_repo import PhonemeRepo
from app.schemas.phoneme_schema import PhonemeScoreInput
from app.utils.errors import bad_request


class PhonemeService:
    """
    Service layer for phoneme progress operations.

    Responsibilities:
    - Validate user_id and incoming phoneme score payload.
    - Fetch the user's existing phoneme scores.
    - Compute weighted-average merges for each phoneme.
    - Delegate the final upsert to the repository.
    """

    def __init__(self, repo: PhonemeRepo):
        self.repo = repo

    async def batch_update(
        self,
        user_id: str,
        phoneme_scores: list[PhonemeScoreInput],
    ) -> int:
        """
        Merge a session's phoneme scores into the user's persistent scores.

        Flow:
        1. Validate user_id is present.
        2. Validate phoneme_scores list is non-empty.
        3. Fetch existing scores for this user.
        4. For each incoming phoneme, compute the weighted average with the
           existing persistent score (or use the session score if none exists).
        5. Build upsert rows and delegate to the repository.
        6. Return the count of rows upserted.

        Args:
        - user_id: Authenticated user's Supabase UUID (from X-User-Id).
        - phoneme_scores: Session phoneme scores from the Flutter client.

        Returns:
        - Number of phoneme rows inserted/updated.

        Raises:
        - 400 if user_id is missing or phoneme_scores is empty.
        """
        if not user_id:
            bad_request("user_id missing")

        if not phoneme_scores:
            bad_request("phoneme_scores must not be empty")

        existing = await self.repo.get_scores_for_user(user_id)

        rows: list[dict] = []

        for entry in phoneme_scores:
            symbol = entry.symbol.lower().strip()
            session_score = entry.score
            session_count = entry.count

            if symbol not in existing:
                # No prior history — use the session score as the starting value.
                merged_score = session_score
                total_attempts = session_count
            else:
                prev = existing[symbol]
                prev_score = prev["score"]
                prev_attempts = prev["attempts"]

                # True weighted average preserving historical performance.
                total_attempts = prev_attempts + session_count
                merged_score = (
                    prev_score * prev_attempts + session_score * session_count
                ) / total_attempts

            rows.append(
                {
                    "user_id": user_id,
                    "phoneme": symbol,
                    "current_avg_accuracy": round(merged_score, 4),
                    "total_attempts": total_attempts,
                }
            )

        await self.repo.upsert_scores(rows)

        return len(rows)
