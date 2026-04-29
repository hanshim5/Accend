"""
Public lobby HTTP routes (matchmaking + same patterns as private_lobbies).
"""

from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, Header, HTTPException, UploadFile

from app.dependencies import get_public_lobby_service, get_lobby_items_repo
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
from app.services.public_lobby_service import PublicLobbyService
from app.repositories.supabase_lobby_items_repo import SupabaseLobbyItemsRepo

router = APIRouter(prefix="/public_lobbies", tags=["public_lobbies"])


def _get_user_id(x_user_id: str | None) -> UUID:
    if not x_user_id:
        raise HTTPException(status_code=401, detail="Missing X-User-Id")
    try:
        return UUID(x_user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid X-User-Id")


@router.get("/me", response_model=list[PrivateLobbyMemberOut])
def get_my_lobbies(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PublicLobbyService = Depends(get_public_lobby_service),
):
    user_id = _get_user_id(x_user_id)
    return svc.get_my_lobbies(user_id)


@router.post("/create", response_model=PrivateLobbyMemberOut)
def create_lobby(
    data: PrivateLobbyCreate,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PublicLobbyService = Depends(get_public_lobby_service),
):
    _get_user_id(x_user_id)
    return svc.create_lobby(data)


@router.post("/join", response_model=PrivateLobbyMemberOut)
def join_lobby(
    data: PrivateLobbyJoin,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PublicLobbyService = Depends(get_public_lobby_service),
):
    _get_user_id(x_user_id)
    return svc.join_lobby(data)


@router.post("/match", response_model=PrivateLobbyMemberOut)
def match_lobby(
    data: PrivateLobbyCreate,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PublicLobbyService = Depends(get_public_lobby_service),
):
    _get_user_id(x_user_id)
    return svc.matchmake(data)


@router.delete("/leave", response_model=PrivateLobbyDeleteOut)
def leave_lobby(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PublicLobbyService = Depends(get_public_lobby_service),
):
    user_id = _get_user_id(x_user_id)
    deleted = svc.leave_lobby(user_id)
    return {"deleted": deleted}


@router.get("/{lobby_id}", response_model=list[PrivateLobbyMemberOut])
def get_lobby(
    lobby_id: int,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PublicLobbyService = Depends(get_public_lobby_service),
):
    _get_user_id(x_user_id)
    return svc.get_lobby(lobby_id)


@router.get("/{lobby_id}/turn_state", response_model=LobbyTurnStateOut)
def get_turn_state(
    lobby_id: int,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PublicLobbyService = Depends(get_public_lobby_service),
):
    _get_user_id(x_user_id)
    return svc.get_turn_state(lobby_id)


@router.post("/{lobby_id}/turn_state/score", response_model=LobbyTurnStateOut)
def submit_turn_score(
    lobby_id: int,
    data: LobbyTurnScoreIn,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PublicLobbyService = Depends(get_public_lobby_service),
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
    svc: PublicLobbyService = Depends(get_public_lobby_service),
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
    Store the AI-generated items for this public lobby session.

    Called once by the matched host immediately after matchmaking completes.
    """
    _get_user_id(x_user_id)
    try:
        return repo.insert_items(lobby_id=lobby_id, lobby_kind="public", items=body.items)
    except RuntimeError as exc:
        raise HTTPException(status_code=502, detail=str(exc))


@router.get("/{lobby_id}/items", response_model=list[LobbyItemOut])
def get_lobby_items(
    lobby_id: int,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    repo: SupabaseLobbyItemsRepo = Depends(get_lobby_items_repo),
):
    """
    Fetch the stored session items for this public lobby.

    Called by all participants before entering the active lobby.
    """
    _get_user_id(x_user_id)
    try:
        return repo.get_items(lobby_id=lobby_id, lobby_kind="public")
    except RuntimeError as exc:
        raise HTTPException(status_code=502, detail=str(exc))


@router.post("/{lobby_id}/turn_state/pronunciation_assess")
async def assess_turn_pronunciation(
    lobby_id: int,
    audio: UploadFile = File(..., description="WAV audio file (max 10 seconds)"),
    reference_text: str = Form(..., description="Ground truth text the learner should say"),
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: PublicLobbyService = Depends(get_public_lobby_service),
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
