"""
config.py

API Gateway Configuration

Purpose:
- Load and validate environment variables required by the API Gateway.
- Provide centralized access to configuration values across the gateway.
- Fail fast at startup if required configuration is missing.

Architecture:
- Used by gateway auth, routing, and downstream service calls.
- Acts as the single source of truth for service URLs and secrets.

Environment Sources:
- OS environment variables (production)
- backend/.env file (development via pydantic-settings)

Security:
- Contains sensitive backend-only values such as service role keys and JWT settings.
- Real secrets should never be committed to version control.
- The Gateway is the only service that uses JWT verification configuration directly.
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Configuration schema for the API Gateway.

    Supabase Configuration:
    - SUPABASE_URL: Base URL of the Supabase project
    - SUPABASE_SERVICE_ROLE_KEY: Backend-only key for internal database access
    - SUPABASE_JWT_SECRET: Legacy JWT secret setting (kept for compatibility)
    - SUPABASE_JWKS_URL: Public JWKS endpoint used for JWT verification
    - SUPABASE_JWT_ISSUER: Expected issuer claim for Supabase JWTs

    Internal Service URLs:
    - Base URLs used by the Gateway to proxy or orchestrate requests
      across downstream microservices

    Development Flags:
    - ALLOW_ANON_PRONUNCIATION_ASSESS:
      Allows POST /pronunciation/assess to skip JWT validation in local/dev only
    """

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # -------------------------
    # Supabase (Auth + DB)
    # -------------------------
    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str
    SUPABASE_JWT_SECRET: str
    SUPABASE_JWKS_URL: str
    SUPABASE_JWT_ISSUER: str

    # -------------------------
    # Internal Service Routing
    # -------------------------
    # These base URLs are used by the Gateway to forward requests
    # to the correct downstream microservice.
    COURSES_SERVICE_URL: str
    AI_COURSE_GEN_SERVICE_URL: str
    PRONUNCIATION_FEEDBACK_SERVICE_URL: str
    GROUP_SERVICE_URL: str
    FOLLOW_SERVICE_URL: str
    USER_PROFILE_SERVICE_URL: str

    # -------------------------
    # Development Flags
    # -------------------------
    # Allows skipping JWT validation for pronunciation assessment in local/dev.
    # This should remain disabled in production environments.
    ALLOW_ANON_PRONUNCIATION_ASSESS: bool = True


# Singleton settings instance loaded at startup.
# Ensures configuration is parsed once and reused consistently.
settings = Settings()