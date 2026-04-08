"""Mint LiveKit access tokens (audio-only) for lobby participants."""

from __future__ import annotations

import datetime
from uuid import UUID

from fastapi import HTTPException
from livekit.api import AccessToken, VideoGrants

from app.config import settings
from app.schemas.livekit_schema import LiveKitTokenResponse
from app.services.lobby_membership import user_in_private_lobby, user_in_public_lobby


def _room_name(lobby_kind: str, lobby_id: int) -> str:
    # Short, URL-safe; must be consistent across clients for the same lobby.
    prefix = "pr" if lobby_kind == "private" else "pu"
    return f"{prefix}_{lobby_id}"


def create_livekit_token(
    *,
    user_id: UUID,
    display_name: str,
    lobby_id: int,
    lobby_kind: str,
) -> LiveKitTokenResponse:
    if not settings.LIVEKIT_API_KEY or not settings.LIVEKIT_API_SECRET:
        raise HTTPException(
            status_code=503,
            detail="LiveKit is not configured (LIVEKIT_API_KEY / LIVEKIT_API_SECRET).",
        )
    if not settings.LIVEKIT_PUBLIC_WS_URL:
        raise HTTPException(
            status_code=503,
            detail="LiveKit is not configured (LIVEKIT_PUBLIC_WS_URL).",
        )

    if lobby_kind == "private":
        if not user_in_private_lobby(lobby_id, user_id):
            raise HTTPException(status_code=403, detail="Not a member of this private lobby")
    else:
        if not user_in_public_lobby(lobby_id, user_id):
            raise HTTPException(status_code=403, detail="Not a member of this public lobby")

    room = _room_name(lobby_kind, lobby_id)
    # Clients should publish audio only (no camera). Token allows publish/subscribe.
    grants = VideoGrants(
        room_join=True,
        room=room,
        can_publish=True,
        can_subscribe=True,
        can_publish_data=True,
    )

    token = (
        AccessToken(settings.LIVEKIT_API_KEY, settings.LIVEKIT_API_SECRET)
        .with_identity(str(user_id))
        .with_name(display_name[:128] if display_name else str(user_id))
        .with_ttl(datetime.timedelta(hours=6))
        .with_grants(grants)
        .to_jwt()
    )

    return LiveKitTokenResponse(
        url=settings.LIVEKIT_PUBLIC_WS_URL.rstrip("/"),
        token=token,
        room_name=room,
    )
