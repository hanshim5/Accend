"""
Gateway Configuration

Purpose:
- Load environment variables needed by Gateway.
- Fail fast if required keys are missing.

Loaded from:
- OS environment variables
- backend/.env file (via pydantic-settings)
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Load from .env and ignore unknown keys
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Supabase credentials
    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str
    SUPABASE_JWT_SECRET: str
    SUPABASE_JWKS_URL: str
    SUPABASE_JWT_ISSUER: str

    # Internal service URLs (docker-compose injects these)
    COURSES_SERVICE_URL: str
    AI_COURSE_GEN_SERVICE_URL: str
    PRONUNCIATION_FEEDBACK_SERVICE_URL: str


# Singleton settings object
settings = Settings()