from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Path where the .pth model file lives INSIDE the container.
    # The Dockerfile downloads it to /app/models/nakhlah_model.pth at build time.
    # Override with MODEL_PATH on the Render environment variables dashboard.
    MODEL_PATH: str = "/app/models/nakhlah_model.pth"
    MODEL_IMG_SIZE: int = 260
    NUM_CLASSES: int = 9

    API_KEY: str = "change-me-in-prod"
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