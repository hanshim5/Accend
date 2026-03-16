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

from uuid import UUID
from app.clients.supabase import rest_get, rest_post
from app.schemas.private_lobby_schema import PrivateLobbyMemberOut
from random import randint


class SupabasePrivateLobbyRepo:
    """
    Repository that reads/writes the 'private_lobbies' table using Supabase PostgREST.

    Notes:
    - Uses backend key, so it bypasses RLS.
      (That’s fine for Sprint 1, but don’t expose this service publicly
       except via gateway.)
    """

    def get_lobby(self, lobby_id: UUID) -> list[PrivateLobbyMemberOut]:
        """
        Fetch all members of a private lobby, sorted by join order
        """
        rows = rest_get(
            table="private_lobbies",
            params={
                "select": "id,lobby_id,username,user_id,title,host,session_start,joined_at",
                "lobby_id": f"eq.{str(lobby_id)}",
                "order": "joined_at.asc",
            },
        )

        return [PrivateLobbyMemberOut.model_validate(row) for row in rows]

    def create_lobby(self, user_id: UUID, username: str) -> PrivateLobbyMemberOut:
        """
        Insert a new private lobby row and return the inserted row.
        """

        # rows = rest_get(
        #     table="profiles",
        #     params={
        #         "select": "username",
        #         "id": f"eq.{str(user_id)}"
        #     }
        # )
        # username = rows[0]

        # TODO: Need to check that the lobby id doesnt exist already
        lobby_id = randint(100000, 999999)


        payload = {
            "lobby_id": lobby_id,
            "username": username,
            "user_id": str(user_id),
        }

        rows = rest_post(
            table="private_lobbies",
            payload=payload,
            select="id,lobby_id,username,user_id,host,session_start,joined_at",
        )
        if not rows:
            raise RuntimeError("Supabase REST POST returned no row")
        
        return PrivateLobbyMemberOut.model_validate(rows[0])
    
    def join_lobby(elf, user_id: UUID, lobby_id: int, username: str) -> PrivateLobbyMemberOut:
        # rows = rest_get(
        #     table="private_lobbies",
        #     params={
        #         "select": "id,lobby_id,username,user_id,host,session_start,joined_atrname",
        #         "lobby_id": f"eq.{str(lobby_id)}",
        #         "host": f"eq.TRUE"
        #     }
        # )

        # if not rows:
        #     raise RuntimeError("Supabase REST POST returned no row")
        
        # rows = rest_get(
        #     table="profiles",
        #     params={
        #         "select": "username",
        #         "id": f"eq.{str(user_id)}"
        #     }
        # )
        # username = rows[0]
        
        payload = {
            "lobby_id": lobby_id,
            "username": username,
            "user_id": str(user_id),
            "host": "FALSE",
        }

        rows = rest_post(
            table="private_lobbies",
            payload=payload,
            select="id,lobby_id,username,user_id,host,session_start,joined_at",
        )
        if not rows:
            raise RuntimeError("Supabase REST POST returned no row")
        
        return PrivateLobbyMemberOut.model_validate(rows[0])
        

