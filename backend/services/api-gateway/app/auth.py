"""
JWT Verification Logic for Gateway

Purpose:
- Validate Supabase access tokens.
- Extract the authenticated user's ID (UUID).
- Reject invalid or missing tokens.

Architecture:
Flutter → Gateway (validates JWT) → internal services

Only the Gateway verifies JWT in Sprint 1.
Services trust the Gateway and use X-User-Id header.
"""

import jwt
from fastapi import HTTPException
from app.config import settings


def verify_supabase_jwt(auth_header: str | None) -> str:
    """
    Validate Authorization header and return user_id (UUID string).

    Expected header:
        Authorization: Bearer <access_token>

    Steps:
    1. Ensure header exists and starts with "Bearer ".
    2. Extract JWT token.
    3. Decode using SUPABASE_JWT_SECRET.
    4. Extract 'sub' field (Supabase user ID).
    """

    # Step 1: Validate header format
    if not auth_header or not auth_header.lower().startswith("bearer "):
        raise HTTPException(
            status_code=401,
            detail="Missing Authorization Bearer token",
        )

    # Step 2: Extract token string
    token = auth_header.split(" ", 1)[1].strip()

    try:
        # Step 3: Decode token
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],

            # For Sprint 1 we keep verification simple.
            # In production you may enable:
            # verify_aud=True, verify_iss=True
            options={
                "verify_aud": False,
                "verify_iss": False,
            },
        )

    except jwt.PyJWTError:
        # Any decode failure → Unauthorized
        raise HTTPException(status_code=401, detail="Invalid token")

    # Step 4: Extract user id
    user_id = payload.get("sub")

    if not user_id:
        raise HTTPException(status_code=401, detail="Token missing sub")

    return user_id