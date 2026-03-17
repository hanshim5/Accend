"""
private_lobby_service.py

Service layer (business logic).

Purpose:
- Where "domain logic" lives (validation rules, permissions, workflows).
- Calls repository methods to access data.
- Keeps routers thin and repositories dumb.

Right now it's mostly pass-through, which is fine for Sprint 1.
Later you might add rules like:
- enforce title uniqueness per user
- sanitize titles
- create default lesson structure
"""

from uuid import UUID

from app.repositories.private_lobby_repo import PrivateLobbyRepo
from app.schemas.private_lobby_schema import PrivateLobbyMemberOut


class PrivateLobbyService:
    """
    The service depends on the abstract CourseRepo (interface),
    so we can swap the repo implementation later.
    """

    def __init__(self, repo: PrivateLobbyRepo):
        self.repo = repo

    def get_lobby(self, lobby_id: int) -> list[PrivateLobbyMemberOut]: 
        """Return members in a lobby."""
        return self.repo.get_lobby(lobby_id)

    def get_my_lobbies(self, user_id: str) -> list[PrivateLobbyMemberOut]:
        """Return the authenticated user's lobby rows."""
        return self.repo.get_my_lobbies(user_id)
    
    def create_lobby(self, user_id: str, username: str) -> PrivateLobbyMemberOut:
        """Create a lobby and return it."""
        return self.repo.create_lobby(user_id, username)

    def join_lobby(self, user_id: str, lobby_id: int, username: str) -> PrivateLobbyMemberOut: 
        """Creates a row with lobby ID and user, joining the user to the lobby."""
        return self.repo.join_lobby(user_id, lobby_id, username)

    def delete_row(self, user_id: str, row_id: int) -> bool:
        """Delete a private_lobbies row owned by user_id."""
        return self.repo.delete_row(user_id, row_id)
