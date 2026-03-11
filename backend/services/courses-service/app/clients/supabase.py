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


from typing import Any

def rest_post(table: str, payload: dict[str, Any] | list[dict[str, Any]], select: str) -> list[dict[str, Any]]:
    """
    INSERT one or many rows via PostgREST and return inserted rows.

    If payload is a dict -> inserts 1 row
    If payload is a list of dicts -> bulk insert

    Returns a list of inserted row dicts (possibly length 1).
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
    PATCH rows via PostgREST and return updated rows.

    match example:
      {"id": "eq.<uuid>"}
    """
    url = f"{settings.SUPABASE_URL}/rest/v1/{table}"
    client = get_http()

    params = {"select": select, **match}
    resp = client.patch(url, headers=_headers(), params=params, json=payload)
    if resp.status_code >= 400:
        raise RuntimeError(f"Supabase REST PATCH failed ({resp.status_code}): {resp.text}")

    data = resp.json()
    return data if isinstance(data, list) else []
