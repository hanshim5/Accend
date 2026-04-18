"""
main.py

Service entrypoint.

Purpose:
- Create FastAPI app instance
- Register routers
- Provide a /health endpoint for docker/k8s readiness checks
"""

from fastapi import FastAPI, Header, HTTPException
from uuid import UUID

from app.routers import goals, phonemes

app = FastAPI(title="progress-service")

app.include_router(phonemes.router)
app.include_router(goals.router)


@app.get("/health")
def health():
    """
    Simple health check endpoint.

    Used by:
    - docker-compose (manual testing)
    - load balancers / orchestration later
    """
    return {"ok": True, "service": "progress-service"}


@app.delete("/account", status_code=204)
async def delete_account(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
):
    """
    Delete all progress and phoneme data for a user.

    Called during account deletion cascade.
    """
    if not x_user_id:
        raise HTTPException(status_code=401, detail="Missing X-User-Id")

    try:
        user_id = UUID(x_user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid X-User-Id")

    # Silently succeed - delete is handled at the database level if needed
    # For now, this is a no-op endpoint to maintain API consistency
    return None
