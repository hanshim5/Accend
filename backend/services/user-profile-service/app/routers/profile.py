from fastapi import APIRouter, Depends, Header

from app.dependencies import get_profile_service
from app.schemas.profile_schema import (
    UsernameAvailableResponse,
    ProfileInitRequest,
    ProfileInitResponse,
    ProfileReadResponse,
    ProfileOnboardingUpdate,
)
from app.services.profile_service import ProfileService


router = APIRouter()


@router.get("/profiles/me")
async def get_profile(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: ProfileService = Depends(get_profile_service),
) -> ProfileReadResponse:
    profile = await svc.get_profile(x_user_id or "")
    return ProfileReadResponse(**profile)


@router.get("/username-available")
async def username_available(
    username: str,
    svc: ProfileService = Depends(get_profile_service),
) -> UsernameAvailableResponse:
    available = await svc.is_username_available(username)
    return UsernameAvailableResponse(available=available)


@router.post("/profiles/init")
async def init_profile(
    body: ProfileInitRequest,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: ProfileService = Depends(get_profile_service),
) -> ProfileInitResponse:
    await svc.init_profile(
        user_id=x_user_id or "",
        username=body.username,
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
    await svc.update_onboarding(
        user_id=x_user_id or "",
        **body.dict(exclude_unset=True),
    )
    return ProfileInitResponse(ok=True)