from fastapi import APIRouter, Depends, HTTPException, File, UploadFile
from sqlalchemy.orm import Session
from typing import List
import logging
import os
import shutil
import uuid

from app import models, schemas
from app.db.session import get_db
from app.core.security import get_current_user, hash_password, verify_password

router = APIRouter()
logger = logging.getLogger(__name__)

# Konfigurasi Upload
UPLOAD_DIR = "uploads/profiles"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.get("/me", response_model=schemas.UserResponse)
async def get_user_profile(current_user: models.User = Depends(get_current_user)):
    return current_user

@router.put("/me", response_model=schemas.ProfileUpdateResponse)
async def update_user_profile(
    request: schemas.UserUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    update_data = request.model_dump(exclude_unset=True)
    
    for key, value in update_data.items():
        setattr(current_user, key, value)
    
    db.commit()
    db.refresh(current_user)
    return {"status": "success", "data": current_user}

@router.put("/settings", response_model=schemas.UserResponse)
async def update_security_settings(
    request: schemas.UserSecurityUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    current_user.is_2fa_enabled = request.is_2fa_enabled
    db.commit()
    db.refresh(current_user)
    return current_user

@router.post("/profile-image")
async def upload_profile_image(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    # Validasi tipe file
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File harus berupa gambar")
    
    # Buat nama file unik
    file_extension = os.path.splitext(file.filename)[1]
    filename = f"{current_user.id}_{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    
    # Simpan file
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # Hapus foto lama jika ada
    if current_user.profile_image and os.path.exists(current_user.profile_image):
        try:
            os.remove(current_user.profile_image)
        except Exception as e:
            logger.error(f"Gagal menghapus foto lama: {e}")
    
    # Update database
    current_user.profile_image = file_path
    db.commit()
    
    return {"message": "Foto profil berhasil diperbarui", "profile_image": file_path}

@router.post("/change-password")
async def change_password(
    request: schemas.ChangePasswordRequest, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(get_current_user)
):
    if not verify_password(request.old_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Password saat ini salah")
    
    current_user.hashed_password = hash_password(request.new_password)
    db.commit()
    return {"message": "Password berhasil diubah"}

@router.get("/emergency-contacts", response_model=List[schemas.EmergencyContactResponse])
async def get_user_emergency_contacts(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    contacts = db.query(models.EmergencyContact).all()
    return contacts

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
