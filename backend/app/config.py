from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # ✅ FIXED: Correct filename matching what Dockerfile downloads
    MODEL_PATH: str = "/app/models/nakhlah_robust_v1_best.pth"
    MODEL_IMG_SIZE: int = 260
    NUM_CLASSES: int = 9

    # ✅ SECURITY FIX: No default value — must be set via environment variable.
    # On Render: set API_KEY in the Environment Variables dashboard.
    # Locally: add to .env file (never commit .env).
    API_KEY: str
    API_KEY_HEADER: str = "X-API-Key"

    MAX_IMAGE_MB: int = 5
    DEVICE: str = "cpu"

    WARMUP_ON_STARTUP: bool = True

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    return Settings()