"""
config.py

Configuration loader (env vars).

Purpose:
- Read required environment variables for this service.
- Fail fast on startup if required config is missing.

How:
- pydantic-settings reads variables from OS environment
- also reads from `.env` file because we set env_file=".env"

Important:
- Loads `backend/.env` then `group-service/.env` (later overrides) so LIVEKIT_*
  can live in the monorepo `backend/.env` when cwd is not group-service.
"""

from pathlib import Path

from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict

# This file: group-service/app/config.py
_SERVICE_ROOT = Path(__file__).resolve().parent.parent
_BACKEND_ROOT = _SERVICE_ROOT.parent.parent

_env_candidates = (
    _BACKEND_ROOT / ".env",
    _SERVICE_ROOT / ".env",
)
_env_files = tuple(p for p in _env_candidates if p.is_file())


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=_env_files if _env_files else (".env",),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Required env vars
    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str

    # LiveKit: keys from cloud dashboard or `livekit-server --keys`; URL is what clients use (wss://…).
    # LIVEKIT_URL is accepted as an alias (common when copying from LiveKit Cloud UI).
    LIVEKIT_API_KEY: str = ""
    LIVEKIT_API_SECRET: str = ""
    LIVEKIT_PUBLIC_WS_URL: str = Field(
        default="",
        validation_alias=AliasChoices("LIVEKIT_PUBLIC_WS_URL", "LIVEKIT_URL"),
    )


# Create a singleton settings object so imports can use it
settings = Settings()