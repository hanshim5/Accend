"""
Supabase Client (Gateway)

Purpose:
- Allow Gateway to query Supabase directly for lightweight checks
  (e.g., username availability).
- Uses SERVICE ROLE / SECRET key (server-side only).

Important:
- This bypasses RLS when using elevated keys.
- Gateway should only perform minimal DB reads directly.
- We intentionally use raw HTTP (PostgREST) instead of supabase-py SDK
  to avoid key-format validation differences and reduce coupling.
"""

from __future__ import annotations

from typing import Any
import httpx

from app.config import settings


def _supabase_headers() -> dict[str, str]:
    """
    Headers for calling Supabase REST (PostgREST).

    Supabase expects:
    - apikey: <key>
    - Authorization: Bearer <key>

    Note:
    - This is an API key (service role / secret), NOT the user's JWT.
    - Never send this header to clients.
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
    Minimal helper to query Supabase PostgREST.

    Example:
      await supabase_select_one(
          table="profiles",
          select="id",
          filters={"username": "eq.matthew"},
      )

    Returns:
      List of rows (0 or 1 if you pass limit=1).
    """
    url = f"{settings.SUPABASE_URL}/rest/v1/{table}"

    # Build query params. PostgREST uses "col=eq.value" style filters.
    params: dict[str, str] = {"select": select, "limit": "1"}
    params.update(filters)

    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(url, headers=_supabase_headers(), params=params)

    if resp.status_code >= 400:
        # Raise a helpful error up to the gateway layer.
        # (Don’t leak secrets; response body is safe-ish but keep it generic.)
        raise httpx.HTTPStatusError(
            f"Supabase REST error {resp.status_code}",
            request=resp.request,
            response=resp,
        )

    return resp.json()