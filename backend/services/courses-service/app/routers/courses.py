"""
courses.py

Courses Router (API Layer)

Purpose:
- Define HTTP endpoints for the courses service.
- Handle request parsing, basic validation, and response serialization.
- Extract authenticated user identity from the X-User-Id header set by the Gateway.
- Delegate all business logic to the CourseService.

Architecture:
Client (Flutter) → Gateway → Courses Service (this router) → Service → Repository → Supabase

Architecture Rules:
- Routers should NOT talk directly to the database.
- Routers should NOT contain business logic.
- Routers should NOT validate JWTs (the Gateway handles that).

This file only:
- Extracts inputs (headers, path params, request body)
- Performs lightweight validation
- Calls the service layer
- Returns typed API responses
"""

from fastapi import APIRouter, Depends, Header, HTTPException
from uuid import UUID

from app.dependencies import get_course_service
from app.schemas.course_schema import CourseCreate, CourseOut
from app.services.course_service import CourseService


# Router is mounted with prefix="/courses".
# Endpoints defined here resolve to:
# - GET  /courses
# - POST /courses
router = APIRouter(prefix="/courses", tags=["courses"])


def _get_user_id(x_user_id: str | None) -> UUID:
    """
    Extract and validate the X-User-Id header.

    Why:
    - We use gateway-validated authentication.
    - The Gateway verifies the user's JWT.
    - The Gateway then forwards the authenticated user's UUID in X-User-Id.
    - This service trusts that header because it is intended for internal use.

    Flow:
    1. Ensure the header is present.
    2. Ensure the header contains a valid UUID string.
    3. Return a UUID object for strong typing in downstream code.

    Raises:
    - 401 if the header is missing
    - 400 if the header value is not a valid UUID
    """

    if not x_user_id:
        # If the gateway did not forward a user id, treat the request as unauthorized.
        raise HTTPException(status_code=401, detail="Missing X-User-Id")

    try:
        return UUID(x_user_id)
    except Exception:
        # If the header value cannot be parsed as a UUID.
        raise HTTPException(status_code=400, detail="Invalid X-User-Id")


@router.get("", response_model=list[CourseOut])
def list_courses(
    # FastAPI extracts the X-User-Id header and injects it here.
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),

    # Dependency injection:
    # FastAPI calls get_course_service() and provides the resulting service instance.
    svc: CourseService = Depends(get_course_service),
):
    """
    Return all courses belonging to the authenticated user.

    Endpoint:
    - GET /courses

    Flow:
    1. Extract and validate user_id from X-User-Id header.
    2. Call the service layer.
    3. The service delegates to the repository.
    4. The repository fetches data from Supabase.
    5. Return a typed list of CourseOut objects.

    response_model ensures:
    - Output matches the CourseOut schema
    - UUID and datetime fields are serialized correctly
    """

    user_id = _get_user_id(x_user_id)
    return svc.list_courses(user_id)


@router.post("", response_model=CourseOut)
def create_course(
    # Request body is automatically parsed and validated as CourseCreate.
    body: CourseCreate,

    # Authenticated user identity forwarded by the Gateway.
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),

    # Inject the service layer.
    svc: CourseService = Depends(get_course_service),
):
    """
    Create a new course for the authenticated user.

    Endpoint:
    - POST /courses

    Example request body:
    {
        "title": "Travel phrases for restaurants"
    }

    Flow:
    1. FastAPI validates the request body using CourseCreate.
    2. Extract and validate user_id from X-User-Id header.
    3. Call the service layer.
    4. The service delegates to the repository.
    5. The repository inserts the course into Supabase.
    6. Return the created course as CourseOut.

    response_model ensures:
    - Returned data matches the CourseOut schema
    - Response types are validated before being sent
    """

    user_id = _get_user_id(x_user_id)
    return svc.create_course(user_id, body)