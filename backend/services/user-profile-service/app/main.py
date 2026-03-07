from fastapi import FastAPI
from app.routers.health import router as health_router
from app.routers.profile import router as profile_router
from app.config import settings

app = FastAPI(title=settings.SERVICE_NAME)

app.include_router(health_router)
app.include_router(profile_router)