from uuid import UUID

from app.repositories.follow_repo import FollowRepo


class FollowService:
    def __init__(self, repo: FollowRepo):
        self.repo = repo

    async def get_counts(self, user_id: UUID):
        followers, following = await self.repo.get_counts(user_id)
        return {"followers": followers, "following": following}

    async def list_followers(self, user_id: UUID):
        return await self.repo.list_followers(user_id)

    async def list_following(self, user_id: UUID):
        return await self.repo.list_following(user_id)

    async def search_profiles(self, user_id: UUID, q: str, limit: int):
        return await self.repo.search_profiles(user_id=user_id, q=q, limit=limit)

    async def follow(self, follower_id: UUID, followee_id: UUID) -> None:
        await self.repo.follow(follower_id, followee_id)

    async def unfollow(self, follower_id: UUID, followee_id: UUID) -> None:
        await self.repo.unfollow(follower_id, followee_id)

    async def block(self, blocker_id: UUID, blocked_id: UUID) -> None:
        await self.repo.block(blocker_id, blocked_id)

    async def unblock(self, blocker_id: UUID, blocked_id: UUID) -> None:
        await self.repo.unblock(blocker_id, blocked_id)

    async def list_blocked_ids(self, user_id: UUID) -> list[str]:
        return await self.repo.list_blocked_ids(user_id)

    async def list_blocked(self, user_id: UUID):
        return await self.repo.list_blocked(user_id)

    async def vote(self, voter_id: UUID, target_id: UUID, delta: int) -> None:
        """
        Apply a reputation delta to target_id's user_stats.reputation.

        delta must be -2, -1, +1, or +2 (the UI controls net delta when
        switching vote direction).
        """
        if voter_id == target_id:
            from app.utils.errors import bad_request
            bad_request("cannot vote for yourself")
        await self.repo.apply_vote_delta(target_id, delta)

    async def get_own_reputation(self, user_id: UUID) -> int:
        return await self.repo.get_own_reputation(user_id)

    async def profiles_by_ids(self, user_ids: list[str]) -> list:
        return await self.repo.profiles_by_ids(user_ids)

    async def delete_account(self, user_id: UUID) -> None:
        """
        Delete all follow relationships for a user (both as follower and followee).

        This is called when a user account is deleted.
        - Removes all follows where user is the follower
        - Removes all follows where user is the followee
        """
        await self.repo.delete_account(user_id)