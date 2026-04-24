"""
supabase_lobby_items_repo.py

Repository for reading and writing the lobby_items table.

Purpose:
- Store and retrieve the AI-generated pronunciation items for a group lobby session.
- Items are written once by the host when a lobby is created.
- Items are read by all members (host and joiners) before entering the active lobby.

Architecture rule:
routers -> repositories -> supabase client
(No service layer needed — no business logic beyond read/write.)

Notes:
- Items are keyed by (lobby_id, lobby_kind) so private and public lobbies share the same table.
- Cleanup is handled automatically by a Supabase DB trigger that fires when all
  member rows are deleted from private_lobbies / public_lobbies.
"""

from app.clients.supabase import rest_get, rest_post
from app.schemas.private_lobby_schema import LobbyItemOut


class SupabaseLobbyItemsRepo:

    def get_items(self, lobby_id: int, lobby_kind: str) -> list[LobbyItemOut]:
        """
        Fetch all items for a lobby, ordered by position ascending.

        Returns an empty list if no items have been stored yet.
        """
        rows = rest_get(
            table="lobby_items",
            params={
                "select": "position,text,ipa,hint",
                "lobby_id": f"eq.{lobby_id}",
                "lobby_kind": f"eq.{lobby_kind}",
                "order": "position.asc",
            },
        )
        return [LobbyItemOut.model_validate(row) for row in rows]

    def insert_items(
        self,
        lobby_id: int,
        lobby_kind: str,
        items: list[LobbyItemOut],
    ) -> list[LobbyItemOut]:
        """
        Bulk-insert items for a lobby session.

        Each item is stored with its position, text, and optional ipa/hint.
        Returns the inserted rows.
        """
        payload = [
            {
                "lobby_id": lobby_id,
                "lobby_kind": lobby_kind,
                "position": item.position,
                "text": item.text,
                "ipa": item.ipa,
                "hint": item.hint,
            }
            for item in items
        ]

        rows = rest_post(
            table="lobby_items",
            payload=payload,
            select="position,text,ipa,hint",
        )
        return [LobbyItemOut.model_validate(row) for row in rows]
