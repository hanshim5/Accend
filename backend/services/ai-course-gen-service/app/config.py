"""
config.py

AI Course Gen Service Configuration

Purpose:
- Load optional environment variables needed for Supabase access.
- Kept intentionally lightweight: most config is read via os.getenv in service code.
- Supabase credentials are optional at startup so existing endpoints work without them;
  they are validated at runtime when the phoneme-metrics endpoint is actually called.
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Required for POST /generate-course-from-metrics.
    # Optional here so the service starts without them when not needed.
    SUPABASE_URL: str | None = None
    SUPABASE_SERVICE_ROLE_KEY: str | None = None


settings = Settings()
