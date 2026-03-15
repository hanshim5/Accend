"""
generate_router.py
"""

from fastapi import APIRouter, HTTPException
from ..schemas.generate_schema import GenerateCourseReq, GenerateCourseRes
from ..services.ai_service import generate_course_from_prompt

router = APIRouter()


@router.get("/health")
async def health():
    return {"ok": True, "service": "ai-course-gen-service"}


@router.post("/generate-course", response_model=GenerateCourseRes)
async def generate_course(body: GenerateCourseReq):
    prompt = body.prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt must be non-empty")

    result = generate_course_from_prompt(prompt)
    # result has {"title":..., "lessons":[{...}]}
    return result