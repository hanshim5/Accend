from app.repositories.supabase_follow_repo import SupabaseFollowRepo
from app.services.follow_service import FollowService


def get_follow_service() -> FollowService:
    return FollowService(repo=SupabaseFollowRepo())