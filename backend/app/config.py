from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Model — default is the container path set in Dockerfile ENV.
    # Override with MODEL_PATH env var on Render dashboard.
    MODEL_PATH: str = "/app/models/nakhlah_model.pth"
    MODEL_IMG_SIZE: int = 260          # EfficientNet-B2 native
    NUM_CLASSES: int = 9

    # Security — MUST be overridden via Render environment variables.
    # Never commit a real key here.
    API_KEY: str = "change-me-in-prod"
    API_KEY_HEADER: str = "X-API-Key"

    # Performance
    MAX_IMAGE_MB: int = 5
    DEVICE: str = "cpu"                # Render free tier has no GPU

    # Warm up the model on startup so the first real request is fast
    WARMUP_ON_STARTUP: bool = True

    class Config:
        env_file = ".env"
        # Also read from environment variables (set on Render dashboard)
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    return Settings()