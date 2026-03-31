from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session
from typing import List
import logging

from app import models, schemas
from app.db.session import get_db
from app.core.security import get_current_admin
from app.utils import notify_all_users

router = APIRouter()
logger = logging.getLogger(__name__)

# Import templates from core module to avoid circular imports
from app.core.templates import templates

@router.get("/stats/overview")
async def get_admin_stats(
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    """
    Mendapatkan statistik ringkas untuk dashboard admin.
    """
    user_count = db.query(models.User).filter(models.User.role == models.UserRole.USER).count()
    test_count = db.query(models.RiwayatTes).count()
    article_count = db.query(models.Article).count()
    admin_count = db.query(models.User).filter(models.User.role == models.UserRole.ADMIN).count()

    return {
        "status": "success",
        "data": {
            "total_users": user_count,
            "total_tests": test_count,
            "total_articles": article_count,
            "total_admins": admin_count
        }
    }

@router.get("/dashboard", response_class=HTMLResponse)
async def get_admin_dashboard(
    request: Request,
    db: Session = Depends(get_db)
    # admin: models.User = Depends(get_current_admin) # Optional: Enable for security
):
    """
    Render halaman dashboard utama dalam format HTML.
    """
    user_count = db.query(models.User).filter(models.User.role == models.UserRole.USER).count()
    test_count = db.query(models.RiwayatTes).count()
    article_count = db.query(models.Article).count()
    admin_count = db.query(models.User).filter(models.User.role == models.UserRole.ADMIN).count()
    
    data = {
        "total_users": user_count,
        "total_tests": test_count,
        "total_articles": article_count,
        "total_admins": admin_count
    }
    
    return templates.TemplateResponse("admin_dashboard.html", {"request": request, "data": data})

@router.get("/users", response_model=List[schemas.UserResponse])
async def list_users(
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    """
    Daftar semua pengguna (Role: User) untuk manajemen akun di dashboard.
    """
    users = db.query(models.User).filter(models.User.role == models.UserRole.USER).all()
    return users

@router.get("/users/export")
async def export_users_data(
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    """
    Ekspor semua data user beserta hasil klasifikasi terbaru mereka.
    """
    users = db.query(models.User).all()
    
    export_data = []
    for user in users:
        # Ambil riwayat tes terbaru
        latest_test = db.query(models.RiwayatTes)\
            .filter(models.RiwayatTes.user_id == user.id)\
            .order_by(models.RiwayatTes.waktu_tes.desc())\
            .first()
        
        user_info = {
            "id": user.id,
            "nama_lengkap": user.nama_lengkap,
            "email": user.email,
            "umur": user.umur,
            "kelamin": user.kelamin,
            "jenjang_pendidikan": user.jenjang_pendidikan,
            "status_pekerjaan": user.status_pekerjaan,
            "vision_type": user.vision_type,
            "latest_classification": latest_test.hasil_klasifikasi if latest_test else "Belum Tes",
            "latest_diopter": latest_test.estimasi_dioptri if latest_test else "N/A",
            "last_test_date": latest_test.waktu_tes.strftime("%Y-%m-%d %H:%M:%S") if latest_test else "N/A",
            "created_at": user.created_at.strftime("%Y-%m-%d %H:%M:%S")
        }
        export_data.append(user_info)
        
    return {
        "status": "success",
        "total_users": len(export_data),
        "data": export_data
    }

@router.post("/notifications/broadcast")
async def broadcast_notification(
    notification: schemas.NotificationCreate,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    """
    Kirim notifikasi ke seluruh pengguna (Role: User).
    """
    notify_all_users(db, notification.title, notification.message)
    return {"status": "success", "message": f"Broadcast '{notification.title}' telah dikirim."}

@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    """
    Hapus user beserta seluruh data terkait (riwayat, notifikasi, dll) secara permanen.
    """
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    
    # Jangan biarkan admin menghapus dirinya sendiri dengan tidak sengaja lewat sini
    if user.id == admin.id:
        raise HTTPException(status_code=400, detail="Admin tidak dapat menghapus akunnya sendiri melalui endpoint ini")

    db.delete(user)
    db.commit()
    return None

@router.delete("/tests/{test_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_test_record(
    test_id: int,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    """
    Hapus salah satu catatan riwayat tes refraksi.
    """
    test = db.query(models.RiwayatTes).filter(models.RiwayatTes.id == test_id).first()
    if not test:
        raise HTTPException(status_code=404, detail="Catatan tes tidak ditemukan")
    
    db.delete(test)
    db.commit()
    return None
