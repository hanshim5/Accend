"""
main.py

Service entrypoint.

Purpose:
- Create FastAPI app instance
- Register routers
- Provide a /health endpoint for docker/k8s readiness checks
"""

from fastapi import FastAPI
from app.routers.private_lobbies import router as private_lobbies_router
from app.routers.public_lobbies import router as public_lobbies_router

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


# Attach the /courses routes
app.include_router(private_lobbies_router)
app.include_router(public_lobbies_router)