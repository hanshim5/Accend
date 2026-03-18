"""
supabase.py

Supabase REST Client (PostgREST)

Purpose:
- Provide a minimal, stable interface for interacting with Supabase Postgres via HTTP.
- Avoid dependency on Supabase SDKs (e.g., supabase-py).
- Support modern Supabase keys (sb_secret_*) without validation issues.

Architecture:
Repository Layer → (this client) → Supabase PostgREST API → Database

Why not use the SDK:
- Supabase "new keys" (sb_secret_*) are not JWTs.
- Some SDKs assume JWT format and reject these keys.
- Direct HTTP calls are simpler, explicit, and microservice-friendly.

Security:
- Uses SUPABASE_SERVICE_ROLE_KEY (server-only).
- This key bypasses RLS and has full database access.
- NEVER expose this key to frontend clients (Flutter, web, etc).

Design Notes:
- Thin wrapper around HTTP calls (GET, POST, PATCH).
- Keeps logic simple and predictable.
- Returns raw JSON rows for repositories to validate into schemas.
"""

from __future__ import annotations

from typing import Any
import httpx
from app.config import settings

# Module-level cache so we only create one HTTP client per process.
# This avoids unnecessary connection overhead.
_http: httpx.Client | None = None


def _headers() -> dict[str, str]:
    """
    Build headers required by Supabase PostgREST.

    Required headers:
    - apikey: Supabase service role key
    - Authorization: Bearer <same key>

    Notes:
    - This is NOT the user's JWT.
    - This is a backend-only key with elevated privileges.
    - "Prefer: return=representation" ensures inserts/updates return rows.
    """
    key = settings.SUPABASE_SERVICE_ROLE_KEY
    return {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        # Ensures POST/PATCH return the affected rows
        "Prefer": "return=representation",
    }


def get_http() -> httpx.Client:
    """
    Return a cached HTTP client.

    Flow:
    - First call: create a new httpx.Client and cache it.
    - Subsequent calls: reuse the same client.

    Why:
    - Reusing a client improves performance (connection pooling).
    - Avoids recreating connections on every database call.

    Usage:
    - Used by repository layer only (not directly by routers/services).
    """
    global _http

    if _http is None:
        _http = httpx.Client(timeout=10)

    return _http


def rest_get(table: str, params: dict[str, str]) -> list[dict[str, Any]]:
    """
    Fetch rows from a table using PostgREST.

    Args:
    - table: Table name (e.g., "lessons")
    - params: Query parameters for filtering, selecting, ordering

    Example:
      {
        "select": "id,user_id,title,created_at",
        "user_id": "eq.<uuid>",
        "order": "created_at.desc",
        "limit": "100",
      }

    Returns:
    - List of row dictionaries (empty list if no results)

    Error Handling:
    - Raises RuntimeError if Supabase returns an error response.
    """
    url = f"{settings.SUPABASE_URL}/rest/v1/{table}"
    client = get_http()

    resp = client.get(url, headers=_headers(), params=params)
    if resp.status_code >= 400:
        raise RuntimeError(f"Supabase REST GET failed ({resp.status_code}): {resp.text}")

    data = resp.json()
    return data if isinstance(data, list) else []


def rest_post(table: str, payload: dict[str, Any] | list[dict[str, Any]], select: str) -> list[dict[str, Any]]:
    """
    Insert one or multiple rows into a table.

    Args:
    - table: Table name
    - payload:
        - dict → insert single row
        - list[dict] → bulk insert
    - select: Columns to return after insert

    Returns:
    - List of inserted row dictionaries (length 1 for single insert)

    Notes:
    - Uses "Prefer: return=representation" to return inserted rows.
    - Bulk inserts are more efficient than multiple single inserts.
    """
    url = f"{settings.SUPABASE_URL}/rest/v1/{table}"
    client = get_http()

    resp = client.post(url, headers=_headers(), params={"select": select}, json=payload)
    if resp.status_code >= 400:
        raise RuntimeError(f"Supabase REST POST failed ({resp.status_code}): {resp.text}")

    data = resp.json()
    return data if isinstance(data, list) else []


def rest_patch(table: str, match: dict[str, str], payload: dict[str, Any], select: str) -> list[dict[str, Any]]:
    """
    Update rows in a table and return updated rows.

    Args:
    - table: Table name
    - match: Filtering conditions (PostgREST format)
        Example: {"id": "eq.<uuid>"}
    - payload: Fields to update
    - select: Columns to return

    Flow:
    - Applies filters via query params.
    - Sends PATCH request with updated fields.
    - Returns updated rows.

    Returns:
    - List of updated row dictionaries

    Error Handling:
    - Raises RuntimeError on failure response.
    """
    url = f"{settings.SUPABASE_URL}/rest/v1/{table}"
    client = get_http()

    params = {"select": select, **match}
    resp = client.patch(url, headers=_headers(), params=params, json=payload)
    if resp.status_code >= 400:
        raise RuntimeError(f"Supabase REST PATCH failed ({resp.status_code}): {resp.text}")

    data = resp.json()
    return data if isinstance(data, list) else []