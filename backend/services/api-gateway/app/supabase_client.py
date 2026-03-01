"""
Supabase Client (Gateway)

Purpose:
- Allow Gateway to query Supabase directly for lightweight checks
  (e.g., username availability).
- Uses SERVICE ROLE key (server-side only).

Important:
- This bypasses RLS.
- Gateway should only perform minimal DB reads directly.
"""

from supabase import create_client, Client
from app.config import settings

_sb: Client | None = None


def supabase() -> Client:
    """
    Return a cached Supabase client.

    Singleton pattern:
    - Create once
    - Reuse across requests
    """
    global _sb

    if _sb is None:
        _sb = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_ROLE_KEY,
        )

    return _sb