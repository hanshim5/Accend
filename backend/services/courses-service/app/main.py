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
from app.routers.courses import router as courses_router
from app.routers.lessons import router as lessons_router
from app.dependencies import get_course_service

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


@app.delete("/account", status_code=204)
async def delete_account(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
):
    """
    Delete all courses and data for a user.

    Called during account deletion cascade.
    """
    if not x_user_id:
        raise HTTPException(status_code=401, detail="Missing X-User-Id")

    try:
        user_id = UUID(x_user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid X-User-Id")

    svc = get_course_service()
    try:
        svc.delete_account(user_id)
    except Exception:
        # Silently succeed even if delete fails
        pass

    return None


# Attach the /courses routes
app.include_router(courses_router)
app.include_router(lessons_router)