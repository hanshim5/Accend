"""
profile.py

Profile Router (API Layer)

Purpose:
- Define HTTP endpoints for user profile operations.
- Handle request parsing, header extraction, and response shaping.
- Delegate all business logic to the ProfileService.

Architecture:
Client (Flutter) → Gateway → Profile Service (this router) → Service → Repository → Supabase

Auth Model:
- Gateway validates JWT and injects X-User-Id header.
- This service trusts the header but still passes it through consistently.
- Future improvements could include stricter validation (like UUID parsing).

Endpoints:
- GET    /profiles/me
- GET    /username-available
- POST   /profiles/init
- PATCH  /profiles/onboarding

Rules:
- No database access here
- No business logic here
- Only validation + delegation
"""

from fastapi import APIRouter, Depends, Header

from app.dependencies import get_profile_service
from app.schemas.profile_schema import (
    UsernameAvailableResponse,
    ProfileInitRequest,
    ProfileInitResponse,
    ProfileDetailsUpdate,
    ProfileReadResponse,
    ProfileOnboardingUpdate,
    ProfileImageUpdate,
    ProfileImageResponse,
)
from app.services.profile_service import ProfileService


# Router for profile-related endpoints
router = APIRouter()


@router.get("/profiles/me")
async def get_profile(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: ProfileService = Depends(get_profile_service),
) -> ProfileReadResponse:
    """
    Get the authenticated user's profile.

    Flow:
    1. Extract user_id from X-User-Id header (provided by Gateway).
    2. Call service layer to fetch profile.
    3. Return response validated as ProfileReadResponse.

    Notes:
    - Assumes Gateway already authenticated the user.
    - If header is missing, empty string is passed (service/repo should handle).
    """
    profile = await svc.get_profile(x_user_id or "")
    return ProfileReadResponse(**profile)


@router.get("/username-available")
async def username_available(
    username: str,
    svc: ProfileService = Depends(get_profile_service),
) -> UsernameAvailableResponse:
    """
    Check if a username is available.

    Flow:
    1. Receive username as query parameter.
    2. Call service to check availability.
    3. Return boolean result.

    Usage:
    - Called during onboarding before profile creation.
    """
    available = await svc.is_username_available(username)
    return UsernameAvailableResponse(available=available)


@router.post("/profiles/init")
async def init_profile(
    body: ProfileInitRequest,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: ProfileService = Depends(get_profile_service),
) -> ProfileInitResponse:
    """
    Initialize a new user profile.

    Flow:
    1. Parse request body (username, email, full_name, native_language).
    2. Extract user_id from header.
    3. Call service to create profile.
    4. Return success response.

    Notes:
    - Typically called after user signs up/logs in.
    - Username uniqueness is enforced in repository layer.
    """
    await svc.init_profile(
        user_id=x_user_id or "",
        username=body.username,
        email=body.email,
        full_name=body.full_name,
        native_language=body.native_language,
    )
    return ProfileInitResponse(ok=True)


@router.patch("/profiles/onboarding")
async def patch_onboarding(
    body: ProfileOnboardingUpdate,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: ProfileService = Depends(get_profile_service),
) -> ProfileInitResponse:
    """
    Update onboarding-related profile fields.

    Flow:
    1. Parse partial update body (only provided fields).
    2. Extract user_id from header.
    3. Call service to update onboarding fields.
    4. Return success response.

    Notes:
    - Uses PATCH semantics (partial updates).
    - exclude_unset=True ensures only provided fields are updated.
    - Supports multi-step onboarding flow.
    """
    await svc.update_onboarding(
        user_id=x_user_id or "",
        **body.dict(exclude_unset=True),
    )
    return ProfileInitResponse(ok=True)


@router.patch("/profiles/me")
async def patch_profile_details(
    body: ProfileDetailsUpdate,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: ProfileService = Depends(get_profile_service),
) -> ProfileInitResponse:
    await svc.update_profile_details(
        user_id=x_user_id or "",
        **body.dict(exclude_unset=True),
    )
    return ProfileInitResponse(ok=True)


@router.get("/profiles/me/image")
async def get_profile_image(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: ProfileService = Depends(get_profile_service),
) -> ProfileImageResponse:
    profile = await svc.get_profile(x_user_id or "")
    return ProfileImageResponse(profile_image_url=profile.get("profile_image_url"))


@router.patch("/profiles/me/image")
async def patch_profile_image(
    body: ProfileImageUpdate,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: ProfileService = Depends(get_profile_service),
) -> ProfileInitResponse:
    await svc.update_profile_image(
        user_id=x_user_id or "",
        profile_image_url=body.profile_image_url,
    )
    return ProfileInitResponse(ok=True)


@router.delete("/profiles/me")
async def delete_account(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: ProfileService = Depends(get_profile_service),
) -> ProfileInitResponse:
    """
    Delete the authenticated user's account and profile.

    Flow:
    1. Extract user_id from X-User-Id header.
    2. Call service to delete profile.
    3. Return success response.

    Notes:
    - Cascading deletion of user data from other services is handled by gateway.
    - This only deletes the user's profile from this service.
    """
    await svc.delete_account(x_user_id or "")
    return ProfileInitResponse(ok=True)