"""Request/response for LiveKit voice tokens."""

from typing import Literal

from pydantic import BaseModel, Field


class LiveKitTokenRequest(BaseModel):
    lobby_id: str = Field(min_length=1, description="Six-digit lobby id as string")
    lobby_kind: Literal["private", "public"] = "private"


class LiveKitTokenResponse(BaseModel):
    url: str = Field(description="WebSocket URL for LiveKit (e.g. wss://host:7880)")
    token: str
    room_name: str
