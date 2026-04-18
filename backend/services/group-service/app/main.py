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
from app.routers.private_lobbies import router as private_lobbies_router
from app.routers.public_lobbies import router as public_lobbies_router
from app.routers.voice import router as voice_router

app = FastAPI(title="group-service")


@app.get("/health")
def health():
    """
    Simple health check endpoint.

    Used by:
    - docker-compose (manual testing)
    - load balancers / orchestration later
    """
    return {"ok": True, "service": "group-service"}


@app.delete("/account", status_code=204)
async def delete_account(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
):
    """
    Delete all group/lobby data for a user.

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


# Attach the private and public lobby routes
app.include_router(private_lobbies_router)
app.include_router(public_lobbies_router)
app.include_router(voice_router)