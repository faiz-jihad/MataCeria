from fastapi import APIRouter, Depends, HTTPException, status, Request
from app.core.ratelimit import limiter
from sqlalchemy.orm import Session
import secrets
import logging

from app import models, schemas
from app.db.session import get_db
from app.core.security import hash_password, verify_password, create_access_token
from app.utils import log_activity, create_notification

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/register", response_model=schemas.UserResponse)
@limiter.limit("5/minute")
async def register_user(request: Request, user_data: schemas.UserCreate, db: Session = Depends(get_db)):
    logger.info(f"Mencoba registrasi user baru: {user_data.email}")
    user_exist = db.query(models.User).filter(models.User.email == user_data.email).first()
    if user_exist:
        raise HTTPException(status_code=400, detail="Email sudah terdaftar!")

    new_user = models.User(
        nama_lengkap=user_data.nama_lengkap,
        email=user_data.email,
        hashed_password=hash_password(user_data.password),
        umur=user_data.umur,
        kelamin=user_data.kelamin,
        jenjang_pendidikan=user_data.jenjang_pendidikan,
        status_pekerjaan=user_data.status_pekerjaan,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    log_activity(db, new_user.id, "Registrasi", "User baru berhasil terdaftar")
    create_notification(
        db, 
        new_user.id, 
        "Selamat Datang! 👋", 
        f"Halo {new_user.nama_lengkap}, selamat bergabung di MataCeria. Mari jaga kesehatan mata Anda bersama kami."
    )
    return new_user

from fastapi.security import OAuth2PasswordRequestForm

@router.post("/login", response_model=schemas.Token)
@limiter.limit("5/minute")
async def login(
    request: Request, form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)
):
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        logger.warning(f"Percobaan login gagal untuk email: {form_data.username}")
        raise HTTPException(status_code=400, detail="Email atau password salah")

    logger.info(f"User login berhasil: {user.email}")
    log_activity(db, user.id, "Login", "Berhasil login ke sistem")
    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer", "role": user.role}

@router.post("/forgot-password")
async def forgot_password(request: schemas.ForgotPasswordRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == request.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Email tidak terdaftar")
    
    token = secrets.token_urlsafe(32)
    user.reset_token = token
    db.commit()
    return {"message": "Email reset password telah dikirim", "reset_token": token}

@router.post("/reset-password")
async def reset_password(request: schemas.ResetPasswordRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.reset_token == request.token).first()
    if not user:
        raise HTTPException(status_code=400, detail="Token tidak valid atau sudah kedaluwarsa")
    
    user.hashed_password = hash_password(request.new_password)
    user.reset_token = None
    db.commit()
    return {"message": "Password berhasil direset"}
