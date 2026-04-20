"""
config.py

Configuration Management (Progress Service)

Purpose:
- Load environment variables into a strongly-typed settings object.
- Provide centralized access to configuration values across the service.
- Ensure required variables are present at startup.

Architecture:
- Used by all layers (clients, repositories, app initialization).
- Values are loaded once and reused throughout the service.

Environment:
- Reads from .env file (local development) and system environment (production).
- Never commit real secrets to version control.

Required Variables:
- SUPABASE_URL
- SUPABASE_SERVICE_ROLE_KEY
"""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """
    Application configuration schema.

    Fields:
    - SERVICE_NAME: Used for service identification (logs, docs, etc.)
    - SUPABASE_URL: Base URL for Supabase project
    - SUPABASE_SERVICE_ROLE_KEY: Backend-only key for database access
    """

    SERVICE_NAME: str = "progress-service"

    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str
    USER_PROFILE_SERVICE_URL: str = "http://user-profile-service:8000"

    class Config:
        env_file = ".env"
        extra = "ignore"


# Singleton settings instance used across the service.
settings = Settings()
