"""
auth.py

JWT Verification Logic for Gateway

Purpose:
- Validate Supabase access tokens (modern asymmetric signing, e.g. ES256).
- Extract the authenticated user's ID (UUID).
- Reject invalid or missing tokens.

Architecture:
Flutter → Gateway (validates JWT) → internal services

Only the Gateway verifies JWT in Sprint 1.
Services trust the Gateway and use X-User-Id header.
Supabase uses ES256; gateway verifies via JWKS.
"""

from __future__ import annotations

import jwt
from jwt import PyJWKClient
from fastapi import HTTPException

from app.config import settings

# Cache JWK client so we don't recreate it for every request.
_jwk_client: PyJWKClient | None = None


def _get_jwk_client() -> PyJWKClient:
    global _jwk_client
    if _jwk_client is None:
        _jwk_client = PyJWKClient(settings.SUPABASE_JWKS_URL)
    return _jwk_client


def verify_supabase_jwt(auth_header: str | None) -> str:
    """
    Validate Authorization header and return user_id (UUID string).

    Expected:
        Authorization: Bearer <access_token>

    Verification:
    - Fetch signing key from Supabase JWKS (kid-based).
    - Verify signature (ES256) and issuer.
    - Skip audience for Sprint 1.
    """

    if not auth_header or not auth_header.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing Authorization Bearer token")

    token = auth_header.split(" ", 1)[1].strip()

    try:
        jwk_client = _get_jwk_client()
        signing_key = jwk_client.get_signing_key_from_jwt(token).key

        payload = jwt.decode(
            token,
            signing_key,
            algorithms=["ES256"],             # Supabase JWKS shows ES256
            issuer=settings.SUPABASE_JWT_ISSUER,
            options={"verify_aud": False},
        )

    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token")

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token missing sub")

    return user_id