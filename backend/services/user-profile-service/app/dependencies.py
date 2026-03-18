"""
dependencies.py

Dependency Injection Setup (Profile Service)

Purpose:
- Provide factory functions for creating service instances.
- Wire together service layer with repository implementations.
- Centralize dependency construction for FastAPI's Depends system.

Architecture:
Router → Depends(get_profile_service) → Service → Repository → Supabase

Why this exists:
- Keeps router code clean and focused on request handling.
- Makes it easy to swap implementations (e.g., mock repo for testing).
- Avoids hardcoding dependencies inside route handlers.

Design Notes:
- Each call currently creates a new repository + service instance.
- This is fine for stateless services in Sprint 1.
- Can later be optimized (e.g., singleton repos, connection pooling).
"""

from app.repositories.supabase_profile_repo import SupabaseProfileRepo
from app.services.profile_service import ProfileService


def get_profile_service() -> ProfileService:
    """
    Create and return a ProfileService instance.

    Flow:
    1. Instantiate repository (SupabaseProfileRepo).
    2. Inject it into ProfileService.
    3. Return the configured service.

    Used by:
    - FastAPI Depends() in router layer

    Example:
    svc: ProfileService = Depends(get_profile_service)
    """
    return ProfileService(repo=SupabaseProfileRepo())