"""
main.py

Profile Service - Application Entry Point

Purpose:
- Initialize the FastAPI application for the profile service.
- Register routers that expose profile-related endpoints.
- Configure basic app metadata (e.g., service name).

Architecture:
This is the entrypoint for the profile-service container.

Flow:
- Uvicorn starts this file
- FastAPI app is created
- Routers are registered
- Requests are routed to the appropriate handlers

Notes:
- This service is intended to be accessed via the API Gateway.
- Authentication is handled upstream (Gateway injects X-User-Id).
- This service focuses on profile and onboarding data only.
"""

from fastapi import FastAPI
from app.routers.health import router as health_router
from app.routers.profile import router as profile_router
from app.config import settings

# Create FastAPI app instance with service name for docs/visibility.
app = FastAPI(title=settings.SERVICE_NAME)

# Register health check routes (used for monitoring and container checks).
app.include_router(health_router)

# Register profile-related routes (main functionality of this service).
app.include_router(profile_router)