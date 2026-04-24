"""
dependencies.py

FastAPI dependency provider.

Purpose:
- Central place to construct and inject our CourseService.
- Lets routers "Depends(get_course_service)" without manually wiring things.

Today:
- Always returns CourseService(repo=SupabaseCourseRepo())

Later:
- Could swap repo based on env (Supabase vs SQLAlchemy)
- Could add caching, testing mocks, etc.
"""

from app.repositories.supabase_private_lobby_repo import SupabasePrivateLobbyRepo
from app.repositories.supabase_public_lobby_repo import SupabasePublicLobbyRepo
from app.repositories.supabase_lobby_items_repo import SupabaseLobbyItemsRepo
from app.services.private_lobby_service import PrivateLobbyService
from app.services.public_lobby_service import PublicLobbyService


def get_private_lobby_service() -> PrivateLobbyService:
    return PrivateLobbyService(repo=SupabasePrivateLobbyRepo())


def get_public_lobby_service() -> PublicLobbyService:
    return PublicLobbyService(repo=SupabasePublicLobbyRepo())


def get_lobby_items_repo() -> SupabaseLobbyItemsRepo:
    return SupabaseLobbyItemsRepo()
