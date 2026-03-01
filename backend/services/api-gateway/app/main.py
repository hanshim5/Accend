from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field
import httpx

from app.config import settings
from app.auth import verify_supabase_jwt
from app.supabase_client import supabase

app = FastAPI(title="api-gateway")


@app.get("/health")
def health():
    return {"ok": True, "service": "api-gateway"}


# ---------- username helper ----------
@app.get("/profile/username-available")
def username_available(username: str):
    u = username.strip().lower()
    if not u:
        raise HTTPException(status_code=400, detail="username required")

    res = supabase().table("profiles").select("id").eq("username", u).limit(1).execute()
    taken = bool(res.data)
    return {"username": u, "available": not taken}


# ---------- Proxy to courses-service ----------
@app.get("/courses")
async def proxy_list_courses(authorization: str | None = Header(default=None)):
    user_id = verify_supabase_jwt(authorization)
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(
            f"{settings.COURSES_SERVICE_URL}/courses",
            headers={"X-User-Id": user_id},
        )
        return r.json()


@app.post("/courses")
async def proxy_create_course(
    body: dict,
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.post(
            f"{settings.COURSES_SERVICE_URL}/courses",
            headers={"X-User-Id": user_id},
            json=body,
        )
        return r.json()


# ---------- generate course ----------
class GenerateReq(BaseModel):
    prompt: str = Field(min_length=1, max_length=5000)

@app.post("/ai/generate-course")
async def generate_course(
    req: GenerateReq,
    authorization: str | None = Header(default=None),
):
    user_id = verify_supabase_jwt(authorization)

    async with httpx.AsyncClient(timeout=30) as client:
        # 1) Ask AI service for generated structure (stubbed)
        ai_resp = await client.post(
            f"{settings.AI_COURSE_GEN_SERVICE_URL}/generate-course",
            json={"prompt": req.prompt},
        )
        if ai_resp.status_code >= 400:
            raise HTTPException(status_code=ai_resp.status_code, detail=ai_resp.text)
        ai_data = ai_resp.json()

        # 2) Store generated course in courses-service
        course_resp = await client.post(
            f"{settings.COURSES_SERVICE_URL}/courses",
            headers={"X-User-Id": user_id},
            json={"title": ai_data["title"]},
        )
        if course_resp.status_code >= 400:
            raise HTTPException(status_code=course_resp.status_code, detail=course_resp.text)

        return {
            "course": course_resp.json(),
            "ai": ai_data,
        }