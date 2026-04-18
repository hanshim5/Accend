"""
supabase.py

Supabase REST Client (Async)

Purpose:
- Provide a minimal async HTTP client for interacting with Supabase PostgREST.
- Centralize all database communication for the user-profile-service.
- Avoid SDK dependencies and use direct HTTP for flexibility and reliability.

Architecture:
Repository Layer → (this client) → Supabase PostgREST → Database

Why this exists:
- Keeps repositories clean and focused on data logic.
- Avoids duplicating HTTP logic across the codebase.
- Works with SUPABASE_SERVICE_ROLE_KEY (including sb_secret_* keys).

Security:
- Uses SUPABASE_SERVICE_ROLE_KEY (backend-only, bypasses RLS).
- This key must NEVER be exposed to frontend clients.
- Safe because this service is only accessible via the API Gateway.

Design Notes:
- Uses httpx.AsyncClient for non-blocking I/O.
- Each method creates a short-lived client (simple + safe for now).
- Can be optimized later with connection pooling if needed.
"""

import httpx
from app.config import settings


class SupabaseClient:
    """
    Async client for interacting with Supabase PostgREST.

    Responsibilities:
    - Construct correct base URL and headers.
    - Provide helper methods for GET, POST, PATCH operations.
    - Handle HTTP errors consistently.

    Used by:
    - Repository layer only (never directly by routers/services).
    """

    def __init__(self) -> None:
        """
        Initialize base URL and headers for Supabase requests.

        Notes:
        - base_url points to the PostgREST endpoint (/rest/v1).
        - Headers include both apikey and Authorization as required by Supabase.
        """
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
        - table: Table name (e.g., "profiles")
        - params: PostgREST query parameters (filters, select, order, etc.)

        Flow:
        1. Build request URL.
        2. Send GET request with headers and params.
        3. Raise error if response is not successful.
        4. Return parsed JSON list.

        Returns:
        - List of row dictionaries
        """
        url = f"{self.base_url}/{table}"

        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(url, headers=self.headers, params=params)

        if resp.status_code >= 400:
            raise httpx.HTTPStatusError(
                f"Supabase GET error {resp.status_code}",
                request=resp.request,
                response=resp,
            )

        return resp.json()

    async def post(self, table: str, json: dict) -> None:
        """
        Insert a new row into a Supabase table.

        Args:
        - table: Table name
        - json: Payload representing the row to insert

        Notes:
        - Does not return inserted row (could be extended later).
        - For now, assumes insert success if no error is raised.
        """
        url = f"{self.base_url}/{table}"

        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(url, headers=self.headers, json=json)

        if resp.status_code >= 400:
            raise httpx.HTTPStatusError(
                f"Supabase POST error {resp.status_code}",
                request=resp.request,
                response=resp,
            )

    async def patch(self, table: str, json: dict, params: dict) -> None:
        """
        Update existing rows in a Supabase table.

        Args:
        - table: Table name
        - json: Fields to update
        - params: PostgREST filter conditions

        Example:
          await supabase.patch(
              "profiles",
              json={"learning_goal": "fluency"},
              params={"id": "eq.<user_id>"},
          )

        Flow:
        1. Build PATCH request with filters.
        2. Send request to Supabase.
        3. Raise error if update fails.

        Notes:
        - Partial updates only (fields not included remain unchanged).
        """
        url = f"{self.base_url}/{table}"

        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.patch(
                url,
                headers=self.headers,
                params=params,
                json=json,
            )

        if resp.status_code >= 400:
            raise httpx.HTTPStatusError(
                f"Supabase PATCH error {resp.status_code}",
                request=resp.request,
                response=resp,
            )

    async def delete(self, table: str, params: dict) -> None:
        """
        Delete rows from a Supabase table.

        Args:
        - table: Table name
        - params: PostgREST filter conditions (e.g., {"id": "eq.<user_id>"})

        Example:
          await supabase.delete(
              "profiles",
              params={"id": f"eq.{user_id}"},
          )

        Flow:
        1. Build DELETE request with filters.
        2. Send request to Supabase.
        3. Raise error if delete fails.

        Notes:
        - Uses params to specify which rows to delete (WHERE clause).
        - No response body is expected.
        """
        url = f"{self.base_url}/{table}"

        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.delete(
                url,
                headers=self.headers,
                params=params,
            )

        if resp.status_code >= 400:
            raise httpx.HTTPStatusError(
                f"Supabase DELETE error {resp.status_code}",
                request=resp.request,
                response=resp,
            )


# Singleton instance used across the service.
# Ensures consistent configuration and avoids repeated instantiation.
supabase = SupabaseClient()