"""
main.py

AI Course Generation Service - Application Entry Point

Purpose:
- Initialize the FastAPI application.
- Register routers (API endpoints).
- Provide basic root/health metadata for the service.

Architecture:
This is the entrypoint for the ai-course-gen-service container.

Flow:
- Uvicorn runs this file
- FastAPI app is created
- Routers are registered
- Requests are routed to the appropriate handlers

Notes:
- This service is intended to be called via the API Gateway.
- It does not handle authentication directly.
- It focuses only on AI-driven course generation.
"""

from fastapi import FastAPI
from app.routers import generate_router

# Create FastAPI application instance.
# The title is useful for OpenAPI docs (/docs).
app = FastAPI(title="ai-course-gen-service")

# Register route handlers from generate_router.
# prefix="" means routes are mounted at root (e.g., /generate-course).
app.include_router(generate_router.router, prefix="")


@app.get("/")
async def root():
    """
    Root endpoint for basic service verification.

    Used for:
    - Quick manual checks in browser
    - Debugging service availability
    - Simple uptime confirmation

    Note:
    - This is not a full health check (see /health for that).
    """
    return {"service": "ai-course-gen-service", "ok": True}