"""
supabase.py

Minimal Supabase REST Client (read-only)

Purpose:
- Allow this service to fetch rows from Supabase PostgREST over HTTP.
- Used exclusively to read user_phoneme_metrics for course generation.
- Uses the service role key to bypass RLS (server-only key).

Architecture:
Service layer → (this client) → Supabase PostgREST API → Database

Why not use the Supabase SDK:
- Supabase "new keys" (sb_secret_*) are not JWTs and may be rejected by some SDK versions.
- Direct HTTP calls are simpler, explicit, and consistent with other services in this project.

Security:
- SUPABASE_SERVICE_ROLE_KEY is backend-only and bypasses RLS.
- This service is internal and only reachable through the API Gateway.
- Never expose this key or this client to frontend clients.
"""

from __future__ import annotations

from typing import Any
import httpx

from app.config import settings


# Module-level cache so only one HTTP client is created per process.
_http: httpx.Client | None = None


def _require_config() -> tuple[str, str]:
    """
    Validate that required Supabase environment variables are present.

    Called at request time (not startup) so the service can start without
    Supabase credentials when only the non-Supabase endpoints are used.

    Returns:
    - (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY) tuple

    Raises:
    - RuntimeError if either variable is missing.
    """
    url = settings.SUPABASE_URL
    key = settings.SUPABASE_SERVICE_ROLE_KEY

    if not url:
        raise RuntimeError("SUPABASE_URL is not set")
    if not key:
        raise RuntimeError("SUPABASE_SERVICE_ROLE_KEY is not set")

    return url, key


def _headers(key: str) -> dict[str, str]:
    """
    Build Supabase PostgREST request headers.

    Notes:
    - apikey and Authorization must both carry the service role key.
    - "Prefer: return=representation" is included for consistency but
      not required for GET requests.
    """
    return {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Prefer": "return=representation",
    }


def get_http() -> httpx.Client:
    """
    Return a cached httpx.Client.

    Reusing the client improves performance via connection pooling and
    avoids creating new TCP connections on every database call.
    """
    global _http

    if _http is None:
        _http = httpx.Client(timeout=10)

    return _http


def rest_get(table: str, params: dict[str, str]) -> list[dict[str, Any]]:
    """
    Fetch rows from a Supabase table using PostgREST.

    Args:
    - table: Table name (e.g., "user_phoneme_metrics")
    - params: Query parameters for filtering, selecting, and ordering.

    Example:
      rest_get(
          "user_phoneme_metrics",
          {
              "select": "phoneme,current_avg_accuracy,total_attempts",
              "user_id": "eq.<uuid>",
              "order": "current_avg_accuracy.asc",
          }
      )

    Returns:
    - List of row dicts (empty list if no results).

    Raises:
    - RuntimeError if Supabase is not configured or the request fails.
    """
    url_base, key = _require_config()
    url = f"{url_base}/rest/v1/{table}"
    client = get_http()

    resp = client.get(url, headers=_headers(key), params=params)
    if resp.status_code >= 400:
        raise RuntimeError(
            f"Supabase REST GET failed ({resp.status_code}): {resp.text}"
        )

    data = resp.json()
    return data if isinstance(data, list) else []
