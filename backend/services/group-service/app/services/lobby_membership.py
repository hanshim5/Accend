"""Verify a user belongs to a lobby before issuing LiveKit tokens."""

from uuid import UUID

from app.clients.supabase import rest_get


def user_in_private_lobby(lobby_id: int, user_id: UUID) -> bool:
    rows = rest_get(
        table="private_lobbies",
        params={
            "select": "id",
            "lobby_id": f"eq.{lobby_id}",
            "user_id": f"eq.{str(user_id)}",
            "limit": "1",
        },
    )
    return len(rows) > 0


def user_in_public_lobby(lobby_id: int, user_id: UUID) -> bool:
    rows = rest_get(
        table="public_lobbies",
        params={
            "select": "id",
            "lobby_id": f"eq.{lobby_id}",
            "user_id": f"eq.{str(user_id)}",
            "limit": "1",
        },
    )
    return len(rows) > 0
