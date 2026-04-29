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

from fastapi import APIRouter, Depends, File, Form, Header, HTTPException, UploadFile

from app.dependencies import get_private_lobby_service, get_lobby_items_repo
from app.schemas.private_lobby_schema import (
    LobbyItemOut,
    LobbyTurnScoreIn,
    LobbyTurnStateOut,
    PrivateLobbyCreate,
    PrivateLobbyDeleteOut,
    PrivateLobbyJoin,
    PrivateLobbyMemberOut,
    SetLobbyItemsReq,
)
from app.services.private_lobby_service import PrivateLobbyService
from app.repositories.supabase_lobby_items_repo import SupabaseLobbyItemsRepo


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


@router.get("/me", response_model=list[PrivateLobbyMemberOut])
def get_my_lobbies(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PrivateLobbyService = Depends(get_private_lobby_service),
):
    user_id = _get_user_id(x_user_id)
    return svc.get_my_lobbies(user_id)


@router.post("/create", response_model=PrivateLobbyMemberOut)
def create_lobby(
    data: PrivateLobbyCreate,
    # Extract user identity from header
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),

    # Inject service layer
    svc: PrivateLobbyService = Depends(get_private_lobby_service),
):
    """
   
    """

    user_id = _get_user_id(x_user_id)
    return svc.create_lobby(data)

@router.post("/join", response_model=PrivateLobbyMemberOut)
def join_lobby(

    data: PrivateLobbyJoin,
    # Extract user identity from header
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),

    # Inject service layer
    svc: PrivateLobbyService = Depends(get_private_lobby_service),
):

    user_id = _get_user_id(x_user_id)
    return svc.join_lobby(data)


@router.delete("/leave", response_model=PrivateLobbyDeleteOut)
def leave_lobby(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PrivateLobbyService = Depends(get_private_lobby_service),
):
    user_id = _get_user_id(x_user_id)
    deleted = svc.leave_lobby(user_id)
    return {"deleted": deleted}


@router.get("/{lobby_id}/turn_state", response_model=LobbyTurnStateOut)
def get_turn_state(
    lobby_id: int,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PrivateLobbyService = Depends(get_private_lobby_service),
):
    _get_user_id(x_user_id)
    return svc.get_turn_state(lobby_id)


@router.post("/{lobby_id}/turn_state/score", response_model=LobbyTurnStateOut)
def submit_turn_score(
    lobby_id: int,
    data: LobbyTurnScoreIn,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PrivateLobbyService = Depends(get_private_lobby_service),
):
    user_id = _get_user_id(x_user_id)
    try:
        return svc.submit_turn_score(
            lobby_id=lobby_id,
            actor_user_id=str(user_id),
            score=data.score,
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@router.post("/{lobby_id}/turn_state/vote_next_round", response_model=LobbyTurnStateOut)
def vote_next_round(
    lobby_id: int,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PrivateLobbyService = Depends(get_private_lobby_service),
):
    user_id = _get_user_id(x_user_id)
    try:
        return svc.vote_next_round(
            lobby_id=lobby_id,
            actor_user_id=str(user_id),
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@router.post("/{lobby_id}/items", response_model=list[LobbyItemOut])
def set_lobby_items(
    lobby_id: int,
    body: SetLobbyItemsReq,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    repo: SupabaseLobbyItemsRepo = Depends(get_lobby_items_repo),
):
    """
    Store the AI-generated items for this lobby session.

    Called once by the host immediately after creating the lobby.
    Joiners do not call this — they read via GET.
    """
    _get_user_id(x_user_id)
    try:
        return repo.insert_items(lobby_id=lobby_id, lobby_kind="private", items=body.items)
    except RuntimeError as exc:
        raise HTTPException(status_code=502, detail=str(exc))


@router.get("/{lobby_id}/items", response_model=list[LobbyItemOut])
def get_lobby_items(
    lobby_id: int,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    repo: SupabaseLobbyItemsRepo = Depends(get_lobby_items_repo),
):
    """
    Fetch the stored session items for this lobby.

    Called by joiners (and optionally the host) before entering the active lobby.
    Returns an empty list if items have not been stored yet.
    """
    _get_user_id(x_user_id)
    try:
        return repo.get_items(lobby_id=lobby_id, lobby_kind="private")
    except RuntimeError as exc:
        raise HTTPException(status_code=502, detail=str(exc))


@router.post("/{lobby_id}/turn_state/pronunciation_assess")
async def assess_turn_pronunciation(
    lobby_id: int,
    audio: UploadFile = File(..., description="WAV audio file (max 10 seconds)"),
    reference_text: str = Form(..., description="Ground truth text the learner should say"),
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PrivateLobbyService = Depends(get_private_lobby_service),
):
    user_id = _get_user_id(x_user_id)
    try:
        content = await audio.read()
        filename = audio.filename or "audio.wav"
        return await svc.assess_turn_pronunciation(
            lobby_id=lobby_id,
            actor_user_id=str(user_id),
            audio_bytes=content,
            filename=filename,
            reference_text=reference_text,
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=502, detail=str(exc))

