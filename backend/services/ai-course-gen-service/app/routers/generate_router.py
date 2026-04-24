"""
generate_router.py

AI Course Generation Router (API Layer)

Purpose:
- Expose HTTP endpoints for the AI course generation service.
- Validate incoming requests at the API boundary.
- Delegate content generation to the AI service layer.

Architecture:
Client (indirectly via Gateway) → Gateway → AI Course Gen Service (this router) → AI Service

Important:
- Flutter should not call this service directly.
- The Gateway is the public entry point and is responsible for auth.
- This service focuses only on generating structured course content from a prompt.

Endpoints:
- GET  /health
- POST /generate-course
- POST /generate-onboarding-seed
"""

from fastapi import APIRouter, Header, HTTPException
from ..schemas.generate_schema import (
    GenerateCourseReq,
    GenerateCourseRes,
    GenerateSessionItemsReq,
    GenerateSessionItemsRes,
    SeedOnboardingCourseReq,
)
from ..prompts.onboarding_seed import build_onboarding_seed_prompt
from ..services.ai_service import generate_course_from_prompt, generate_course_from_metrics, generate_session_items

# Router for AI course generation endpoints.
router = APIRouter()


@router.get("/health")
async def health():
    """
    Health check endpoint for container/service monitoring.

    Used for:
    - Docker/local smoke tests
    - Verifying the service is running and reachable
    - Basic orchestration checks
    """
    return {"ok": True, "service": "ai-course-gen-service"}


@router.post("/generate-course", response_model=GenerateCourseRes)
async def generate_course(body: GenerateCourseReq):
    """
    Generate a structured course from a free-text prompt.

    Flow:
    1. Receive and validate request body using GenerateCourseReq.
    2. Normalize prompt by trimming whitespace.
    3. Reject empty prompts.
    4. Call AI service to generate structured course content.
    5. Return response validated as GenerateCourseRes.

    Notes:
    - This route performs only lightweight input validation.
    - Prompt engineering and generation logic belong in the service layer.
    """
    # Normalize prompt so whitespace-only input does not pass validation.
    prompt = body.prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt must be non-empty")

    try:
        result = generate_course_from_prompt(prompt)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except RuntimeError as exc:
        msg = str(exc)
        if "503" in msg or "UNAVAILABLE" in msg:
            raise HTTPException(status_code=503, detail="AI generation service temporarily unavailable. Please try again.")
        raise HTTPException(status_code=502, detail=msg)

    # The generated result is expected to match the response schema shape:
    # {"title": ..., "lessons": [{...}]}
    return result


@router.post("/generate-onboarding-seed", response_model=GenerateCourseRes)
async def generate_onboarding_seed(body: SeedOnboardingCourseReq):
    """
    Build a course from hardcoded goal templates plus optional focus areas.

    Used after onboarding; the gateway persists the result like a normal generate-course flow.
    """
    try:
        prompt = build_onboarding_seed_prompt(
            body.learning_goal,
            body.focus_areas or None,
        )
        result = generate_course_from_prompt(prompt)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except RuntimeError as exc:
        msg = str(exc)
        if "503" in msg or "UNAVAILABLE" in msg:
            raise HTTPException(status_code=503, detail="AI generation service temporarily unavailable. Please try again.")
        raise HTTPException(status_code=502, detail=msg)

    return result


@router.post("/generate-course-from-metrics", response_model=GenerateCourseRes)
async def generate_course_from_user_metrics(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
):
    """
    Generate a pronunciation course targeting the user's weakest phonemes.

    Flow:
    1. Extract authenticated user identity from the X-User-Id header (set by Gateway).
    2. Fetch the user's lowest-accuracy phonemes from user_phoneme_metrics.
    3. Build a phoneme-targeted prompt from those results.
    4. Call Gemini to generate a structured course focused on those sounds.
    5. Return response validated as GenerateCourseRes.

    Notes:
    - X-User-Id is trusted because it is set by the Gateway after JWT verification.
    - Requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY to be configured.
    - Returns 422 if the user has no phoneme practice data yet.
    - Returns 503 if Supabase is not configured on this service.
    """
    if not x_user_id or not x_user_id.strip():
        raise HTTPException(status_code=401, detail="Missing X-User-Id")

    try:
        result = generate_course_from_metrics(x_user_id.strip())
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))
    except RuntimeError as exc:
        msg = str(exc)
        if "SUPABASE_URL" in msg or "SUPABASE_SERVICE_ROLE_KEY" in msg:
            raise HTTPException(status_code=503, detail=msg)
        if "503" in msg or "UNAVAILABLE" in msg:
            raise HTTPException(status_code=503, detail="AI generation service temporarily unavailable. Please try again.")
        raise HTTPException(status_code=502, detail=msg)

    return result


@router.post("/generate-session-items", response_model=GenerateSessionItemsRes)
async def generate_session_items_endpoint(body: GenerateSessionItemsReq):
    """
    Generate 20 short phrases/sentences for a group pronunciation session.

    Flow:
    1. Receive and validate the topic string.
    2. Call AI service to generate a flat list of 20 items guided by the topic.
    3. Return items in GenerateSessionItemsRes shape.

    Notes:
    - No course or lesson structure — just a flat list of 20 practice prompts.
    - Called by the Gateway when a group lobby host creates a session.
    """
    topic = body.topic.strip()
    if not topic:
        raise HTTPException(status_code=400, detail="Topic must be non-empty")

    try:
        items = generate_session_items(topic)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except RuntimeError as exc:
        msg = str(exc)
        if "503" in msg or "UNAVAILABLE" in msg:
            raise HTTPException(status_code=503, detail="AI generation service temporarily unavailable. Please try again.")
        raise HTTPException(status_code=502, detail=msg)

    return {"items": items}