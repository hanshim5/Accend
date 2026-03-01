"""
Supabase client factory.

Purpose:
- Create ONE Supabase client instance for this service process.
- Reuse it across requests instead of re-creating it each time.

Why:
- Creating the client repeatedly is wasted work.
- This is a simple "singleton" pattern scoped to this Python process.

Important:
- Uses SUPABASE_SERVICE_ROLE_KEY (server-only).
- Never expose this key to Flutter or public clients.
"""

from supabase import create_client, Client
from app.config import settings

# Module-level cache so we only create the client once per process.
_supabase: Client | None = None


def get_supabase() -> Client:
    """
    Returns a cached Supabase client.

    How it works:
    - First call: creates client using env vars, stores it in _supabase.
    - Later calls: returns the already-created client.

    This function is used by repositories (data access layer),
    NOT by routes directly (keeps our architecture clean).
    """
    global _supabase

    if _supabase is None:
        # Create a new Supabase client with service-role credentials.
        _supabase = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_ROLE_KEY,
        )

    return _supabase