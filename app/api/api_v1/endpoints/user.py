from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import logging

from app import models, schemas
from app.db.session import get_db
from app.core.security import get_current_user, hash_password, verify_password

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/me", response_model=schemas.UserResponse)
async def get_user_profile(current_user: models.User = Depends(get_current_user)):
    return current_user

@router.post("/change-password")
async def change_password(
    request: schemas.ChangePasswordRequest, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(get_current_user)
):
    if not verify_password(request.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Password saat ini salah")
    
    current_user.hashed_password = hash_password(request.new_password)
    db.commit()
    return {"message": "Password berhasil diubah"}

@router.get("/activities", response_model=List[schemas.UserActivityResponse])
async def get_user_activities(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    activities = db.query(models.UserActivity)\
        .filter(models.UserActivity.user_id == current_user.id)\
        .order_by(models.UserActivity.created_at.desc())\
        .limit(20)\
        .all()
    return activities
