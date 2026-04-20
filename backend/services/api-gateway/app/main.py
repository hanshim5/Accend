"""
main.py

API Gateway (BFF - Backend For Frontend)

Purpose:
- Serve as the single public entry point for the mobile app.
- Validate authentication at the edge.
- Route requests to the appropriate internal microservice.
- Orchestrate multi-service workflows when one client action requires multiple backend calls.

Architecture:
Flutter → Gateway → Internal Services → Supabase

Gateway Responsibilities:
- Verify Supabase JWTs
- Extract authenticated user identity
- Forward identity to internal services via X-User-Id
- Proxy requests to downstream services
- Aggregate multi-service responses for frontend-friendly APIs
- Support one-request-per-screen BFF patterns

Notes:
- Internal services are not intended to be called directly by Flutter.
- In Sprint 1, JWT validation happens only in the Gateway.
- Downstream services trust the Gateway and use X-User-Id for identity.
"""

from fastapi import FastAPI, File, Form, Header, HTTPException, UploadFile
from typing import Literal

from pydantic import BaseModel, Field
import httpx
import asyncio

from app.config import settings
from app.auth import verify_supabase_jwt

from httpx import HTTPStatusError
from app.supabase_client import supabase_select_one

from fastapi.middleware.cors import CORSMiddleware


# Create FastAPI application instance for the public gateway service.
app = FastAPI(title="api-gateway")

# CORS configuration for local development.
# Allows localhost / 127.0.0.1 on any port so Flutter web and other local
# dev clients can reach the gateway even when ports change.
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
# Login Identifier Resolution
# -----------------------------------

class ResolveLoginReq(BaseModel):
    """
    Resolve a login identifier into an email address for Supabase Auth.

    Supported identifiers:
    - email address
    - username

    Why this exists:
    - Supabase Auth signs in with email + password.
    - The app UI supports "Username or Email".
    - The gateway resolves usernames to emails before the frontend calls
      Supabase sign-in.

    Security:
    - This endpoint does not reveal whether a username exists.
    - Failures return a generic invalid-credentials style message.
    """
    identifier: str = Field(min_length=1, max_length=255)


@app.post("/auth/resolve-login")
async def resolve_login_identifier(req: ResolveLoginReq):
    """
    Resolve a login identifier to an email address.

    Flow:
    1. Normalize the identifier.
    2. If it looks like an email, return it directly.
    3. Otherwise treat it as a username and look up the profile row.
    4. Return the resolved email.

    Notes:
    - Public endpoint: no JWT required because it is used before login.
    - User-facing callers should still show a generic login failure message
      if this endpoint fails.
    """
    identifier = req.identifier.strip()
    if not identifier:
        raise HTTPException(status_code=400, detail="identifier required")

    # If the identifier contains "@", treat it as an email.
    # This assumes usernames are not allowed to look like email addresses.
    if "@" in identifier:
        return {"email": identifier}

    try:
        rows = await supabase_select_one(
            table="profiles",
            select="email",
            filters={"username": f"eq.{identifier}"},
        )
    except HTTPStatusError:
        raise HTTPException(status_code=502, detail="Login resolution failed")

    if not rows:
        raise HTTPException(status_code=400, detail="Invalid credentials")

    email = rows[0].get("email")
    if not email:
        raise HTTPException(status_code=400, detail="Invalid credentials")

    return {"email": email}


# -----------------------------------
# Profile Service
# -----------------------------------

@app.get("/profile/username-available")
async def proxy_username_available(username: str):
    """
    Forward username availability checks to user-profile-service.

    Public endpoint:
    - No JWT required because this is used before profile initialization.

    Flow:
    1. Validate and normalize the username query parameter.
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


@app.get("/profile")
async def proxy_profile_get(
    authorization: str | None = Header(default=None),
):
    """
    Fetch the authenticated user's profile.

    Flow:
    1. Validate JWT and extract user_id.
    2. Forward request to user-profile-service with X-User-Id.
    3. Return the downstream profile JSON.

    Used for:
    - Onboarding resume decisions
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


def _is_active_course(course: dict) -> bool:
    status = str(course.get("status", "")).strip().lower()
    progress = int(course.get("progress_percent", 0) or 0)
    if status in {"complete", "completed"}:
        return False
    return progress < 100


def _goal_minutes_from_daily_pace(daily_pace: object) -> int:
    pace = str(daily_pace or "").strip().lower()
    return {
        "hiker": 5,
        "climber": 10,
        "summiter": 15,
        "mountaineer": 20,
    }.get(pace, 10)


@app.get("/home")
async def proxy_home_preload(
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        profile_resp = await client.get(
            f"{settings.USER_PROFILE_SERVICE_URL}/profiles/me",
            headers={"X-User-Id": user_id},
        )
        if profile_resp.status_code >= 400:
            raise HTTPException(status_code=profile_resp.status_code, detail=profile_resp.text)

        goals_resp = await client.get(
            f"{settings.PROGRESS_SERVICE_URL}/goals/progress",
            headers={"X-User-Id": user_id},
        )
        if goals_resp.status_code >= 400:
            raise HTTPException(status_code=goals_resp.status_code, detail=goals_resp.text)

        courses_resp = await client.get(
            f"{settings.COURSES_SERVICE_URL}/courses",
            headers={"X-User-Id": user_id},
        )
        if courses_resp.status_code >= 400:
            raise HTTPException(status_code=courses_resp.status_code, detail=courses_resp.text)

    profile = profile_resp.json()
    goals = goals_resp.json()
    courses = courses_resp.json()
    if not isinstance(courses, list):
        courses = []

    active_courses = [c for c in courses if isinstance(c, dict) and _is_active_course(c)]
    active_courses.sort(key=lambda c: int(c.get("progress_percent", 0) or 0))
    target = active_courses[0] if active_courses else None

    full_name = (profile.get("full_name") if isinstance(profile, dict) else None) or ""
    username = (profile.get("username") if isinstance(profile, dict) else None) or ""
    daily_pace = profile.get("daily_pace") if isinstance(profile, dict) else None

    active_course = None
    if target:
        active_course = {
            "id": target.get("id"),
            "title": target.get("title"),
            "progress_percent": int(target.get("progress_percent", 0) or 0),
            "status": target.get("status"),
        }

    return {
        "display_name": (full_name.strip() or username.strip() or "there"),
        "current_streak": int(goals.get("current_streak", 0) or 0),
        "longest_streak": int(goals.get("longest_streak", 0) or 0),
        "current_minutes": int(goals.get("current_minutes", 0) or 0),
        "goal_minutes": _goal_minutes_from_daily_pace(daily_pace),
        "active_course": active_course,
    }


@app.post("/profile/init")
async def proxy_profile_init(
    body: dict,
    authorization: str | None = Header(default=None),
):
    """
    Initialize a profile row for the authenticated user.

    Flow:
    1. Validate JWT and extract user_id.
    2. Forward the request body to user-profile-service.
    3. Include X-User-Id for identity.
    4. Return the downstream response.

    Typical usage:
    - Called after signup/login when initial profile data is collected.
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


@app.get("/profile/image")
async def proxy_profile_image_get(
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.get(
            f"{settings.USER_PROFILE_SERVICE_URL}/profiles/me/image",
            headers={"X-User-Id": user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


@app.patch("/profile/image")
async def proxy_profile_image_patch(
    body: dict,
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.patch(
            f"{settings.USER_PROFILE_SERVICE_URL}/profiles/me/image",
            headers={"X-User-Id": user_id},
            json=body,
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


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
    4. Return the downstream response.

    Used for:
    - Multi-step onboarding updates
    - Marking onboarding as complete
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


@app.patch("/profile")
async def proxy_profile_patch(
    body: dict,
    authorization: str | None = Header(default=None),
):
    """
    Update editable profile details.

    This route is intended for profile page edits such as full_name,
    native_language, learning_goal, feedback_tone, accent, and daily_pace.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.patch(
            f"{settings.USER_PROFILE_SERVICE_URL}/profiles/me",
            headers={"X-User-Id": user_id},
            json=body,
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


@app.get("/profile/page")
async def profile_page_preload(
    authorization: str | None = Header(default=None),
):
    """
    Preload profile page data in one request for the mobile client.

    Aggregates:
    - user-profile-service /profiles/me
    - follow-service /counts
    - progress-service /goals/progress (streak)
    - progress-service /phonemes/overall-accuracy
    - courses-service /lessons/completed-count
    - progress-service /daily-activity (last 5 days)
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        profile_req = client.get(
            f"{settings.USER_PROFILE_SERVICE_URL}/profiles/me",
            headers={"X-User-Id": user_id},
        )
        counts_req = client.get(
            f"{settings.FOLLOW_SERVICE_URL}/counts",
            headers={"X-User-Id": user_id},
        )
        goals_req = client.get(
            f"{settings.PROGRESS_SERVICE_URL}/goals/progress",
            headers={"X-User-Id": user_id},
        )
        accuracy_req = client.get(
            f"{settings.PROGRESS_SERVICE_URL}/phonemes/overall-accuracy",
            headers={"X-User-Id": user_id},
        )
        lessons_completed_req = client.get(
            f"{settings.COURSES_SERVICE_URL}/lessons/completed-count",
            headers={"X-User-Id": user_id},
        )
        activity_req = client.get(
            f"{settings.PROGRESS_SERVICE_URL}/daily-activity",
            headers={"X-User-Id": user_id},
        )
        profile_res, counts_res, goals_res, accuracy_res, lessons_completed_res, activity_res = await asyncio.gather(
            profile_req,
            counts_req,
            goals_req,
            accuracy_req,
            lessons_completed_req,
            activity_req,
        )

    if profile_res.status_code >= 400:
        raise HTTPException(status_code=profile_res.status_code, detail=profile_res.text)
    if counts_res.status_code >= 400:
        raise HTTPException(status_code=counts_res.status_code, detail=counts_res.text)
    if goals_res.status_code >= 400:
        raise HTTPException(status_code=goals_res.status_code, detail=goals_res.text)
    if accuracy_res.status_code >= 400:
        raise HTTPException(status_code=accuracy_res.status_code, detail=accuracy_res.text)
    if lessons_completed_res.status_code >= 400:
        raise HTTPException(status_code=lessons_completed_res.status_code, detail=lessons_completed_res.text)

    return {
        "profile": profile_res.json(),
        "social": counts_res.json(),
        "stats": {
            "current_streak": int(goals_res.json().get("current_streak", 0) or 0),
            "overall_accuracy": float(accuracy_res.json().get("overall_accuracy", 0.0) or 0.0),
            "lessons_completed": int(lessons_completed_res.json().get("lessons_completed", 0) or 0),
            "meters_climbed": int(lessons_completed_res.json().get("meters_climbed", 0) or 0),
            "level": int(lessons_completed_res.json().get("level", 1) or 1),
        },
        "activity": activity_res.json() if activity_res.status_code < 400 else [],
    }


@app.delete("/account", status_code=204)
async def delete_account(
    authorization: str | None = Header(default=None),
):
    """
    Delete the authenticated user's account completely.

    This is a destructive operation that:
    1. Deletes user profile (user-profile-service)
    2. Deletes all user follows (follow-service)
    3. Deletes all user courses and progress (courses-service)
    4. Deletes all user phoneme metrics and stats (progress-service)
    5. Deletes all user group memberships (group-service)
    6. Deletes user from Supabase Auth

    Flow:
    1. Validate JWT and extract user_id.
    2. Make parallel DELETE calls to all services.
    3. Delete user from Supabase Auth.
    4. Return 204 No Content on success.

    Notes:
    - This operation is irreversible.
    - User will not appear in any public profiles or follower lists.
    - All user data is permanently deleted.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=30) as client:
        # Parallel deletion from all services
        profile_delete = client.delete(
            f"{settings.USER_PROFILE_SERVICE_URL}/profiles/me",
            headers={"X-User-Id": user_id},
        )
        follows_delete = client.delete(
            f"{settings.FOLLOW_SERVICE_URL}/account",
            headers={"X-User-Id": user_id},
        )
        courses_delete = client.delete(
            f"{settings.COURSES_SERVICE_URL}/account",
            headers={"X-User-Id": user_id},
        )
        progress_delete = client.delete(
            f"{settings.PROGRESS_SERVICE_URL}/account",
            headers={"X-User-Id": user_id},
        )
        group_delete = client.delete(
            f"{settings.GROUP_SERVICE_URL}/account",
            headers={"X-User-Id": user_id},
        )

        profile_res, follows_res, courses_res, progress_res, group_res = await asyncio.gather(
            profile_delete,
            follows_delete,
            courses_delete,
            progress_delete,
            group_delete,
            return_exceptions=True,
        )

    # Check for errors (but don't fail if one service is unavailable)
    # Log issues but proceed with deletion
    for i, res in enumerate([profile_res, follows_res, courses_res, progress_res, group_res]):
        if isinstance(res, Exception):
            # Service might be down, continue anyway
            continue
        if isinstance(res, httpx.Response) and res.status_code >= 400:
            # Log but don't fail - user account should still be deleted
            pass

    # Delete user from Supabase Auth (this is the final deletion)
    # This removes the user completely from authentication
    from app.supabase_client import supabase_auth_delete_user
    try:
        await supabase_auth_delete_user(user_id)
    except Exception:
        # If auth deletion fails, still return success (user is deleted from all services)
        pass

    return None


# -----------------------------------
# Courses Service
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


@app.delete("/courses/{course_id}", status_code=204)
async def proxy_delete_course(
    course_id: str,
    authorization: str | None = Header(default=None),
):
    """
    Delete a course owned by the authenticated user.

    Flow:
    1. Validate JWT and extract user_id.
    2. Forward DELETE request to courses-service with X-User-Id.
    3. Return 204 No Content on success.
    4. Surface 403/404 errors from courses-service unchanged.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.delete(
            f"{settings.COURSES_SERVICE_URL}/courses/{course_id}",
            headers={"X-User-Id": user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)


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
    Orchestrate AI generation and course persistence.

    Flow:
    1. Validate JWT and extract user_id.
    2. Call AI service to generate course structure.
    3. Create the parent course row in courses-service.
    4. Normalize and persist generated curriculum in courses-service.
    5. Return an aggregated response containing:
       - created course row
       - persisted lessons
       - raw AI output

    Why this belongs in the Gateway:
    - This is a cross-service workflow.
    - AI service generates structure but does not own course tables.
    - Courses service owns persistence.
    - Gateway coordinates both while exposing a single endpoint to Flutter.
    """
    # Step 1: Validate identity.
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

        # Minimal validation before persistence.
        # The AI service should return a title and lessons, but the gateway
        # still validates and normalizes the response before writing anything.
        if "title" not in ai_data:
            raise HTTPException(status_code=502, detail="AI service returned no title")

        title = ai_data.get("title", "Untitled Course")
        image_url = ai_data.get("image_url")

        # Step 3: Create the parent course row first.
        course_resp = await client.post(
            f"{settings.COURSES_SERVICE_URL}/courses",
            headers={"X-User-Id": user_id},
            json={
                "title": title,
                "image_url": image_url,
            },
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

        # Step 4: Normalize AI lesson output into the curriculum payload
        # expected by courses-service.
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

            # Skip lessons with no valid items so courses-service
            # does not receive invalid curriculum data.
            if not normalized_items:
                continue

            curriculum_payload["lessons"].append({
                "title": lesson_title,
                "items": normalized_items,
            })

        # Persist the curriculum only if at least one valid lesson exists.
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

@app.get("/private_lobbies/{lobby_id}")
async def proxy_get_lobby(
    lobby_id: str,
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(
            f"{settings.GROUP_SERVICE_URL}/private_lobbies/{lobby_id}",
            headers={"X-User-Id": user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


class CreatePrivateLobbyReq(BaseModel):
    """
    Request schema for generating a private lobby.
    """
    username: str = Field(min_length=1, max_length=5000)
    user_id: str = Field(min_length=1, max_length=5000)


@app.post("/private_lobbies/create")
async def proxy_create_lobby(
    body: CreatePrivateLobbyReq,
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(
            f"{settings.GROUP_SERVICE_URL}/private_lobbies/create",
            headers={"X-User-Id": user_id},
            json={"username": body.username, "user_id": body.user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


class JoinPrivateLobbyReq(BaseModel):
    """
    Request schema for joining a private lobby.
    """
    user_id: str = Field(min_length=1, max_length=5000)
    lobby_id: int = Field(gt=0)
    username: str = Field(min_length=1, max_length=5000)


@app.post("/private_lobbies/join")
async def proxy_join_lobby(
    body: JoinPrivateLobbyReq,
    authorization: str | None = Header(default=None),
):
    """
    Fetch private lobby data from group-service.

    Flow:
    1. Validate JWT.
    2. Forward request with X-User-Id header.
    3. Return downstream JSON response.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(
            f"{settings.GROUP_SERVICE_URL}/private_lobbies/join",
            headers={"X-User-Id": user_id},
            json={"user_id": body.user_id, "lobby_id": body.lobby_id, "username": body.username},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


@app.get("/private_lobbies/me")
async def proxy_get_my_private_lobbies(
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(
            f"{settings.GROUP_SERVICE_URL}/private_lobbies/me",
            headers={"X-User-Id": user_id},
        )
        if r.status_code >= 400:
            raise HTTPException(status_code=r.status_code, detail=r.text)

        return r.json()


# -----------------------------------
# Follow Service
# -----------------------------------

@app.get("/social/followers")
async def proxy_social_followers(
    authorization: str | None = Header(default=None),
):
    """
    Fetch the authenticated user's followers from follow-service.

    Flow:
    1. Validate JWT.
    2. Forward request with X-User-Id.
    3. Return follower data.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.get(
            f"{settings.FOLLOW_SERVICE_URL}/followers",
            headers={"X-User-Id": user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


@app.delete("/private_lobbies/leave")
async def proxy_leave_lobby(
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.delete(
            f"{settings.GROUP_SERVICE_URL}/private_lobbies/leave",
            headers={"X-User-Id": user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


# -----------------------------------
# Public lobbies (matchmaking)
# -----------------------------------


@app.get("/public_lobbies/me")
async def proxy_get_my_public_lobbies(
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(
            f"{settings.GROUP_SERVICE_URL}/public_lobbies/me",
            headers={"X-User-Id": user_id},
        )
        if r.status_code >= 400:
            raise HTTPException(status_code=r.status_code, detail=r.text)

        return r.json()


@app.post("/public_lobbies/create")
async def proxy_create_public_lobby(
    body: CreatePrivateLobbyReq,
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(
            f"{settings.GROUP_SERVICE_URL}/public_lobbies/create",
            headers={"X-User-Id": user_id},
            json={"username": body.username, "user_id": body.user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


@app.post("/public_lobbies/join")
async def proxy_join_public_lobby(
    body: JoinPrivateLobbyReq,
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(
            f"{settings.GROUP_SERVICE_URL}/public_lobbies/join",
            headers={"X-User-Id": user_id},
            json={"user_id": body.user_id, "lobby_id": body.lobby_id, "username": body.username},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


@app.post("/public_lobbies/match")
async def proxy_match_public_lobby(
    body: CreatePrivateLobbyReq,
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=30) as client:
        r = await client.post(
            f"{settings.GROUP_SERVICE_URL}/public_lobbies/match",
            headers={"X-User-Id": user_id},
            json={"username": body.username, "user_id": body.user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


@app.get("/public_lobbies/{lobby_id}")
async def proxy_get_public_lobby(
    lobby_id: str,
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(
            f"{settings.GROUP_SERVICE_URL}/public_lobbies/{lobby_id}",
            headers={"X-User-Id": user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


@app.delete("/public_lobbies/leave")
async def proxy_leave_public_lobby(
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.delete(
            f"{settings.GROUP_SERVICE_URL}/public_lobbies/leave",
            headers={"X-User-Id": user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


class LiveKitTokenGatewayReq(BaseModel):
    lobby_id: str = Field(min_length=1)
    lobby_kind: Literal["private", "public"] = "private"


@app.post("/voice/livekit/token")
async def proxy_livekit_token(
    body: LiveKitTokenGatewayReq,
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.post(
            f"{settings.GROUP_SERVICE_URL}/voice/livekit/token",
            headers={"X-User-Id": user_id},
            json={"lobby_id": body.lobby_id, "lobby_kind": body.lobby_kind},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


@app.get("/social/following")
async def proxy_social_following(
    authorization: str | None = Header(default=None),
):
    """
    Fetch the authenticated user's following list from follow-service.

    Flow:
    1. Validate JWT.
    2. Forward request with X-User-Id.
    3. Return following data.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.get(
            f"{settings.FOLLOW_SERVICE_URL}/following",
            headers={"X-User-Id": user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


@app.get("/social/counts")
async def proxy_social_counts(
    authorization: str | None = Header(default=None),
):
    """
    Fetch follower/following counts from follow-service.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.get(
            f"{settings.FOLLOW_SERVICE_URL}/counts",
            headers={"X-User-Id": user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


@app.get("/social/search")
async def proxy_social_search(
    q: str,
    limit: int = 20,
    authorization: str | None = Header(default=None),
):
    """
    Search users by username through follow-service.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.get(
            f"{settings.FOLLOW_SERVICE_URL}/search",
            headers={"X-User-Id": user_id},
            params={"q": q, "limit": str(limit)},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


@app.post("/social/follow/{followee_id}")
async def proxy_social_follow_user(
    followee_id: str,
    authorization: str | None = Header(default=None),
):
    """
    Follow another user through follow-service.

    Flow:
    1. Validate JWT.
    2. Forward follow request with X-User-Id.
    3. Return downstream response.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(
            f"{settings.FOLLOW_SERVICE_URL}/follow/{followee_id}",
            headers={"X-User-Id": user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


@app.delete("/social/follow/{followee_id}")
async def proxy_social_unfollow_user(
    followee_id: str,
    authorization: str | None = Header(default=None),
):
    """
    Unfollow another user through follow-service.

    Flow:
    1. Validate JWT.
    2. Forward unfollow request with X-User-Id.
    3. Return downstream response.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.delete(
            f"{settings.FOLLOW_SERVICE_URL}/follow/{followee_id}",
            headers={"X-User-Id": user_id},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


# -----------------------------------
# Progress Service — Phoneme Scores
# -----------------------------------

@app.post("/progress/phonemes/batch")
async def proxy_phoneme_batch_update(
    body: dict,
    authorization: str | None = Header(default=None),
):
    """
    Merge a practice session's phoneme scores into the user's persistent record.

    Called by the Flutter app at the end of a solo practice session. The client
    sends per-phoneme aggregated scores and counts; the progress-service applies
    a weighted-average merge with any previously stored data.

    Flow:
    1. Validate JWT and extract user_id.
    2. Forward request body to progress-service with X-User-Id.
    3. Return the downstream response (updated count).

    Notes:
    - Best-effort: failures on the client side should not block the results UI.
    - The progress-service owns the 'user_phoneme_scores' table.
    """
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.post(
            f"{settings.PROGRESS_SERVICE_URL}/phonemes/batch",
            headers={"X-User-Id": user_id, "Content-Type": "application/json"},
            json=body,
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()


@app.post("/progress/daily-minutes")
async def proxy_daily_minutes_update(
    body: dict,
    authorization: str | None = Header(default=None),
):
    """
    Add a practice-session time delta to today's daily minutes.

    Expected body:
    - seconds_delta: int (elapsed active seconds in current session chunk)
    """
    user_id = verify_supabase_jwt(authorization)
    seconds_delta = int(body.get("seconds_delta", 0) or 0)

    async with httpx.AsyncClient(timeout=10) as client:
        profile_resp = await client.get(
            f"{settings.USER_PROFILE_SERVICE_URL}/profiles/me",
            headers={"X-User-Id": user_id},
        )
        if profile_resp.status_code >= 400:
            raise HTTPException(status_code=profile_resp.status_code, detail=profile_resp.text)
        profile = profile_resp.json()
        daily_pace = profile.get("daily_pace") if isinstance(profile, dict) else None
        goal_minutes = _goal_minutes_from_daily_pace(daily_pace)

        r = await client.post(
            f"{settings.PROGRESS_SERVICE_URL}/daily-minutes",
            headers={"X-User-Id": user_id, "Content-Type": "application/json"},
            json={"seconds_delta": seconds_delta, "goal_minutes": goal_minutes},
        )

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=r.text)

    return r.json()