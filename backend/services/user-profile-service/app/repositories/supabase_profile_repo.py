import httpx
from app.clients.supabase import supabase
from app.repositories.profile_repo import ProfileRepo
from app.utils.errors import conflict


class SupabaseProfileRepo(ProfileRepo):

    async def username_exists(self, username: str) -> bool:
        params = {
            "select": "id",
            "username": f"eq.{username}",
            "limit": "1",
        }

        rows = await supabase.get("profiles", params=params)
        return len(rows) > 0

    async def init_profile(
        self,
        user_id: str,
        username: str,
        full_name: str | None,
        native_language: str | None,
    ) -> None:

        if await self.username_exists(username):
            conflict("Username already taken")

        payload = {
            "id": user_id,
            "username": username,
            "onboarding_complete": False,
        }

        if full_name is not None:
            payload["full_name"] = full_name

        if native_language is not None:
            payload["native_language"] = native_language

        await supabase.post("profiles", json=payload)