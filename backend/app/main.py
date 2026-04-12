import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config        import get_settings
from app.model_loader  import NakhlahModel
from app.routers       import predict
from app.utils.logging import setup_logging, log_requests

setup_logging()
logger   = logging.getLogger(__name__)
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Runs once on startup: pre-load the model so the FIRST real request
    doesn't pay the cold-start penalty.
    """
    logger.info("🚀 Starting Nakhlah AI backend …")
    if settings.WARMUP_ON_STARTUP:
        NakhlahModel.instance()          # loads weights into memory
        logger.info("✅ Model warm-up complete")
    yield
    logger.info("👋 Shutting down")


app = FastAPI(
    title       = "Nakhlah AI API",
    description = "Date-fruit classification endpoint for the Nakhlah Flutter app.",
    version     = "2.0.0",
    lifespan    = lifespan,
)

# ── CORS (tighten origins in production) ────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins     = ["*"],    # replace with your domain in prod
    allow_credentials = True,
    allow_methods     = ["*"],
    allow_headers     = ["*"],
)

# ── Request logging middleware ───────────────────────────────────────────────
app.middleware("http")(log_requests)

# ── Routers ──────────────────────────────────────────────────────────────────
app.include_router(predict.router)


@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok", "model": settings.MODEL_PATH}