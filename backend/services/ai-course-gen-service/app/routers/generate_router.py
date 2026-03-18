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
"""

from fastapi import APIRouter, HTTPException
from ..schemas.generate_schema import GenerateCourseReq, GenerateCourseRes
from ..services.ai_service import generate_course_from_prompt

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

    # Delegate actual generation logic to the AI service layer.
    result = generate_course_from_prompt(prompt)

    # The generated result is expected to match the response schema shape:
    # {"title": ..., "lessons": [{...}]}
    return result