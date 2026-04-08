from pydantic import BaseModel


class SocialUserOut(BaseModel):
    id: str
    display_name: str
    username: str
    level_label: str | None = None
    native_language: str | None = None
    learning_goal: str | None = None
    focus_areas: str | None = None
    current_streak: int = 0
    overall_accuracy: float = 0.0
    lessons_completed: int = 0
    i_follow: bool
    follows_me: bool


class FollowWriteResponse(BaseModel):
    ok: bool


class FollowCountsOut(BaseModel):
    followers: int
    following: int