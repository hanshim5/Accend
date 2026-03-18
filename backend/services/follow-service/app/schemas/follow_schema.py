from pydantic import BaseModel


class SocialUserOut(BaseModel):
    id: str
    display_name: str
    username: str
    level_label: str | None = None
    i_follow: bool
    follows_me: bool


class FollowWriteResponse(BaseModel):
    ok: bool