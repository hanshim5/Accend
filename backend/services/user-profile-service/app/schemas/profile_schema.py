from pydantic import BaseModel, Field

class UsernameAvailableResponse(BaseModel):
    available: bool

class ProfileInitRequest(BaseModel):
    username: str = Field(min_length=3)
    full_name: str | None = None
    native_language: str | None = None

class ProfileInitResponse(BaseModel):
    ok: bool