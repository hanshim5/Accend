from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="ai-course-gen-service")

class GenerateCourseReq(BaseModel):
    prompt: str = Field(min_length=1, max_length=5000)

class GenerateCourseRes(BaseModel):
    title: str
    outline: list[str]

@app.get("/health")
def health():
    return {"ok": True, "service": "ai-course-gen-service"}

@app.post("/generate-course", response_model=GenerateCourseRes)
def generate_course(body: GenerateCourseReq):
    prompt = body.prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt must be non-empty")

    # STUB: replace with real LLM later
    title = f"Course: {prompt[:40].strip()}" if len(prompt) > 0 else "New Course"
    outline = [
        "Intro & key vocabulary",
        "Pronunciation focus items",
        "Practice phrases",
        "Mini review",
    ]
    return GenerateCourseRes(title=title, outline=outline)