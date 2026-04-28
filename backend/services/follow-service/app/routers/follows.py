from uuid import UUID

from fastapi import APIRouter, Body, Depends, Header, HTTPException, Query

from app.dependencies import get_follow_service
from app.schemas.follow_schema import FollowCountsOut, FollowWriteResponse, ReputationOut, SocialUserOut, VoteRequest
from app.services.follow_service import FollowService


router = APIRouter(tags=["follows"])


def _get_user_id(x_user_id: str | None) -> UUID:
    if not x_user_id:
        raise HTTPException(status_code=401, detail="Missing X-User-Id")

    try:
        return UUID(x_user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid X-User-Id")


@router.get("/followers", response_model=list[SocialUserOut])
async def list_followers(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: FollowService = Depends(get_follow_service),
):
    return await svc.list_followers(_get_user_id(x_user_id))


@router.get("/following", response_model=list[SocialUserOut])
async def list_following(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: FollowService = Depends(get_follow_service),
):
    return await svc.list_following(_get_user_id(x_user_id))


@router.get("/counts", response_model=FollowCountsOut)
async def get_counts(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: FollowService = Depends(get_follow_service),
):
    return await svc.get_counts(_get_user_id(x_user_id))


@router.get("/search", response_model=list[SocialUserOut])
async def search_profiles(
    q: str = Query(..., min_length=1),
    limit: int = Query(20, ge=1, le=50),
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: FollowService = Depends(get_follow_service),
):
    return await svc.search_profiles(_get_user_id(x_user_id), q=q, limit=limit)


@router.post("/follow/{followee_id}", response_model=FollowWriteResponse)
async def follow_user(
    followee_id: UUID,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: FollowService = Depends(get_follow_service),
):
    await svc.follow(_get_user_id(x_user_id), followee_id)
    return FollowWriteResponse(ok=True)


@router.delete("/follow/{followee_id}", response_model=FollowWriteResponse)
async def unfollow_user(
    followee_id: UUID,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: FollowService = Depends(get_follow_service),
):
    await svc.unfollow(_get_user_id(x_user_id), followee_id)
    return FollowWriteResponse(ok=True)


@router.post("/block/{blocked_id}", response_model=FollowWriteResponse)
async def block_user(
    blocked_id: UUID,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: FollowService = Depends(get_follow_service),
):
    await svc.block(_get_user_id(x_user_id), blocked_id)
    return FollowWriteResponse(ok=True)


@router.delete("/block/{blocked_id}", response_model=FollowWriteResponse)
async def unblock_user(
    blocked_id: UUID,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: FollowService = Depends(get_follow_service),
):
    await svc.unblock(_get_user_id(x_user_id), blocked_id)
    return FollowWriteResponse(ok=True)


@router.get("/blocked", response_model=list[SocialUserOut])
async def list_blocked(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: FollowService = Depends(get_follow_service),
):
    return await svc.list_blocked(_get_user_id(x_user_id))


@router.get("/blocked-ids", response_model=list[str])
async def list_blocked_ids(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: FollowService = Depends(get_follow_service),
):
    return await svc.list_blocked_ids(_get_user_id(x_user_id))


@router.delete("/account", status_code=204)
async def delete_account(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: FollowService = Depends(get_follow_service),
):
    """
    Delete all follow relationships for a user.

    Called during account deletion cascade.
    Removes all follows where user is follower or followee.
    """
    await svc.delete_account(_get_user_id(x_user_id))
    return None


@router.post("/vote/{target_id}", response_model=FollowWriteResponse)
async def vote_user(
    target_id: UUID,
    body: VoteRequest,
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: FollowService = Depends(get_follow_service),
):
    """
    Apply an upvote (+1) or downvote (-1) to target_id's reputation.

    delta must be in {-2, -1, 1, 2}.  The client tracks vote state and
    sends the correct net delta (e.g. +2 to flip from downvote to upvote).
    There is no per-voter tracking — each group session allows a fresh vote.
    """
    user_id = _get_user_id(x_user_id)
    if body.delta not in {-2, -1, 1, 2}:
        raise HTTPException(status_code=422, detail="delta must be -2, -1, 1, or 2")
    await svc.vote(user_id, target_id, body.delta)
    return FollowWriteResponse(ok=True)


@router.post("/profiles/batch", response_model=list[SocialUserOut])
async def profiles_batch(
    user_ids: list[str] = Body(...),
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: FollowService = Depends(get_follow_service),
):
    """Return profile + reputation for an arbitrary list of user IDs."""
    _get_user_id(x_user_id)  # auth guard
    return await svc.profiles_by_ids(user_ids)


@router.get("/reputation/me", response_model=ReputationOut)
async def get_own_reputation(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    svc: FollowService = Depends(get_follow_service),
):
    """Return the authenticated user's current reputation score."""
    user_id = _get_user_id(x_user_id)
    reputation = await svc.get_own_reputation(user_id)
    return ReputationOut(reputation=reputation)