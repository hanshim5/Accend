"""
profile_repo.py

Profile Repository Interface (Contract)

Purpose:
- Define the required data access methods for user profile operations.
- Decouple the service layer from the underlying database implementation.
- Enable swapping implementations (e.g., Supabase → SQLAlchemy) without changing business logic.

Architecture:
Router → Service → Repository (this interface) → Database

Why Protocol:
- Acts like an interface using Python's structural typing.
- Any class implementing these methods satisfies ProfileRepo.
- Enables easy testing (mock repos) and future flexibility.

Design Notes:
- Defines WHAT operations are available, not HOW they are implemented.
- Concrete implementation lives in supabase_profile_repo.py.
"""

from typing import Protocol


class ProfileRepo(Protocol):
    """
    Contract for profile data access.

    Responsibilities:
    - Handle profile creation, retrieval, and updates.
    - Abstract away persistence details from the service layer.

    Used by:
    - ProfileService (business logic layer)
    """

    async def username_exists(self, username: str) -> bool: ...
    """
    Check if a username is already taken.

    Expected Behavior:
    - Return True if username exists in the database.
    - Return False if username is available.
    """

    async def get_profile(self, user_id: str) -> dict: ...
    """
    Retrieve a user's profile by user_id.

    Expected Behavior:
    - Return profile data as a dictionary.
    - Return empty or raise if profile does not exist (implementation-dependent).
    """

    async def init_profile(
        self,
        user_id: str,
        username: str,
        email: str,
        full_name: str | None,
        native_language: str | None,
    ) -> None: ...
    """
    Initialize a new user profile.

    Expected Behavior:
    - Insert a new profile row for the given user_id.
    - Populate initial fields such as username, email, full_name, and native_language.
    - Called during onboarding/registration.
    """

    async def update_onboarding(
        self,
        user_id: str,
        native_language: str | None = None,
        learning_goal: str | None = None,
        feedback_tone: str | None = None,
        accent: str | None = None,
        daily_pace: str | None = None,
        skill_assess: str | None = None,
        focus_areas: str | None = None,
        mark_complete: bool = False,
    ) -> None: ...

    async def update_profile_details(
        self,
        user_id: str,
        full_name: str | None = None,
        native_language: str | None = None,
        learning_goal: str | None = None,
        feedback_tone: str | None = None,
        accent: str | None = None,
        daily_pace: str | None = None,
        focus_areas: str | None = None,
    ) -> None: ...

    async def update_streak(
        self,
        user_id: str,
        current_streak: int,
        longest_streak: int,
    ) -> None: ...
    """
    Update onboarding-related fields for a user's profile.

    Fields:
    - learning_goal: User's objective (e.g., fluency, pronunciation)
    - feedback_tone: Preferred feedback style (e.g., strict, encouraging)
    - accent: Target accent (e.g., American, British)
    - daily_pace: Desired daily workload
    - skill_assess: Initial skill assessment result
    - mark_complete: Whether onboarding is finished

    Expected Behavior:
    - Perform partial update (only provided fields).
    - Mark onboarding as complete if specified.
    """

    async def update_profile_image(self, user_id: str, profile_image_url: str) -> None: ...

    async def delete_profile(self, user_id: str) -> None: ...
    """
    Delete a user's profile.

    Expected Behavior:
    - Delete the profile row for the given user_id.
    - This is called as part of account deletion cascade.
    - Should succeed silently if profile does not exist.
    """