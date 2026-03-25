from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import logging

from app import models, schemas
from app.db.session import get_db
from app.core.security import get_current_admin

router = APIRouter()
logger = logging.getLogger(__name__)

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
