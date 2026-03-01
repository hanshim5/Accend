"""
AI Course Generation Service

Purpose:
- Accept a text prompt from the Gateway.
- Generate a structured course (title + outline).
- Return that structure back to the Gateway.

Important:
- This service does NOT write to the database.
- It does NOT handle authentication (Gateway handles JWT).
- It is purely responsible for "AI logic".

Architecture role:
Flutter → Gateway → AI Service → (returns generated structure)
Gateway → Courses Service → stores generated course
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field


# Create FastAPI app instance for this microservice
app = FastAPI(title="ai-course-gen-service")


# -------------------------
# Request / Response Schemas
# -------------------------

class GenerateCourseReq(BaseModel):
    """
    Request body schema for generating a course.

    Example request:
    {
        "prompt": "Learn travel phrases for ordering food"
    }

    Constraints:
    - min_length ensures non-empty input
    - max_length prevents extremely large payloads
    """
    prompt: str = Field(min_length=1, max_length=5000)


class GenerateCourseRes(BaseModel):
    """
    Response schema for generated course structure.

    This is NOT a full course model.
    It is just the structured output from AI.

    Gateway will take this and store it via courses-service.
    """
    title: str
    outline: list[str]


# -------------------------
# Health Check Endpoint
# -------------------------

@app.get("/health")
def health():
    """
    Simple health check endpoint.

    Used by:
    - docker-compose testing
    - service monitoring
    - load balancers (later)

    If this returns 200, service is alive.
    """
    return {"ok": True, "service": "ai-course-gen-service"}


# -------------------------
# Generate Course Endpoint
# -------------------------

@app.post("/generate-course", response_model=GenerateCourseRes)
def generate_course(body: GenerateCourseReq):
    """
    POST /generate-course

    Flow:
    1. FastAPI parses and validates request body using GenerateCourseReq.
    2. We sanitize/clean the prompt.
    3. Generate structured course output (stubbed for now).
    4. Return structured data to Gateway.

    IMPORTANT:
    - This service does NOT persist anything.
    - Gateway handles saving to courses-service.
    """

    # Remove accidental whitespace
    prompt = body.prompt.strip()

    # Defensive check (even though schema enforces min_length=1)
    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt must be non-empty")

    # -------------------------------------------------
    # STUB IMPLEMENTATION (Sprint 1)
    # -------------------------------------------------
    # This is fake AI logic.
    # Later you will:
    # - Call an LLM (OpenAI, etc.)
    # - Possibly queue an async job (Redis)
    # - Return job_id instead of immediate result
    # -------------------------------------------------

    title = (
        f"Course: {prompt[:40].strip()}"
        if len(prompt) > 0
        else "New Course"
    )

    outline = [
        "Intro & key vocabulary",
        "Pronunciation focus items",
        "Practice phrases",
        "Mini review",
    ]

    # Return structured response (validated by Pydantic)
    return GenerateCourseRes(
        title=title,
        outline=outline,
    )