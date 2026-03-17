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

from pydantic import BaseModel

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
