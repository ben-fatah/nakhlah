"""
POST /predict
Accepts a multipart image upload, runs inference, returns JSON.
"""
import logging
from datetime import datetime, timezone

from fastapi import APIRouter, File, UploadFile, HTTPException, status, Depends

from app.model_loader  import NakhlahModel, DATE_METADATA
from app.preprocessing import bytes_to_tensor
from app.schemas       import PredictResponse, Prediction
from app.utils.security import require_api_key
from app.config        import get_settings

router   = APIRouter(prefix="/predict", tags=["predict"])
logger   = logging.getLogger(__name__)
settings = get_settings()

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}


@router.post(
    "",
    response_model=PredictResponse,
    summary="Classify a date-fruit image",
    responses={
        401: {"description": "Invalid API key"},
        413: {"description": "Image too large"},
        415: {"description": "Unsupported image type"},
        422: {"description": "Cannot decode image"},
    },
)
async def predict(
    file: UploadFile = File(..., description="JPEG / PNG / WEBP image of a date fruit"),
    _key: str = Depends(require_api_key),
):
    # ── 1. Validate content-type ─────────────────────────────────────────
    ct = (file.content_type or "").lower()
    if ct not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported file type '{ct}'. Use JPEG, PNG, or WEBP.",
        )

    # ── 2. Read & size-check ─────────────────────────────────────────────
    image_bytes = await file.read()
    max_bytes   = settings.MAX_IMAGE_MB * 1024 * 1024
    if len(image_bytes) > max_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"Image exceeds {settings.MAX_IMAGE_MB} MB limit.",
        )

    # ── 3. Preprocess ────────────────────────────────────────────────────
    try:
        tensor = bytes_to_tensor(image_bytes)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        )

    # ── 4. Inference ─────────────────────────────────────────────────────
    try:
        nakhlah    = NakhlahModel.instance()
        ranked     = nakhlah.predict(tensor)
    except Exception as exc:
        logger.exception("Inference failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Model inference failed. Please try again.",
        )

    # ── 5. Build response ────────────────────────────────────────────────
    top  = ranked[0]
    meta = DATE_METADATA.get(top["label"], {})

    logger.info(
        f"Prediction: {top['label']} ({top['confidence']*100:.1f}%) "
        f"— file={file.filename} size={len(image_bytes)//1024}KB"
    )

    return PredictResponse(
        label            = top["label"],
        nameAr           = meta.get("nameAr",   top["label"]),
        confidence       = top["confidence"],
        originEn         = meta.get("originEn", ""),
        originAr         = meta.get("originAr", ""),
        calories         = meta.get("calories", 0),
        carbs            = meta.get("carbs",    0),
        fiber            = meta.get("fiber",    0),
        potassium        = meta.get("potassium",0),
        all_predictions  = [Prediction(**p) for p in ranked],
        processed_at     = datetime.now(timezone.utc),
    )