"""
API Gateway (BFF - Backend For Frontend)

Purpose:
- Single public entry point for mobile app.
- Validate authentication.
- Route requests to appropriate microservices.
- Aggregate or orchestrate multi-service flows.

Architecture:
Flutter → Gateway → Internal Services
"""

from fastapi import FastAPI, File, Form, Header, HTTPException, UploadFile
from pydantic import BaseModel, Field
import httpx

from app.config import settings
from app.auth import verify_supabase_jwt

from httpx import HTTPStatusError
from app.supabase_client import supabase_select_one

from fastapi.middleware.cors import CORSMiddleware


# Create FastAPI app
app = FastAPI(title="api-gateway")

# Allow cross-origin requests from your web/dev origins.
# settings.ALLOWED_ORIGINS should be a list of origins, e.g. ["http://localhost:5173"]
# If not set, we allow a sensible dev list (localhost + 127.0.0.1) — change this for production.

# DEV CORS: allow ANY localhost/127.0.0.1 port (flutter web port changes)
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
    Simple readiness check.
    Used by docker-compose and monitoring.
    """
    return {"ok": True, "service": "api-gateway"}

# -----------------------------------
# Proxy: GET /profile/username-available  (PUBLIC)
# -----------------------------------

@app.get("/profile/username-available")
async def proxy_username_available(username: str):
    """
    Forward username availability to user-profile-service.

    Public endpoint (pre-signup), so NO JWT required.
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
# Proxy: POST /profile/init  (PROTECTED)
# -----------------------------------

@app.post("/profile/init")
async def proxy_profile_init(
    body: dict,
    authorization: str | None = Header(default=None),
):
    """
    Initialize profile row after signup/login.
    Requires JWT (gateway validates), forwards X-User-Id.
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
    Forward GET /courses to courses-service.

    Steps:
    1. Validate JWT.
    2. Extract user_id.
    3. Call courses-service with X-User-Id header.
    4. Return response.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(
            f"{settings.COURSES_SERVICE_URL}/courses",
            headers={"X-User-Id": user_id},
        )

        return r.json()
    
# -----------------------------------
# AI Course Generation
# -----------------------------------

class GenerateReq(BaseModel):
    """
    Request schema for generating a course.
    """
    prompt: str = Field(min_length=1, max_length=5000)


@app.post("/ai/generate-course")
async def generate_course(
    req: GenerateReq,
    authorization: str | None = Header(default=None),
):
    """
    Orchestrated flow:

    1. Validate JWT (identify user).
    2. Call AI service to generate structure.
    3. Call courses-service to persist generated course.
    4. Return combined response to Flutter.

    This is orchestration logic.
    This is why Gateway exists.
    """

    # Step 1: Verify identity
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=30) as client:

        # Step 2: Call AI service
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

        # Step 3: Persist in courses-service
        course_resp = await client.post(
            f"{settings.COURSES_SERVICE_URL}/courses",
            headers={"X-User-Id": user_id},
            json={"title": ai_data["title"]},
        )

        if course_resp.status_code >= 400:
            raise HTTPException(
                status_code=course_resp.status_code,
                detail=course_resp.text,
            )

        # Step 4: Return aggregated response
        return {
            "course": course_resp.json(),
            "ai": ai_data,
        }


# -----------------------------------
# Pronunciation Feedback (proxy to pronunciation-feedback service)
# -----------------------------------


@app.post("/pronunciation/assess")
async def proxy_pronunciation_assess(
    audio: UploadFile = File(..., description="WAV audio file (max 10 seconds)"),
    reference_text: str = Form(..., description="Ground truth text the learner should say"),
    authorization: str | None = Header(default=None),
):
    """
    Forward pronunciation assessment to pronunciation-feedback service.

    Gateway: validate JWT (unless ALLOW_ANON_PRONUNCIATION_ASSESS is set for dev), forward multipart.
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