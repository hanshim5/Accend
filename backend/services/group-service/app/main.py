"""
main.py

Service entrypoint.

Purpose:
- Create FastAPI app instance
- Register routers
- Provide a /health endpoint for docker/k8s readiness checks
"""

from fastapi import FastAPI
from app.routers.courses import router as courses_router
from app.routers.lessons import router as lessons_router

app = FastAPI(title="courses-service")


@app.get("/health")
def health():
    """
    Simple health check endpoint.

    Used by:
    - docker-compose (manual testing)
    - load balancers / orchestration later
    """
    return {"ok": True, "service": "courses-service"}


# Attach the /courses routes
app.include_router(courses_router)
app.include_router(lessons_router)