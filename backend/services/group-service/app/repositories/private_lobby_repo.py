"""
private_lobby_repo.py

Repository interface (contract).

Purpose:
- Define the methods our service layer expects for course data.
- Allows us to swap implementations later (Supabase now, SQLAlchemy later)
  without changing business logic.

Why Protocol:
- Protocol is like an "interface" in Python.
- Any class that implements these methods is considered a PrivateLobbyRepo.
"""

from typing import Protocol
from uuid import UUID
from app.schemas.private_lobby_schema import PrivateLobbyMemberOut, PrivateLobbyCreate, PrivateLobbyDeleteOut


class PrivateLobbyRepo(Protocol):
    """
    Data access contract for courses.

    The service layer (CourseService) depends on this abstraction,
    not on Supabase directly.

    That keeps our code modular and migration-friendly.
    """
    def get_lobby(self, lobby_id: int) -> list[PrivateLobbyMemberOut]: ...
    def get_my_lobbies(self, user_id: str) -> list[PrivateLobbyMemberOut]: ...
    def create_lobby(self, data: PrivateLobbyCreate) -> PrivateLobbyMemberOut: ...
    def join_lobby(self, user_id: str, lobby_id: int, username: str) -> PrivateLobbyMemberOut: ...
    def delete_row(self, user_id: str, row_id: int) -> bool: ...