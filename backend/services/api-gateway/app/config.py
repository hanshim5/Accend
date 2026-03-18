"""
config.py

API Gateway Configuration

Purpose:
- Load and validate environment variables required by the API Gateway.
- Provide centralized access to configuration values across the gateway.
- Fail fast at startup if required configuration is missing.

Architecture:
- Used by all gateway components (auth, routing, service calls).
- Acts as the single source of truth for service URLs and secrets.

Environment Sources:
- OS environment variables (production)
- backend/.env file (development via pydantic-settings)

Security:
- Contains sensitive values (service role key, JWT config).
- Never commit real secrets to version control.
- Gateway is the only service that uses JWT verification settings.
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Gateway configuration schema.

    Supabase Config:
    - SUPABASE_URL: Base URL of Supabase project
    - SUPABASE_SERVICE_ROLE_KEY: Backend key for internal operations
    - SUPABASE_JWT_SECRET: (legacy / optional depending on setup)
    - SUPABASE_JWKS_URL: Public key endpoint for JWT verification
    - SUPABASE_JWT_ISSUER: Expected issuer for JWT validation

    Internal Service URLs:
    - URLs for routing requests to downstream microservices
    - Injected via docker-compose

    Dev Flags:
    - ALLOW_ANON_PRONUNCIATION_ASSESS:
        Allows skipping JWT validation for pronunciation endpoint in dev only
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
    # These URLs are used by the gateway to forward requests
    # to the appropriate microservices.
    COURSES_SERVICE_URL: str
    AI_COURSE_GEN_SERVICE_URL: str
    PRONUNCIATION_FEEDBACK_SERVICE_URL: str
    GROUP_SERVICE_URL: str
    USER_PROFILE_SERVICE_URL: str

    # -------------------------
    # Development Flags
    # -------------------------
    # Allows skipping JWT validation for pronunciation endpoint in dev.
    # Must be disabled in production.
    ALLOW_ANON_PRONUNCIATION_ASSESS: bool = True


# Singleton settings instance loaded at startup.
# Ensures consistent configuration access across the gateway.
settings = Settings()