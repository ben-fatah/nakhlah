"""
routers/scan.py
POST /scan  – upload image → AI inference → save to Firestore → return result
"""

from fastapi import APIRouter, Depends, File, UploadFile, HTTPException, status
from firebase_admin import storage as fb_storage
import uuid

from app.dependencies import verify_firebase_token
from app.services import inference_service, firebase_service
from app.schemas.models import ScanResponse

router = APIRouter(prefix="/scan", tags=["scan"])

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_SIZE_MB = 10


@router.post("", response_model=ScanResponse)
async def scan_image(
    file: UploadFile = File(...),
    user: dict = Depends(verify_firebase_token),
):
    # ── Validate ────────────────────────────────────────────────────────────
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported file type: {file.content_type}",
        )

    image_bytes = await file.read()

    if len(image_bytes) > MAX_SIZE_MB * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"Image must be under {MAX_SIZE_MB} MB",
        )

    uid = user["uid"]

    # ── Run inference ────────────────────────────────────────────────────────
    result = await inference_service.classify_image(image_bytes, file.filename or "image.jpg")

    top = result["top"]
    all_preds = result["all_predictions"]

    # ── Upload image to Firebase Storage (optional, non-blocking) ───────────
    image_url: str | None = None
    try:
        bucket = fb_storage.bucket()
        blob_path = f"scans/{uid}/{uuid.uuid4()}.jpg"
        blob = bucket.blob(blob_path)
        blob.upload_from_string(image_bytes, content_type="image/jpeg")
        blob.make_public()
        image_url = blob.public_url
    except Exception:
        pass  # Storage failure is non-fatal — scan result is still returned

    # ── Persist to Firestore ─────────────────────────────────────────────────
    scan_id = await firebase_service.save_scan(
        uid=uid,
        label=top["label"],
        confidence=top["confidence"],
        all_predictions=all_preds,
        image_url=image_url,
    )

    # Ensure user doc exists
    user_doc = await firebase_service.get_user(uid)
    if not user_doc:
        await firebase_service.upsert_user(uid, {"uid": uid, "scan_count": 0})

    from datetime import datetime, timezone
    return ScanResponse(
        scan_id=scan_id,
        user_id=uid,
        label=top["label"],
        confidence=top["confidence"],
        all_predictions=all_preds,
        image_url=image_url,
        scanned_at=datetime.now(timezone.utc),
    )


@router.get("/history")
async def scan_history(user: dict = Depends(verify_firebase_token)):
    scans = await firebase_service.get_user_scans(user["uid"])
    return {"scans": scans}
