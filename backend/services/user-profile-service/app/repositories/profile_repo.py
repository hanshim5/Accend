from typing import Protocol


class ProfileRepo(Protocol):
    def username_exists(self, username: str) -> bool: ...

    async def get_profile(self, user_id: str) -> dict: ...

    def init_profile(
        self,
        user_id: str,
        username: str,
        full_name: str | None,
        native_language: str | None,
    ) -> None: ...

    async def update_onboarding(
        self,
        user_id: str,
        learning_goal: str | None = None,
        feedback_tone: str | None = None,
        accent: str | None = None,
        daily_pace: str | None = None,
        skill_assess: str | None = None,
        mark_complete: bool = False,
    ) -> None: ...