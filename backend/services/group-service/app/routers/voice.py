"""
LiveKit voice: issue access tokens for clients (self-hosted LiveKit server).
"""

from uuid import UUID

from fastapi import APIRouter, Depends, Header, HTTPException

from app.schemas.livekit_schema import LiveKitTokenRequest, LiveKitTokenResponse
from app.services.livekit_voice_service import create_livekit_token


router = APIRouter(prefix="/voice", tags=["voice"])


def _get_user_id(x_user_id: str | None) -> UUID:
    if not x_user_id:
        raise HTTPException(status_code=401, detail="Missing X-User-Id")
    try:
        return UUID(x_user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid X-User-Id")


@router.post("/livekit/token", response_model=LiveKitTokenResponse)
def post_livekit_token(
    body: LiveKitTokenRequest,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
):
    user_id = _get_user_id(x_user_id)
    try:
        lobby_id_int = int(body.lobby_id.strip())
    except ValueError:
        raise HTTPException(status_code=400, detail="lobby_id must be a number")

    # Display name is optional for token; identity is the source of truth.
    return create_livekit_token(
        user_id=user_id,
        display_name=str(user_id),
        lobby_id=lobby_id_int,
        lobby_kind=body.lobby_kind,
    )
