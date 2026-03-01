"""
Configuration loader (env vars).

Purpose:
- Read required environment variables for this service.
- Fail fast on startup if required config is missing.

How:
- pydantic-settings reads variables from OS environment
- also reads from `.env` file because we set env_file=".env"

Important:
- This is service-level config. Each service can have its own .env
  or share backend/.env via docker-compose env_file.
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Reads from .env if present and ignores unknown keys
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Required env vars
    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str


# Create a singleton settings object so imports can use it
settings = Settings()