from fastapi import APIRouter, Depends, Header
from app.dependencies import get_profile_service
from app.schemas.profile_schema import UsernameAvailableResponse, ProfileInitRequest, ProfileInitResponse
from app.services.profile_service import ProfileService

router = APIRouter()

@router.get("/username-available")
async def username_available(username: str, svc: ProfileService = Depends(get_profile_service)):
    available = await svc.is_username_available(username)
    return {"available": available}

# Optional: server-owned profile creation (gateway sends X-User-Id)
@router.post("/profiles/init")
async def init_profile(
    body: ProfileInitRequest,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: ProfileService = Depends(get_profile_service),
):
    await svc.init_profile(
        user_id=x_user_id or "",
        username=body.username,
        full_name=body.full_name,
        native_language=body.native_language,
    )
    return {"ok": True}