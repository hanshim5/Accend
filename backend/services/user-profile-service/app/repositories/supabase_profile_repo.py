"""
supabase_profile_repo.py

Supabase Profile Repository

Purpose:
- Implement ProfileRepo using Supabase PostgREST.
- Handle all persistence for the 'profiles' table.
- Convert raw database responses into structured data for the service layer.

Architecture:
Router → Service → Repository (this layer) → Supabase client → Database

Ownership:
- This service owns the 'profiles' table.
- Only this service should write to it (per architecture rules).

Security:
- Uses SUPABASE_SERVICE_ROLE_KEY (bypasses RLS).
- Safe because this service is only accessed via the API Gateway.
"""

import httpx
from app.clients.supabase import supabase
from app.repositories.profile_repo import ProfileRepo
from app.utils.errors import conflict, not_found


class SupabaseProfileRepo(ProfileRepo):
    """
    Supabase-backed implementation of ProfileRepo.

    Responsibilities:
    - Fetch user profile data
    - Check username availability
    - Initialize new profiles
    - Update onboarding fields

    Notes:
    - Uses async Supabase client
    - Returns raw dicts (service layer may shape further if needed)
    """

    async def get_profile(self, user_id: str) -> dict:
        """
        Retrieve a user's profile by ID.

        Flow:
        1. Query 'profiles' table filtered by user_id.
        2. Limit to a single result.
        3. Raise not_found if no profile exists.
        4. Return the first row.

        Returns:
        - Dictionary representing the user's profile
        """
        rows = await supabase.get(
            "profiles",
            params={
                "select": "id,username,onboarding_complete,email,native_language,full_name,learning_goal,feedback_tone,accent,daily_pace,skill_assess,focus_areas,profile_image_url",
                "id": f"eq.{user_id}",
                "limit": "1",
            },
        )

        if not rows:
            not_found("profile not found for user")

        return rows[0]

    async def username_exists(self, username: str) -> bool:
        """
        Check if a username is already taken.

        Flow:
        1. Query profiles table for matching username.
        2. Limit to one result for efficiency.
        3. Return True if any row exists.

        Returns:
        - True if username exists
        - False otherwise
        """
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
        email: str,
        full_name: str | None,
        native_language: str | None,
    ) -> None:
        """
        Initialize a new user profile.

        Flow:
        1. Check if username is already taken.
        2. Build insert payload with required fields.
        3. Optionally include full_name and native_language.
        4. Insert row into 'profiles' table.

        Raises:
        - conflict if username is already taken
        """

        # Ensure username uniqueness before inserting.
        if await self.username_exists(username):
            conflict("Username already taken")

        # Base payload for new profile.
        payload = {
            "id": user_id,
            "username": username,
            "email": email,
            "onboarding_complete": False,
        }

        # Optional fields (only included if provided).
        if full_name is not None:
            payload["full_name"] = full_name

        if native_language is not None:
            payload["native_language"] = native_language

        # Insert new profile row.
        await supabase.post("profiles", json=payload)

    async def update_onboarding(
        self,
        user_id: str,
        learning_goal: str | None = None,
        feedback_tone: str | None = None,
        accent: str | None = None,
        daily_pace: str | None = None,
        skill_assess: str | None = None,
        focus_areas: str | None = None,
        mark_complete: bool = False,
    ) -> None:
        """
        Update onboarding-related fields for a user profile.

        Flow:
        1. Build a partial update payload from provided fields.
        2. If mark_complete is True, set onboarding_complete flag.
        3. If no fields provided, do nothing.
        4. Send PATCH request to Supabase.

        Notes:
        - Only provided fields are updated (partial update).
        - Safe to call multiple times during onboarding flow.
        """

        payload: dict[str, object] = {}

        # Add fields only if provided (prevents overwriting with None).
        if learning_goal is not None:
            payload["learning_goal"] = learning_goal
        if feedback_tone is not None:
            payload["feedback_tone"] = feedback_tone
        if accent is not None:
            payload["accent"] = accent
        if daily_pace is not None:
            payload["daily_pace"] = daily_pace
        if skill_assess is not None:
            payload["skill_assess"] = skill_assess
        if focus_areas is not None:
            payload["focus_areas"] = focus_areas
        if mark_complete:
            payload["onboarding_complete"] = True

        # If nothing to update, exit early.
        if not payload:
            return

        # Perform partial update via Supabase.
        await supabase.patch(
            "profiles",
            json=payload,
            params={"id": f"eq.{user_id}"},
        )

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
    ) -> None:
        payload: dict[str, object] = {}

        if full_name is not None:
            payload["full_name"] = full_name
        if native_language is not None:
            payload["native_language"] = native_language
        if learning_goal is not None:
            payload["learning_goal"] = learning_goal
        if feedback_tone is not None:
            payload["feedback_tone"] = feedback_tone
        if accent is not None:
            payload["accent"] = accent
        if daily_pace is not None:
            payload["daily_pace"] = daily_pace
        if focus_areas is not None:
            payload["focus_areas"] = focus_areas

        if not payload:
            return

        await supabase.patch(
            "profiles",
            json=payload,
            params={"id": f"eq.{user_id}"},
        )

    async def update_profile_image(self, user_id: str, profile_image_url: str) -> None:
        await supabase.patch(
            "profiles",
            json={"profile_image_url": profile_image_url},
            params={"id": f"eq.{user_id}"},
        )

    async def delete_profile(self, user_id: str) -> None:
        """
        Delete a user's profile.

        Flow:
        1. Delete the profile row matching user_id.
        2. Silently succeed if profile does not exist.

        Notes:
        - This is typically called as part of account deletion cascade.
        - Uses DELETE with filter on id.
        """
        await supabase.delete(
            "profiles",
            params={"id": f"eq.{user_id}"},
        )