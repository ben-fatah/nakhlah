from fastapi import APIRouter, HTTPException, status
from app.services import firebase_service

router = APIRouter(prefix="/dates", tags=["dates"])


@router.get("")
async def list_dates():
    dates = await firebase_service.get_all_dates()
    return {"dates": dates}


@router.get("/{name}")
async def get_date(name: str):
    info = await firebase_service.get_date_info(name)
    if not info:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"No info for '{name}'")
    return info
