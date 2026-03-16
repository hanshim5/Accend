"""
main.py
"""

from fastapi import FastAPI
from app.routers import generate_router

app = FastAPI(title="ai-course-gen-service")

app.include_router(generate_router.router, prefix="")

@app.get("/")
async def root():
    return {"service": "ai-course-gen-service", "ok": True}