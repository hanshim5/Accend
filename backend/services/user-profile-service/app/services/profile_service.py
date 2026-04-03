"""
profile_service.py

Profile Service (Business Logic Layer)

Purpose:
- Encapsulate business logic for user profile operations.
- Validate inputs before passing to repository layer.
- Act as the intermediary between routers and repositories.

Architecture:
Router → Service (this layer) → Repository → Supabase

Design Notes:
- Keeps routers lightweight (no validation/business rules there).
- Keeps repositories focused on persistence only.
- Central place to enforce rules like required fields and normalization.

Future Extensions:
- Enforce additional username formatting rules
- Add analytics/logging for onboarding
- Add permission/ownership checks if needed
"""

import re

from app.repositories.profile_repo import ProfileRepo
from app.utils.errors import bad_request


class ProfileService:
    """
    Service layer for profile-related operations.

    Responsibilities:
    - Validate inputs (e.g., required fields, normalization)
    - Coordinate profile workflows
    - Delegate persistence to repository layer

    Dependency:
    - Uses ProfileRepo abstraction for flexibility and testability
    """

    def __init__(self, repo: ProfileRepo):
        """
        Initialize service with repository implementation.

        Dependency Injection:
        - Allows swapping repo implementations (Supabase, mock, etc.)
        """
        self.repo = repo

    def _looks_like_email(self, value: str) -> bool:
        """
        Return True if the provided value matches a simple email pattern.

        Notes:
        - Used to prevent usernames from being email-shaped.
        - Also used to validate required email input during profile init.
        """
        return bool(re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", value.strip()))

    async def get_profile(self, user_id: str) -> dict:
        """
        Retrieve a user's profile.

        Flow:
        1. Validate user_id is present.
        2. Delegate to repository.
        3. Return profile data.

        Raises:
        - bad_request if user_id is missing
        """
        if not user_id:
            bad_request("user_id missing")

        return await self.repo.get_profile(user_id)

    async def is_username_available(self, username: str) -> bool:
        """
        Check if a username is available.

        Flow:
        1. Normalize input (strip whitespace).
        2. Validate non-empty username.
        3. Reject usernames that look like emails.
        4. Query repository to check existence.
        5. Return inverse (available = not exists).

        Raises:
        - bad_request if username is empty
        - bad_request if username looks like an email address
        """
        u = username.strip()
        if not u:
            bad_request("username is required")
        if self._looks_like_email(u):
            bad_request("username cannot be an email address")

        exists = await self.repo.username_exists(u)
        return not exists

    async def init_profile(
        self,
        user_id: str,
        username: str,
        email: str,
        full_name: str | None,
        native_language: str | None,
    ) -> None:
        """
        Initialize a new user profile.

        Flow:
        1. Validate user_id.
        2. Normalize username and email (strip whitespace).
        3. Validate username is present and not email-shaped.
        4. Validate email is present and email-shaped.
        5. Delegate creation to repository.

        Notes:
        - Username uniqueness is enforced in repository layer.
        - Email uniqueness should also be enforced in persistence/database layer.
        """
        if not user_id:
            bad_request("user_id missing")

        u = username.strip()
        e = email.strip().lower()

        if not u:
            bad_request("username is required")
        if len(u) < 3:
            bad_request("username must be at least 3 characters")
        if self._looks_like_email(u):
            bad_request("username cannot be an email address")

        if not e:
            bad_request("email is required")
        if not self._looks_like_email(e):
            bad_request("valid email is required")

        await self.repo.init_profile(
            user_id=user_id,
            username=u,
            email=e,
            full_name=full_name,
            native_language=native_language,
        )

    async def update_onboarding(
        self,
        user_id: str,
        learning_goal: str | None = None,
        feedback_tone: str | None = None,
        accent: str | None = None,
        daily_pace: str | None = None,
        skill_assess: str | None = None,
        mark_complete: bool = False,
    ) -> None:
        """
        Update onboarding-related fields for a user profile.

        Flow:
        1. Validate user_id.
        2. Pass optional fields to repository.
        3. Repository performs partial update.

        Notes:
        - Supports incremental onboarding flow.
        - Only provided fields are updated.
        """
        if not user_id:
            bad_request("user_id missing")

        await self.repo.update_onboarding(
            user_id=user_id,
            learning_goal=learning_goal,
            feedback_tone=feedback_tone,
            accent=accent,
            daily_pace=daily_pace,
            skill_assess=skill_assess,
            mark_complete=mark_complete,
        )