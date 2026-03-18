"""
config.py

Configuration Management (Profile Service)

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

Design Notes:
- Uses pydantic-settings for validation and type safety.
- Missing required variables will raise errors at startup.
"""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """
    Application configuration schema.

    Fields:
    - SERVICE_NAME: Used for service identification (logs, docs, etc.)
    - SUPABASE_URL: Base URL for Supabase project
    - SUPABASE_SERVICE_ROLE_KEY: Backend-only key for database access

    Notes:
    - SERVICE_NAME has a default value.
    - Other fields must be provided via environment variables.
    """

    SERVICE_NAME: str = "user-profile-service"

    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str

    class Config:
        """
        Pydantic configuration for environment loading.

        - env_file: Loads variables from .env during development
        - extra: Ignore unknown environment variables
        """
        env_file = ".env"
        extra = "ignore"


# Singleton settings instance used across the service.
# Loaded once at startup for consistent configuration access.
settings = Settings()