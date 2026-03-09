from typing import Protocol

class ProfileRepo(Protocol):
    def username_exists(self, username: str) -> bool: ...
    def init_profile(
        self,
        user_id: str,
        username: str,
        full_name: str | None,
        native_language: str | None,
    ) -> None: ...