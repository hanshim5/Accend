import httpx

from app.config import settings


class SupabaseClient:
    def __init__(self) -> None:
        self.base_url = settings.SUPABASE_URL.rstrip("/") + "/rest/v1"
        self.headers = {
            "apikey": settings.SUPABASE_SERVICE_ROLE_KEY,
            "Authorization": f"Bearer {settings.SUPABASE_SERVICE_ROLE_KEY}",
            "Content-Type": "application/json",
        }

    async def get(self, table: str, params: dict) -> list[dict]:
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
        url = f"{self.base_url}/{table}"

        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(url, headers=self.headers, json=json)

        if resp.status_code >= 400:
            raise httpx.HTTPStatusError(
                f"Supabase POST error {resp.status_code}",
                request=resp.request,
                response=resp,
            )

    async def delete(self, table: str, params: dict) -> None:
        url = f"{self.base_url}/{table}"

        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.delete(url, headers=self.headers, params=params)

        if resp.status_code >= 400:
            raise httpx.HTTPStatusError(
                f"Supabase DELETE error {resp.status_code}",
                request=resp.request,
                response=resp,
            )


supabase = SupabaseClient()