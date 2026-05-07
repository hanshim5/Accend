"""
supabase_private_lobby_repo.py

Supabase implementation of PrivateLobbyRepo.

Purpose:
- Talk to the database (Supabase Postgres via PostgREST HTTP).
- This is the ONLY layer that should call the Supabase REST client helpers.

Architecture rule:
routers -> services -> repositories -> supabase client
(no DB calls in routers)
"""

from random import randint
from uuid import UUID

from app.clients.supabase import rest_delete, rest_get, rest_post
from app.schemas.private_lobby_schema import PrivateLobbyMemberOut, PrivateLobbyCreate, PrivateLobbyDeleteOut, PrivateLobbyJoin


class SupabasePrivateLobbyRepo:
    """
    Repository that reads/writes the 'private_lobbies' table using Supabase PostgREST.

    Notes:
    - Uses backend key, so it bypasses RLS.
      (That’s fine for Sprint 1, but don’t expose this service publicly
       except via gateway.)
    """

    def get_lobby(self, lobby_id: int) -> list[PrivateLobbyMemberOut]:
        """
        Fetch all members of a private lobby, sorted by join order
        """
        rows = rest_get(
            table="private_lobbies",
            params={
                "select": "id,lobby_id,username,user_id,host,session_start,joined_at",
                "lobby_id": f"eq.{str(lobby_id)}",
                "order": "joined_at.asc",
            },
        )

        return [PrivateLobbyMemberOut.model_validate(row) for row in rows]

    def get_my_lobbies(self, user_id: UUID) -> list[PrivateLobbyMemberOut]:
        rows = rest_get(
            table="private_lobbies",
            params={
                "select": "id,lobby_id,username,user_id,host,session_start,joined_at",
                "user_id": f"eq.{str(user_id)}",
                "order": "joined_at.desc",
                "limit": "10",
            },
        )
        return [PrivateLobbyMemberOut.model_validate(row) for row in rows]

    def create_lobby(self, data: PrivateLobbyCreate) -> PrivateLobbyMemberOut:
        """
        Insert a new private lobby row and return the inserted row.
        """
        lobby_id = randint(100000, 999999)

        # Remove any stale row for this user before inserting.
        rest_delete(table="private_lobbies", match={"user_id": f"eq.{data.user_id}"}, select="id")

        payload = {
            "lobby_id": lobby_id,
            "username": data.username,
            "user_id": data.user_id,
        }

        rows = rest_post(
            table="private_lobbies",
            payload=payload,
            select="id,lobby_id,username,user_id,host,session_start,joined_at",
        )
        if not rows:
            raise RuntimeError("Supabase REST POST returned no row")
        
        return PrivateLobbyMemberOut.model_validate(rows[0])
    
    def join_lobby(self, data: PrivateLobbyJoin) -> PrivateLobbyMemberOut:
        rows = rest_get(
            table="private_lobbies",
            params={
                "select": "lobby_id",
                "lobby_id": f"eq.{str(data.lobby_id)}",
                "host": f"eq.TRUE"
            }
        )

        if not rows:
            raise RuntimeError("No Lobby Available")

        # Remove any stale row for this user before inserting.
        rest_delete(table="private_lobbies", match={"user_id": f"eq.{data.user_id}"}, select="id")

        payload = {
            "lobby_id": data.lobby_id,
            "username": data.username,
            "user_id": data.user_id,
            "host": False,
        }

        rows = rest_post(
            table="private_lobbies",
            payload=payload,
            select="id,lobby_id,username,user_id,host,session_start,joined_at",
        )
        if not rows:
            raise RuntimeError("Supabase REST POST returned no row")
        
        return PrivateLobbyMemberOut.model_validate(rows[0])

    def leave_lobby(self, user_id: str) -> bool:
        
        rows = rest_delete(
            table="private_lobbies",
            match={
                "user_id": f"eq.{user_id}",
            },
            select="id",
        )
        return len(rows) > 0
        

