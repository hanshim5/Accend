"""
auth.py

JWT Verification Logic for API Gateway

Purpose:
- Validate Supabase access tokens using asymmetric signing (ES256).
- Extract the authenticated user's ID (UUID).
- Reject invalid, expired, or malformed tokens.

Architecture:
Flutter → Gateway (validates JWT) → internal services → Supabase

Auth Model:
- Gateway is the ONLY component that verifies JWTs in Sprint 1.
- Downstream services trust the Gateway.
- Gateway forwards identity via X-User-Id header.

Why JWKS:
- Supabase signs tokens using asymmetric keys (ES256).
- JWKS endpoint provides public keys for verification.
- Tokens include a "kid" used to select the correct key.

Security Notes:
- Never trust tokens without verification.
- Never pass raw JWTs to downstream services.
- Only pass derived identity (user_id).
"""

from __future__ import annotations

import jwt
from jwt import PyJWKClient
from fastapi import HTTPException

from app.config import settings

# Cached JWK client to avoid re-fetching keys on every request.
# Improves performance and reduces external calls to Supabase JWKS endpoint.
_jwk_client: PyJWKClient | None = None


def _get_jwk_client() -> PyJWKClient:
    """
    Return a cached PyJWKClient instance.

    Flow:
    - First call: create client using Supabase JWKS URL.
    - Subsequent calls: reuse cached instance.

    Why:
    - Avoids repeated network calls for JWKS retrieval.
    - Improves request performance.
    """
    global _jwk_client
    if _jwk_client is None:
        _jwk_client = PyJWKClient(settings.SUPABASE_JWKS_URL)
    return _jwk_client


def verify_supabase_jwt(auth_header: str | None) -> str:
    """
    Validate Authorization header and return user_id (UUID string).

    Expected Header:
        Authorization: Bearer <access_token>

    Flow:
    1. Validate header format.
    2. Extract token string.
    3. Fetch signing key from Supabase JWKS (based on token's kid).
    4. Verify token signature and issuer.
    5. Extract user_id from 'sub' claim.
    6. Return user_id.

    Verification Details:
    - Algorithm: ES256 (Supabase standard)
    - Issuer: validated against SUPABASE_JWT_ISSUER
    - Audience: skipped for Sprint 1 (can be added later)

    Raises:
    - 401 if header is missing/invalid
    - 401 if token verification fails
    - 401 if 'sub' claim is missing
    """

    # Ensure Authorization header is present and properly formatted.
    if not auth_header or not auth_header.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing Authorization Bearer token")

    # Extract raw token string.
    token = auth_header.split(" ", 1)[1].strip()

    try:
        # Retrieve signing key using token's "kid" from JWKS.
        jwk_client = _get_jwk_client()
        signing_key = jwk_client.get_signing_key_from_jwt(token).key

        # Decode and verify token.
        payload = jwt.decode(
            token,
            signing_key,
            algorithms=["ES256"],  # Supabase uses ES256
            issuer=settings.SUPABASE_JWT_ISSUER,
            options={"verify_aud": False},  # Audience validation skipped for now
        )

    except Exception as e:
        # Do not expose internal error details to client.
        raise HTTPException(status_code=401, detail="Invalid token")

    # Extract user ID from token payload.
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token missing sub")

    return user_id