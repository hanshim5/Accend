from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    SERVICE_NAME: str = "user-profile-service"

    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()