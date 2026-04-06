"""
profile_schema.py

Profile Schemas (Data Models)

Purpose:
- Define request and response shapes for profile-related endpoints.
- Validate incoming data and ensure consistent API responses.
- Serve as the contract between frontend (Flutter) and backend.

Architecture:
- Routers use these schemas for request parsing and response serialization.
- Services and repositories operate on validated data from these schemas.
- These map closely to the 'profiles' table but are API-focused.

Schema Types:
- Request models → data sent from client (create/update)
- Response models → data returned to client
"""

from pydantic import BaseModel, Field


class UsernameAvailableResponse(BaseModel):
    """
    Response schema for username availability check.

    Fields:
    - available: True if username is not taken, False otherwise
    """
    available: bool


class ProfileInitRequest(BaseModel):
    """
    Request schema for initializing a user profile.

    Fields:
    - username: Desired username (minimum length enforced)
    - email: email of account used for auth and login
    - full_name: Optional display name
    - native_language: Optional user-native language

    Notes:
    - Used during onboarding after authentication.
    """
    username: str = Field(min_length=3)
    email: str = Field(min_length=3)
    full_name: str | None = None
    native_language: str | None = None


class ProfileInitResponse(BaseModel):
    """
    Response schema for profile initialization.

    Fields:
    - ok: Indicates whether the operation succeeded
    """
    ok: bool


class ProfileReadResponse(BaseModel):
    """
    Response schema for reading a user profile.

    Represents a profile record returned from the database.

    Fields:
    - id: User ID (matches Supabase auth user ID)
    - username: Unique username
    - onboarding_complete: Whether onboarding flow is finished
    - email: Unique email
    - native_language: Optional
    - full_name: Optional
    - learning_goal: Optional onboarding field
    - feedback_tone: Optional onboarding field
    - accent: Optional onboarding field
    - daily_pace: Optional onboarding field
    - skill_assess: Optional onboarding field

    Notes:
    - Many fields are nullable because onboarding is incremental.
    """
    id: str
    username: str
    email: str
    onboarding_complete: bool
    native_language: str | None = None
    full_name: str | None = None
    learning_goal: str | None = None
    feedback_tone: str | None = None
    accent: str | None = None
    daily_pace: str | None = None
    skill_assess: str | None = None
    focus_areas: str | None = None


class ProfileOnboardingUpdate(BaseModel):
    """
    Request schema for updating onboarding fields.

    Fields:
    - learning_goal: User's objective (e.g., fluency, pronunciation)
    - feedback_tone: Preferred feedback style
    - accent: Target accent
    - daily_pace: Desired learning pace
    - skill_assess: Initial skill assessment result
    - mark_complete: Whether onboarding should be marked complete

    Notes:
    - All fields are optional to support partial updates (PATCH semantics).
    - exclude_unset=True is typically used when applying updates.
    """
    learning_goal: str | None = None
    feedback_tone: str | None = None
    accent: str | None = None
    daily_pace: str | None = None
    skill_assess: str | None = None
    mark_complete: bool = False


class ProfileDetailsUpdate(BaseModel):
    full_name: str | None = None
    native_language: str | None = None
    learning_goal: str | None = None
    feedback_tone: str | None = None
    accent: str | None = None
    daily_pace: str | None = None
    focus_areas: str | None = None