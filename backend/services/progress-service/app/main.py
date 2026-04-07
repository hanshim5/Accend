"""
main.py

Service entrypoint.

Purpose:
- Create FastAPI app instance
- Register routers
- Provide a /health endpoint for docker/k8s readiness checks
"""

from fastapi import FastAPI

from app.routers import phonemes

app = FastAPI(title="progress-service")

app.include_router(phonemes.router)


@app.get("/health")
def health():
    """
    Simple health check endpoint.

    Used by:
    - docker-compose (manual testing)
    - load balancers / orchestration later
    """
    return {"ok": True, "service": "progress-service"}
