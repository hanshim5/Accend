from uuid import UUID

from app.repositories.follow_repo import FollowRepo


class FollowService:
    def __init__(self, repo: FollowRepo):
        self.repo = repo

    async def list_followers(self, user_id: UUID):
        return await self.repo.list_followers(user_id)

    async def list_following(self, user_id: UUID):
        return await self.repo.list_following(user_id)

    async def follow(self, follower_id: UUID, followee_id: UUID) -> None:
        await self.repo.follow(follower_id, followee_id)

    async def unfollow(self, follower_id: UUID, followee_id: UUID) -> None:
        await self.repo.unfollow(follower_id, followee_id)