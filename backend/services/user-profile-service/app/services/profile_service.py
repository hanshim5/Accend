from app.repositories.profile_repo import ProfileRepo
from app.utils.errors import bad_request


class ProfileService:
    def __init__(self, repo: ProfileRepo):
        self.repo = repo

    async def is_username_available(self, username: str) -> bool:
        u = username.strip()
        if not u:
            bad_request("username is required")
        exists = await self.repo.username_exists(u)
        return not exists

    async def init_profile(
        self,
        user_id: str,
        username: str,
        full_name: str | None,
        native_language: str | None,
    ) -> None:
        if not user_id:
            bad_request("user_id missing")

        await self.repo.init_profile(
            user_id=user_id,
            username=username.strip(),
            full_name=full_name,
            native_language=native_language,
        )