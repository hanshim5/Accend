"""
main.py

API Gateway (BFF - Backend For Frontend)

Purpose:
- Serve as the single public entry point for the mobile app.
- Validate authentication once at the edge.
- Route requests to the correct internal microservice.
- Orchestrate multi-service workflows when one client action requires multiple backend calls.

Architecture:
Flutter → Gateway → Internal Services → Supabase

Gateway Responsibilities:
- Verify Supabase JWTs
- Forward authenticated identity via X-User-Id
- Proxy requests to internal services
- Aggregate responses for frontend-friendly flows
- Support one-request-per-screen BFF patterns

Notes:
- Internal services are not meant to be called directly by Flutter.
- In Sprint 1, auth is centralized here and downstream services trust the gateway.
"""

from fastapi import FastAPI, File, Form, Header, HTTPException, UploadFile
from pydantic import BaseModel, Field
import httpx

from app.config import settings
from app.auth import verify_supabase_jwt

from httpx import HTTPStatusError
from app.supabase_client import supabase_select_one

from fastapi.middleware.cors import CORSMiddleware


# Create FastAPI application instance.
app = FastAPI(title="api-gateway")

# CORS configuration for local development.
# Allows requests from localhost / 127.0.0.1 on any port so Flutter web/dev
# can reach the gateway even when the dev server port changes.
# This should be tightened for production deployments.
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# -----------------------------------
# Health Check
# -----------------------------------

@app.get("/health")
def health():
    """
    Basic readiness/health endpoint.

    Used for:
    - Docker Compose health checks
    - Local smoke testing
    - Monitoring / uptime checks
    """
    return {"ok": True, "service": "api-gateway"}


# -----------------------------------
# Proxy: GET /profile/username-available (PUBLIC)
# -----------------------------------

@app.get("/profile/username-available")
async def proxy_username_available(username: str):
    """
    Forward username availability checks to user-profile-service.

    Public endpoint:
    - No JWT required because this is needed before signup/profile init.

    Flow:
    1. Validate and normalize username query parameter.
    2. Call user-profile-service.
    3. Return the downstream JSON response.
    """
    u = username.strip()
    if not u:
        raise HTTPException(status_code=400, detail="username required")

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.get(
            f"{settings.USER_PROFILE_SERVICE_URL}/username-available",
            params={"username": u},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


# -----------------------------------
# Proxy: GET /profile (PROTECTED)
# -----------------------------------

@app.get("/profile")
async def proxy_profile_get(
    authorization: str | None = Header(default=None),
):
    """
    Fetch the authenticated user's profile.

    Flow:
    1. Validate JWT and extract user_id.
    2. Forward request to user-profile-service with X-User-Id.
    3. Return profile JSON.

    Used for:
    - Onboarding resume logic
    - Profile screen data
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.get(
            f"{settings.USER_PROFILE_SERVICE_URL}/profiles/me",
            headers={"X-User-Id": user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


# -----------------------------------
# Proxy: POST /profile/init (PROTECTED)
# -----------------------------------

@app.post("/profile/init")
async def proxy_profile_init(
    body: dict,
    authorization: str | None = Header(default=None),
):
    """
    Initialize a profile row for the authenticated user.

    Flow:
    1. Validate JWT and extract user_id.
    2. Forward request body to user-profile-service.
    3. Include X-User-Id header for identity.
    4. Return downstream response.

    Typical usage:
    - Called after first signup/login when profile data is collected.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(
            f"{settings.USER_PROFILE_SERVICE_URL}/profiles/init",
            headers={"X-User-Id": user_id},
            json=body,
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


# -----------------------------------
# Proxy: GET /courses
# -----------------------------------

@app.get("/courses")
async def proxy_list_courses(
    authorization: str | None = Header(default=None)
):
    """
    Forward course list request to courses-service.

    Flow:
    1. Validate JWT.
    2. Extract authenticated user_id.
    3. Forward request with X-User-Id header.
    4. Return courses JSON.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(
            f"{settings.COURSES_SERVICE_URL}/courses",
            headers={"X-User-Id": user_id},
        )
        if r.status_code >= 400:
            raise HTTPException(status_code=r.status_code, detail=r.text)

        return r.json()


# -----------------------------------
# Proxy: GET /courses/{course_id}/lessons
# -----------------------------------

@app.get("/courses/{course_id}/lessons")
async def proxy_list_lessons(
    course_id: str,
    authorization: str | None = Header(default=None),
):
    """
    Fetch full curriculum (lessons + items) for a course.

    Flow:
    1. Validate JWT.
    2. Forward request to courses-service with X-User-Id.
    3. Return lesson data.

    Notes:
    - course_id is treated as a path parameter and passed through unchanged.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(
            f"{settings.COURSES_SERVICE_URL}/courses/{course_id}/lessons",
            headers={"X-User-Id": user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


# -----------------------------------
# Proxy: POST /courses/{course_id}/lessons/{lesson_id}/complete
# -----------------------------------

@app.post("/courses/{course_id}/lessons/{lesson_id}/complete")
async def proxy_complete_lesson(
    course_id: str,
    lesson_id: str,
    authorization: str | None = Header(default=None),
):
    """
    Mark a lesson complete through courses-service.

    Flow:
    1. Validate JWT.
    2. Forward completion request with X-User-Id.
    3. Return updated lesson data.

    Side Effect:
    - Downstream service recomputes and updates cached course progress/status.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.post(
            f"{settings.COURSES_SERVICE_URL}/courses/{course_id}/lessons/{lesson_id}/complete",
            headers={"X-User-Id": user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


# -----------------------------------
# AI Course Generation
# -----------------------------------

class GenerateReq(BaseModel):
    """
    Request schema for gateway-side AI course generation.

    Fields:
    - prompt: Free-text description of what the user wants to learn
    """
    prompt: str = Field(min_length=1, max_length=5000)


@app.post("/ai/generate-course")
async def generate_course(
    req: GenerateReq,
    authorization: str | None = Header(default=None),
):
    """
    Orchestrated AI → persistence flow.

    Flow:
    1. Validate JWT and extract user_id.
    2. Call AI service to generate course structure.
    3. Create a course row in courses-service.
    4. Normalize and persist generated curriculum in courses-service.
    5. Return aggregated response containing:
       - created course row
       - persisted lessons
       - raw AI output

    Why this belongs in the Gateway:
    - This is a cross-service workflow.
    - AI service generates structure but does not own course tables.
    - Courses service owns persistence.
    - Gateway orchestrates the two while presenting a single API call to Flutter.
    """
    # Step 1: Verify identity
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=30) as client:
        # Step 2: Ask AI service to generate structured course content.
        ai_resp = await client.post(
            f"{settings.AI_COURSE_GEN_SERVICE_URL}/generate-course",
            json={"prompt": req.prompt},
        )

        if ai_resp.status_code >= 400:
            raise HTTPException(
                status_code=ai_resp.status_code,
                detail=ai_resp.text,
            )

        ai_data = ai_resp.json()

        # Minimal gateway-side validation before persistence.
        # The AI service should return a title plus lessons, but the gateway
        # defensively checks and normalizes before writing anything.
        if "title" not in ai_data:
            raise HTTPException(status_code=502, detail="AI service returned no title")

        # Step 3: Create the parent course row first.
        course_resp = await client.post(
            f"{settings.COURSES_SERVICE_URL}/courses",
            headers={"X-User-Id": user_id},
            json={"title": ai_data.get("title", "Untitled Course")},
        )

        if course_resp.status_code >= 400:
            raise HTTPException(
                status_code=course_resp.status_code,
                detail=course_resp.text,
            )

        course_row = course_resp.json()
        course_id = course_row.get("id")
        if not course_id:
            raise HTTPException(status_code=502, detail="Courses service returned no id")

        # Step 4: Normalize AI lesson output into the curriculum payload expected
        # by courses-service.
        curriculum_payload = {"lessons": []}

        # Support both current and legacy shapes:
        # - ai_data["lessons"]
        # - ai_data["outline"]
        raw_lessons = ai_data.get("lessons") or ai_data.get("outline") or []
        for raw_l in raw_lessons:
            # Accept either:
            # - a plain string lesson title
            # - a dict with title/items fields
            if isinstance(raw_l, str):
                lesson_title = raw_l
                lesson_items = []
            elif isinstance(raw_l, dict):
                lesson_title = raw_l.get("title") or raw_l.get("lesson_title") or "Untitled lesson"
                lesson_items = raw_l.get("items") or raw_l.get("phrases") or []
            else:
                continue

            # Normalize item shape.
            # Accept either:
            # - list[str]
            # - list[dict{text, ipa, hint}]
            normalized_items = []
            for it in lesson_items:
                if isinstance(it, str):
                    normalized_items.append({"text": it})
                elif isinstance(it, dict) and it.get("text"):
                    normalized_items.append({
                        "text": it["text"],
                        "ipa": it.get("ipa"),
                        "hint": it.get("hint"),
                    })

            # Skip empty lessons so courses-service does not receive invalid
            # curriculum data with no items.
            if not normalized_items:
                continue

            curriculum_payload["lessons"].append({
                "title": lesson_title,
                "items": normalized_items,
            })

        # Persist the curriculum only if there is at least one valid lesson.
        if curriculum_payload["lessons"]:
            curriculum_resp = await client.post(
                f"{settings.COURSES_SERVICE_URL}/courses/{course_id}/curriculum",
                headers={"X-User-Id": user_id},
                json=curriculum_payload,
            )

            if curriculum_resp.status_code >= 400:
                # Surface helpful context for debugging multi-service failures.
                raise HTTPException(
                    status_code=curriculum_resp.status_code,
                    detail={"courses_error": curriculum_resp.text, "ai_preview": ai_data},
                )

            curriculum_rows = curriculum_resp.json()
        else:
            curriculum_rows = []

        # Step 5: Return aggregated response for frontend use.
        return {
            "course": course_row,
            "lessons": curriculum_rows,
            "ai": ai_data,
        }


# -----------------------------------
# Pronunciation Feedback
# -----------------------------------

@app.post("/pronunciation/assess")
async def proxy_pronunciation_assess(
    audio: UploadFile = File(..., description="WAV audio file (max 10 seconds)"),
    reference_text: str = Form(..., description="Ground truth text the learner should say"),
    authorization: str | None = Header(default=None),
):
    """
    Proxy pronunciation assessment to pronunciation-feedback service.

    Auth Behavior:
    - By default, JWT is required.
    - In local/dev, auth can be skipped if ALLOW_ANON_PRONUNCIATION_ASSESS is enabled.

    Flow:
    1. Optionally verify JWT.
    2. Read uploaded audio file.
    3. Forward multipart request to pronunciation service.
    4. Return JSON assessment response.
    """
    if not getattr(settings, "ALLOW_ANON_PRONUNCIATION_ASSESS", False):
        verify_supabase_jwt(authorization)

    content = await audio.read()
    filename = audio.filename or "audio.wav"

    async with httpx.AsyncClient(timeout=30) as client:
        r = await client.post(
            f"{settings.PRONUNCIATION_FEEDBACK_SERVICE_URL}/assess",
            files={"audio": (filename, content, "audio/wav")},
            data={"reference_text": reference_text},
        )

    if r.status_code >= 400:
        try:
            detail = r.json()
        except Exception:
            detail = r.text
        raise HTTPException(status_code=r.status_code, detail=detail)

    return r.json()


# -----------------------------------
# Group Session Service
# -----------------------------------

@app.get("/private_lobbies")
async def proxy_get_private_lobby(
    authorization: str | None = Header(default=None)
):
    """
    Fetch private lobby data from group-service.

    Flow:
    1. Validate JWT.
    2. Forward request with X-User-Id header.
    3. Return downstream JSON response.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(
            f"{settings.GROUP_SERVICE_URL}/private_lobby",
            headers={"X-User-Id": user_id},
        )
        if r.status_code >= 400:
            raise HTTPException(status_code=r.status_code, detail=r.text)

        return r.json()


# -----------------------------------
# Proxy: PATCH /profile/onboarding
# -----------------------------------

@app.patch("/profile/onboarding")
async def proxy_profile_onboarding(
    body: dict,
    authorization: str | None = Header(default=None),
):
    """
    Update onboarding-related profile fields.

    Flow:
    1. Validate JWT and extract user_id.
    2. Forward PATCH body to user-profile-service.
    3. Include X-User-Id header.
    4. Return downstream response.

    Used for:
    - Multi-step onboarding state updates
    - Marking onboarding complete
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.patch(
            f"{settings.USER_PROFILE_SERVICE_URL}/profiles/onboarding",
            headers={"X-User-Id": user_id},
            json=body,
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()