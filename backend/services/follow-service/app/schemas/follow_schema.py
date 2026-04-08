from pydantic import BaseModel


class SocialUserOut(BaseModel):
    id: str
    display_name: str
    username: str
    level_label: str | None = None
    native_language: str | None = None
    learning_goal: str | None = None
    focus_areas: str | None = None
    i_follow: bool
    follows_me: bool


class FollowWriteResponse(BaseModel):
    ok: bool


class FollowCountsOut(BaseModel):
    followers: int
    following: int