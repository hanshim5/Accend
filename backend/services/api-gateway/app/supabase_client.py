"""
supabase_client.py

Supabase Client (Gateway - Lightweight Reads)

Purpose:
- Provide minimal helper functions for the Gateway to query Supabase directly.
- Support lightweight, read-only checks (e.g., username existence).
- Avoid full service round-trips for simple lookups.

Architecture:
Gateway → (this client) → Supabase PostgREST → Database

Important Constraints:
- This bypasses RLS using the service role key.
- Gateway should ONLY perform minimal, read-only queries here.
- All writes and core business logic must go through the owning service.

Why raw HTTP (PostgREST):
- Avoid SDK coupling (supabase-py)
- Works cleanly with sb_secret_* keys
- Keeps behavior explicit and predictable

Security:
- Uses SUPABASE_SERVICE_ROLE_KEY (server-only)
- Never expose this key outside the backend
- Never forward these headers to clients
"""

from __future__ import annotations

from typing import Any
import httpx

from app.config import settings


def _supabase_headers() -> dict[str, str]:
    """
    Build headers required for Supabase PostgREST requests.

    Required:
    - apikey: Supabase service role key
    - Authorization: Bearer <same key>

    Notes:
    - This is NOT the user's JWT.
    - This key has elevated privileges (bypasses RLS).
    - Must never be exposed to frontend clients.
    """
    key = settings.SUPABASE_SERVICE_ROLE_KEY
    return {
        "apikey": key,
        "Authorization": f"Bearer {key}",
    }


async def supabase_select_one(
    table: str,
    select: str,
    filters: dict[str, str],
) -> list[dict[str, Any]]:
    """
    Query a single row (or small result set) from Supabase via PostgREST.

    Args:
    - table: Table name (e.g., "profiles")
    - select: Columns to retrieve (comma-separated string)
    - filters: PostgREST filter conditions (e.g., {"username": "eq.matthew"})

    Example:
      await supabase_select_one(
          table="profiles",
          select="id",
          filters={"username": "eq.matthew"},
      )

    Flow:
    1. Build request URL and query parameters.
    2. Send GET request to Supabase PostgREST.
    3. Raise error if request fails.
    4. Return JSON rows.

    Returns:
    - List of row dictionaries (0 or 1 row if limit=1 is used)

    Notes:
    - This helper enforces limit=1 by default for efficiency.
    - Intended for lightweight existence checks, not bulk queries.
    """

    url = f"{settings.SUPABASE_URL}/rest/v1/{table}"

    # Build query parameters.
    # PostgREST uses "column=eq.value" syntax for filters.
    params: dict[str, str] = {"select": select, "limit": "1"}
    params.update(filters)

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(url, headers=_supabase_headers(), params=params)

    if resp.status_code >= 400:
        # Raise controlled error to gateway layer.
        # Avoid leaking sensitive details while still surfacing failure.
        raise httpx.HTTPStatusError(
            f"Supabase REST error {resp.status_code}",
            request=resp.request,
            response=resp,
        )

    return resp.json()


async def supabase_auth_delete_user(user_id: str) -> None:
    """
    Delete a user from Supabase Auth.

    Args:
    - user_id: The UUID of the user to delete

    Flow:
    1. Call Supabase Auth Admin API to delete user.
    2. This removes the user from the auth_users table.
    3. Cascading deletes via database triggers should clean up related data.

    Notes:
    - This uses the service role key to bypass authentication.
    - User must already be deleted from all service tables before calling this.
    - This is the final step in account deletion.

    Raises:
    - httpx.HTTPStatusError if deletion fails
    """
    url = f"{settings.SUPABASE_URL}/auth/v1/admin/users/{user_id}"

    headers = _supabase_headers()
    headers["Content-Type"] = "application/json"

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.delete(url, headers=headers)

    if resp.status_code >= 400:
        raise httpx.HTTPStatusError(
            f"Supabase Auth delete error {resp.status_code}",
            request=resp.request,
            response=resp,
        )