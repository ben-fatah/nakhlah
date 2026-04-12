import logging
import time
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

_startup_time: float = 0.0


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _startup_time
    t0 = time.perf_counter()
    logger.info("Starting Nakhlah AI backend …")
    logger.info(f"MODEL_PATH = {settings.MODEL_PATH}")

    if settings.WARMUP_ON_STARTUP:
        try:
            NakhlahModel.instance()
            elapsed = time.perf_counter() - t0
            logger.info(f"Model warm-up complete in {elapsed:.1f}s")
        except FileNotFoundError as exc:
            # Log clearly so Render logs show exactly what happened
            logger.error(
                f"MODEL FILE NOT FOUND: {exc}\n"
                f"  → Set the MODEL_PATH environment variable on the Render dashboard.\n"
                f"  → The model file must exist at that path inside the container.\n"
                f"  → Current value: {settings.MODEL_PATH}"
            )
            raise  # Crash at startup — better than silently serving 500s

    _startup_time = time.perf_counter() - t0
    yield
    logger.info("Shutting down")


app = FastAPI(
    title       = "Nakhlah AI API",
    description = "Date-fruit classification endpoint for the Nakhlah Flutter app.",
    version     = "2.0.0",
    lifespan    = lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins     = ["*"],
    allow_credentials = True,
    allow_methods     = ["*"],
    allow_headers     = ["*"],
)

app.middleware("http")(log_requests)
app.include_router(predict.router)


@app.get("/health", tags=["health"])
async def health():
    """Lightweight liveness check — does not touch the model."""
    return {
        "status": "ok",
        "model_path": settings.MODEL_PATH,
        "startup_seconds": round(_startup_time, 1),
    }


@app.get("/warmup", tags=["health"])
async def warmup():
    """
    Ensures the model is loaded and runs a dummy inference pass.
    Flutter should call this once at app launch (fire-and-forget) so that
    the first real scan does not pay the cold-start penalty.
    Returns immediately once the model is ready.
    """
    try:
        m = NakhlahModel.instance()
        # Quick dummy forward pass to warm up the interpreter
        import torch
        dummy = torch.zeros(1, 3, settings.MODEL_IMG_SIZE, settings.MODEL_IMG_SIZE)
        m.predict(dummy)
        return {"status": "ready"}
    except Exception as exc:
        logger.error(f"Warmup failed: {exc}")
        return {"status": "error", "detail": str(exc)}