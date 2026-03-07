from app.repositories.supabase_profile_repo import SupabaseProfileRepo
from app.services.profile_service import ProfileService

def get_profile_service() -> ProfileService:
    return ProfileService(repo=SupabaseProfileRepo())