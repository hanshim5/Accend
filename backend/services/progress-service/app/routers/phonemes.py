"""
phonemes.py

Phoneme Progress Router

Purpose:
- Expose the POST /phonemes/batch endpoint.
- Receive aggregated phoneme scores from the API Gateway after a practice session.
- Delegate to the PhonemeService for weighted-average merging and persistence.

Architecture:
Gateway → Router (this layer) → Service → Repository → Supabase

Identity:
- User identity is extracted from the X-User-Id header, which is set by the
  API Gateway after JWT verification. Internal services trust this header.
"""

from fastapi import APIRouter, Header, HTTPException

from app.repositories.supabase_phoneme_repo import SupabasePhonemeRepo
from app.schemas.phoneme_schema import PhonemesBatchUpdateRequest, PhonemesBatchUpdateResponse
from app.services.phoneme_service import PhonemeService

router = APIRouter()


@router.post("/phonemes/batch", response_model=PhonemesBatchUpdateResponse)
async def batch_update_phonemes(
    body: PhonemesBatchUpdateRequest,
    x_user_id: str | None = Header(default=None),
):
    """
    Merge a practice session's phoneme scores into the user's persistent record.

    Called by the API Gateway after the Flutter app finishes a solo practice
    session. Each phoneme entry carries the session-average accuracy and how
    many times the phoneme appeared, enabling a proper weighted merge with
    previously stored scores.

    Flow:
    1. Validate X-User-Id header is present.
    2. Instantiate service with Supabase repository.
    3. Run weighted-average merge and upsert updated rows.
    4. Return count of rows updated.

    Identity:
    - X-User-Id is set by the API Gateway after JWT verification.
    - Not present → 401 Unauthorized.
    """
    if not x_user_id:
        raise HTTPException(status_code=401, detail="X-User-Id header required")

    service = PhonemeService(repo=SupabasePhonemeRepo())

    updated = await service.batch_update(
        user_id=x_user_id,
        phoneme_scores=body.phoneme_scores,
    )

    return PhonemesBatchUpdateResponse(updated=updated)


@router.get("/phonemes/overall-accuracy")
async def get_overall_phoneme_accuracy(
    x_user_id: str | None = Header(default=None),
):
    """
    Return weighted overall phoneme accuracy for the authenticated user.
    """
    if not x_user_id:
        raise HTTPException(status_code=401, detail="X-User-Id header required")

    service = PhonemeService(repo=SupabasePhonemeRepo())
    overall_accuracy = await service.get_overall_accuracy(user_id=x_user_id)
    return {"overall_accuracy": overall_accuracy}
