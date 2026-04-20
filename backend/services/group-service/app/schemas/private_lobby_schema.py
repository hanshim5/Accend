"""
course_schema.py

Pydantic schemas for request/response shapes.

Purpose:
- Define the "API contract" for courses endpoints.
- Validate inputs and structure outputs consistently.

Rule of thumb:
- PrivateLobbyCreate = What the client sends to create a private lobby.
- JoinPrivateLobby   = What the client needs to join a user to a lobby.
- GetPrivateLobby    = What the api returns to the client.
"""

from datetime import datetime

from pydantic import BaseModel, Field

class PrivateLobbyCreate(BaseModel):
    """
    Request shape for creating a private lobby.

    Fields:
    - username: The name of the user creating the lobby. Required to set the host and create the first member.
    """

    username: str
    user_id: str

class PrivateLobbyJoin(BaseModel):
    """
    Request shape for joining a private lobby.

    Fields:
    - user_id: The ID of the user joining the lobby.
    - lobby_id: The ID of the lobby to join.
    - username: The name of the user joining the lobby.
    """
    lobby_id: int
    username: str
    user_id: str

class PrivateLobbyMemberOut(BaseModel):
    """
    Response shape for a member of a private lobby  returned from the DB.

    Fields match the columns we select from Supabase.
    Supabase returns JSON, and Pydantic converts types:
    - id/user_id -> UUID
    - created_at -> datetime
    """

    id: str
    lobby_id: int
    username: str
    user_id: str
    host: bool
    session_start: bool
    joined_at: datetime


class PrivateLobbyDeleteOut(BaseModel):
    deleted: bool


class LobbyTurnParticipantOut(BaseModel):
    user_id: str
    username: str
    turn_order: int
    score: float | None = None


class LobbyTurnStateOut(BaseModel):
    lobby_id: int
    lobby_kind: str
    current_turn_index: int
    participants: list[LobbyTurnParticipantOut]
    round_complete: bool
    event_seq: int
    latest_scored_user_id: str | None = None


class LobbyTurnScoreIn(BaseModel):
    score: float = Field(ge=0, le=100)
