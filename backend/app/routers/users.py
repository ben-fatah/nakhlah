from fastapi import APIRouter, Depends, HTTPException, status
from app.dependencies import verify_firebase_token
from app.services import firebase_service
from app.schemas.models import UserProfile, UserUpdateRequest

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserProfile)
async def get_my_profile(user: dict = Depends(verify_firebase_token)):
    uid = user["uid"]
    doc = await firebase_service.get_user(uid)
    if not doc:
        # Auto-create on first access
        doc = {"uid": uid, "email": user.get("email"), "scan_count": 0}
        await firebase_service.upsert_user(uid, doc)
    return UserProfile(**doc)


@router.put("/me", response_model=UserProfile)
async def update_my_profile(
    body: UserUpdateRequest,
    user: dict = Depends(verify_firebase_token),
):
    uid = user["uid"]
    updates = body.model_dump(exclude_none=True)
    if not updates:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nothing to update")
    await firebase_service.upsert_user(uid, updates)
    doc = await firebase_service.get_user(uid)
    return UserProfile(**doc)
