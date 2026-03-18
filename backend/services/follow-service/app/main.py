from fastapi import FastAPI

from app.config import settings
from app.routers.follows import router as follows_router


app = FastAPI(title=settings.SERVICE_NAME)


@app.get("/health")
def health():
    return {"ok": True, "service": settings.SERVICE_NAME}


app.include_router(follows_router)