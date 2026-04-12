from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    # Model
    MODEL_PATH: str = "C:/ai/nakhlah/ai/models/nakhlah_model_v2_best.pth"
    MODEL_IMG_SIZE: int = 260          # EfficientNet-B2 native
    NUM_CLASSES: int = 9

    # Security
    API_KEY: str = "change-me-in-prod"
    API_KEY_HEADER: str = "X-API-Key"

    # Performance
    MAX_IMAGE_MB: int = 5
    DEVICE: str = "cpu"                # "cuda" if GPU available on Render

    # Render free tier keeps the service alive on first request
    WARMUP_ON_STARTUP: bool = True

    class Config:
        env_file = ".env"

@lru_cache
def get_settings() -> Settings:
    return Settings()
