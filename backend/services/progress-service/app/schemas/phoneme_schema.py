"""
phoneme_schema.py

Pydantic Schemas — Phoneme Progress

Purpose:
- Define request/response shapes for the phoneme batch-update endpoint.
- Validate incoming data from the API Gateway.

Architecture:
Router → (these schemas) → Service → Repository → Supabase

Table: user_phoneme_metrics
Columns:
  user_id              TEXT        — from X-User-Id header (set by Gateway)
  phoneme              TEXT        — ARPAbet symbol (e.g. "iy", "p")
  current_avg_accuracy FLOAT8      — weighted running average accuracy (0–100)
  total_attempts       INTEGER     — total number of times this phoneme has been scored
  updated_at           TIMESTAMPTZ — auto-managed by trigger or set on upsert
UNIQUE(user_id, phoneme)
"""

from pydantic import BaseModel, Field


class PhonemeScoreInput(BaseModel):
    """
    A single phoneme's aggregated score from one practice session.

    Fields:
    - symbol: ARPAbet phoneme identifier (e.g. "iy", "sh", "p")
    - score: Average accuracy for this phoneme across the session (0–100)
    - count: How many times the phoneme appeared in the session (used for
             weighted-average merging with existing persistent data)
    """

    symbol: str = Field(min_length=1, max_length=10)
    score: float = Field(ge=0.0, le=100.0)
    count: int = Field(ge=1)


class PhonemesBatchUpdateRequest(BaseModel):
    """
    Batch request to update a user's phoneme scores after a practice session.

    All phoneme entries in the batch are merged with the user's existing
    persistent scores using a weighted running average so that historical
    performance is preserved.
    """

    phoneme_scores: list[PhonemeScoreInput] = Field(min_length=1)


class PhonemesBatchUpdateResponse(BaseModel):
    """
    Confirmation returned after a successful batch update.

    Fields:
    - updated: Number of phoneme rows that were inserted or updated.
    """

    updated: int
