"""
supabase.py

Supabase REST Client (Async)

Purpose:
- Provide a minimal async HTTP client for interacting with Supabase PostgREST.
- Centralize all database communication for the progress-service.
- Avoid SDK dependencies and use direct HTTP for flexibility and reliability.

Architecture:
Repository Layer → (this client) → Supabase PostgREST → Database

Security:
- Uses SUPABASE_SERVICE_ROLE_KEY (backend-only, bypasses RLS).
- This key must NEVER be exposed to frontend clients.
- Safe because this service is only accessible via the API Gateway.
"""

import httpx
from app.config import settings


class SupabaseClient:
    """
    Async client for interacting with Supabase PostgREST.

    Responsibilities:
    - Construct correct base URL and headers.
    - Provide helper methods for GET, POST, and upsert operations.
    - Handle HTTP errors consistently.

    Used by:
    - Repository layer only (never directly by routers/services).
    """

    def __init__(self) -> None:
        self.base_url = settings.SUPABASE_URL.rstrip("/") + "/rest/v1"
        self.headers = {
            "apikey": settings.SUPABASE_SERVICE_ROLE_KEY,
            "Authorization": f"Bearer {settings.SUPABASE_SERVICE_ROLE_KEY}",
            "Content-Type": "application/json",
        }

    async def get(self, table: str, params: dict) -> list[dict]:
        """
        Fetch rows from a Supabase table.

        Args:
        - table: Table name
        - params: PostgREST query parameters (filters, select, order, etc.)

        Returns:
        - List of row dictionaries
        """
        url = f"{self.base_url}/{table}"

        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(url, headers=self.headers, params=params)

        if resp.status_code >= 400:
            raise httpx.HTTPStatusError(
                f"Supabase GET error {resp.status_code}: {resp.text}",
                request=resp.request,
                response=resp,
            )

        return resp.json()

    async def upsert(self, table: str, rows: list[dict]) -> None:
        """
        Upsert rows into a Supabase table.

        Uses Prefer: resolution=merge-duplicates so existing rows are updated
        rather than returning a conflict error.

        Args:
        - table: Table name
        - rows: List of row dicts to insert/update

        Notes:
        - The table must have a UNIQUE constraint on the conflict columns.
        - Caller is responsible for pre-computing the correct values to write
          (e.g., weighted average scores) before calling this method.
        """
        url = f"{self.base_url}/{table}"
        headers = {
            **self.headers,
            "Prefer": "resolution=merge-duplicates",
        }

        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(url, headers=headers, json=rows)

        if resp.status_code >= 400:
            raise httpx.HTTPStatusError(
                f"Supabase upsert error {resp.status_code}: {resp.text}",
                request=resp.request,
                response=resp,
            )


# Singleton instance used across the service.
supabase = SupabaseClient()
