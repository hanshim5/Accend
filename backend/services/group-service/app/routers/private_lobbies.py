"""
private_lobbies.py

Private Lobby Router

Purpose:
- Define HTTP endpoints for the courses-service.
- Handle request validation and response formatting.
- Extract user identity from the X-User-Id header (set by the Gateway).
- Delegate business logic to the CourseService.

Architecture rule:
routers -> services -> repositories -> supabase

This file should NOT:
- Talk directly to the database
- Contain business logic
- Validate JWTs (Gateway handles that)

It only:
- Extracts inputs (headers + body)
- Validates basic things
- Calls the service layer
"""

from uuid import UUID

from fastapi import APIRouter, Depends, Header, HTTPException

from app.dependencies import get_private_lobby_service
from app.schemas.private_lobby_schema import PrivateLobbyMemberOut
from app.services.private_lobby_service import PrivateLobbyService


# Router is mounted with prefix="/courses"
# So endpoints here become:
# GET  /courses
# POST /courses
router = APIRouter(prefix="/private_lobbies", tags=["private_lobbies"])


def _get_user_id(x_user_id: str | None) -> UUID:
    """
    Extract and validate the X-User-Id header.

    Why:
    - We are using "Gateway-validated auth".
    - Gateway verifies JWT and forwards the authenticated user's UUID
      via the X-User-Id header.
    - This service trusts that header (internal-only communication).

    What this does:
    1. Ensure header exists
    2. Ensure it is a valid UUID
    3. Return UUID object for strong typing

    Raises:
    - 401 if header missing
    - 400 if header is not a valid UUID
    """

    if not x_user_id:
        # If gateway didn't forward user id, request is unauthorized
        raise HTTPException(status_code=401, detail="Missing X-User-Id")

    try:
        return UUID(x_user_id)
    except Exception:
        # If header value is not a valid UUID string
        raise HTTPException(status_code=400, detail="Invalid X-User-Id")


@router.get("/{lobby_id}", response_model=list[PrivateLobbyMemberOut])
def get_lobby(
    lobby_id: int,
    
    # FastAPI extracts X-User-Id header and assigns it here
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),


    # Dependency injection:
    # FastAPI calls get_course_service() and injects the result
    svc: PrivateLobbyService = Depends(get_private_lobby_service),
):
    """
    ***NOT TRUE LEO WILL FIX FOR GROUP PRIVATE STUFF L8R
    GET /courses

    Returns all courses belonging to the authenticated user.

    Flow:
    1. Extract user_id from header
    2. Call service layer
    3. Service calls repository
    4. Repository calls Supabase
    5. Return structured CourseOut list

    response_model ensures:
    - Output matches CourseOut schema
    - UUIDs and datetimes are serialized properly
    """

    _get_user_id(x_user_id)
    return svc.get_lobby(lobby_id)


@router.post("", response_model=PrivateLobbyMemberOut)
def create_lobby(

    username: str,
    # Extract user identity from header
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),

    # Inject service layer
    svc: PrivateLobbyService = Depends(get_private_lobby_service),
):
    """
    POST /courses

    Creates a new course for the authenticated user.

    Request body example:
    {
        "title": "Travel phrases for restaurants"
    }

    Flow:
    1. FastAPI validates request body using CourseCreate schema
    2. Extract user_id from header
    3. Call service layer
    4. Service calls repository
    5. Repository inserts into Supabase
    6. Return newly created course as CourseOut

    response_model ensures:
    - Returned data matches CourseOut structure
    - Types are validated before sending response
    """

    user_id = _get_user_id(x_user_id)
    return svc.create_lobby(user_id, username)

@router.post("/join", response_model=PrivateLobbyMemberOut)
def join_lobby(

    lobby_id: int,
    username: str,
    # Extract user identity from header
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),

    # Inject service layer
    svc: PrivateLobbyService = Depends(get_private_lobby_service),
):

    user_id = _get_user_id(x_user_id)
    return svc.join_lobby(user_id, lobby_id, username)