"""
Supabase REST client (PostgREST) factory.

Purpose:
- Provide a minimal, stable way to interact with Supabase Postgres via HTTP.
- Avoid SDK coupling (supabase-py) so sb_secret_* keys work reliably.

Why:
- Supabase's "new keys" (sb_secret_*) are not legacy JWT-style keys.
- Some SDK versions validate key format and reject these keys.
- Raw PostgREST HTTP is stable, explicit, and microservice-friendly.

Important:
- Uses SUPABASE_SERVICE_ROLE_KEY (server-only) even if its value is sb_secret_*.
- Never expose this key to Flutter or public clients.
"""

from __future__ import annotations

from typing import Any
import httpx
from app.config import settings

# Module-level cache so we only create the client once per process.
_http: httpx.Client | None = None


def _headers() -> dict[str, str]:
    """
    Headers required by Supabase PostgREST.

    Supabase expects:
    - apikey: <key>
    - Authorization: Bearer <key>

    Note:
    - This is the backend API key (service role / secret).
    - This is NOT the user's JWT.
    """
    key = settings.SUPABASE_SERVICE_ROLE_KEY
    return {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        # For inserts, this header requests the inserted row be returned.
        "Prefer": "return=representation",
    }


def get_http() -> httpx.Client:
    """
    Returns a cached HTTP client.

    How it works:
    - First call: creates a client and caches it in _http.
    - Later calls: returns the cached client.

    Used by repositories (data access layer), not by routers directly.
    """
    global _http

    if _http is None:
        _http = httpx.Client(timeout=10)

    return _http


def rest_get(table: str, params: dict[str, str]) -> list[dict[str, Any]]:
    """
    GET rows from a table via PostgREST.

    Example params:
      {
        "select": "id,user_id,title,created_at",
        "user_id": "eq.<uuid>",
        "order": "created_at.desc",
        "limit": "100",
      }
    """
    url = f"{settings.SUPABASE_URL}/rest/v1/{table}"
    client = get_http()

    resp = client.get(url, headers=_headers(), params=params)
    if resp.status_code >= 400:
        raise RuntimeError(f"Supabase REST GET failed ({resp.status_code}): {resp.text}")

    data = resp.json()
    return data if isinstance(data, list) else []


def rest_post(table: str, payload: dict[str, Any], select: str) -> dict[str, Any]:
    """
    INSERT a row via PostgREST and return the inserted row.

    PostgREST pattern:
    - POST /rest/v1/<table>
    - body: JSON object
    - Prefer: return=representation
    - select=<columns> query param to choose returned columns

    Returns a single inserted row dict.
    """
    url = f"{settings.SUPABASE_URL}/rest/v1/{table}"
    client = get_http()

    resp = client.post(url, headers=_headers(), params={"select": select}, json=payload)
    if resp.status_code >= 400:
        raise RuntimeError(f"Supabase REST POST failed ({resp.status_code}): {resp.text}")

    data = resp.json()
    # PostgREST returns a list of inserted rows
    if isinstance(data, list) and data:
        return data[0]

    raise RuntimeError("Supabase REST POST returned no row")