"""
Supabase implementation for public_lobbies (matchmaking).
Mirrors private_lobby patterns; table name is public_lobbies.
"""

from __future__ import annotations

from collections import defaultdict
from random import randint
from uuid import UUID

from app.clients.supabase import rest_delete, rest_get, rest_post
from app.schemas.private_lobby_schema import (
    PrivateLobbyCreate,
    PrivateLobbyJoin,
    PrivateLobbyMemberOut,
)


class SupabasePublicLobbyRepo:
    """Reads/writes the public_lobbies table via PostgREST."""

    def get_lobby(self, lobby_id: int) -> list[PrivateLobbyMemberOut]:
        rows = rest_get(
            table="public_lobbies",
            params={
                "select": "id,lobby_id,username,user_id,host,session_start,joined_at",
                "lobby_id": f"eq.{str(lobby_id)}",
                "order": "joined_at.asc",
            },
        )
        return [PrivateLobbyMemberOut.model_validate(row) for row in rows]

    def get_my_lobbies(self, user_id: UUID) -> list[PrivateLobbyMemberOut]:
        rows = rest_get(
            table="public_lobbies",
            params={
                "select": "id,lobby_id,username,user_id,host,session_start,joined_at",
                "user_id": f"eq.{str(user_id)}",
                "order": "joined_at.desc",
                "limit": "10",
            },
        )
        return [PrivateLobbyMemberOut.model_validate(row) for row in rows]

    def find_oldest_joinable_lobby_id(self) -> int | None:
        """
        Oldest lobby = smallest min(joined_at) among lobbies with session_start=false
        and member count < 5.
        """
        rows = rest_get(
            table="public_lobbies",
            params={
                "select": "lobby_id,joined_at",
                "session_start": "eq.false",
                "order": "joined_at.asc",
            },
        )
        by_lobby: dict[int, list[dict]] = defaultdict(list)
        for row in rows:
            lid = row["lobby_id"]
            lid_int = int(lid) if not isinstance(lid, int) else lid
            by_lobby[lid_int].append(row)

        best: tuple[str, int] | None = None  # (min joined_at iso, lobby_id)
        for lid, members in by_lobby.items():
            if len(members) >= 5:
                continue
            min_j = min(m["joined_at"] for m in members)
            if best is None or min_j < best[0]:
                best = (min_j, lid)
        return best[1] if best else None

    def create_lobby(self, data: PrivateLobbyCreate) -> PrivateLobbyMemberOut:
        lobby_id = randint(100000, 999999)
        payload = {
            "lobby_id": lobby_id,
            "username": data.username,
            "user_id": data.user_id,
        }
        rows = rest_post(
            table="public_lobbies",
            payload=payload,
            select="id,lobby_id,username,user_id,host,session_start,joined_at",
        )
        if not rows:
            raise RuntimeError("Supabase REST POST returned no row")
        return PrivateLobbyMemberOut.model_validate(rows[0])

    def join_lobby(self, data: PrivateLobbyJoin) -> PrivateLobbyMemberOut:
        rows = rest_get(
            table="public_lobbies",
            params={
                "select": "lobby_id",
                "lobby_id": f"eq.{str(data.lobby_id)}",
                "host": "eq.TRUE",
            },
        )
        if not rows:
            raise RuntimeError("No Lobby Available")

        payload = {
            "lobby_id": data.lobby_id,
            "username": data.username,
            "user_id": data.user_id,
            "host": False,
        }
        rows = rest_post(
            table="public_lobbies",
            payload=payload,
            select="id,lobby_id,username,user_id,host,session_start,joined_at",
        )
        if not rows:
            raise RuntimeError("Supabase REST POST returned no row")
        return PrivateLobbyMemberOut.model_validate(rows[0])

    def leave_lobby(self, user_id: str) -> bool:
        rows = rest_delete(
            table="public_lobbies",
            match={
                "user_id": f"eq.{user_id}",
            },
            select="id",
        )
        return len(rows) > 0
