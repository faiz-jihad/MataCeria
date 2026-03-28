from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from typing import List
import datetime
import logging

from app import models, schemas
from app.db.session import get_db
from app.core.security import get_current_user
from app.services import ml_service
from app.utils import log_activity

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/refraction-test", response_model=schemas.RiwayatTesResponse)
async def upload_test_result(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    if not file.filename.lower().endswith((".png", ".jpg", ".jpeg")):
        raise HTTPException(status_code=400, detail="Format file harus JPG atau PNG")

    timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    file_location = f"uploads/images/user_{current_user.id}_{timestamp}_{file.filename}"
    
    with open(file_location, "wb+") as file_object:
        file_object.write(await file.read())

    try:
        hasil, dioptri, conf = ml_service.predict_refraction(file_location)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gagal memproses gambar: {str(e)}")

    riwayat_baru = models.RiwayatTes(
        user_id=current_user.id,
        image_path=file_location,
        hasil_klasifikasi=hasil,
        estimasi_dioptri=dioptri,
        confidence_score=conf,
    )

    db.add(riwayat_baru)
    db.commit()
    db.refresh(riwayat_baru)
    
    log_activity(db, current_user.id, "Tes Mata", f"Hasil: {hasil} ({dioptri})")
    return riwayat_baru

@router.get("/refraction-test", response_model=schemas.RefractionHistoryResponse)
@router.get("/predictions", response_model=schemas.RefractionHistoryResponse)
async def get_predictions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    Returns standardized prediction history for the mobile app.
    """
    riwayat = db.query(models.RiwayatTes)\
        .filter(models.RiwayatTes.user_id == current_user.id)\
        .order_by(models.RiwayatTes.waktu_tes.desc())\
        .all()
    
    formatted_data = []
    for item in riwayat:
        # Pengecekan standar untuk image_url
        img_url = item.image_path
        if img_url and not img_url.startswith("/"):
            img_url = f"/{img_url}"

        # Mapping data medis ke nested 'results'
        # Kita coba parsing rekomendasi dari catatan_admin jika ada
        recommendation = "Silakan konsultasi dokter."
        if item.catatan_admin and "AI Recommendation: " in item.catatan_admin:
            recommendation = item.catatan_admin.replace("AI Recommendation: ", "")

        history_item = schemas.RefractionHistoryItem(
            id=item.id,
            created_at=item.waktu_tes,
            image_url=img_url,
            predicted_class=item.hasil_klasifikasi,
            confidence=item.confidence_score,
            results=schemas.RefractionTestResult(
                visual_acuity=item.estimasi_dioptri,
                snellen_decimal=0.0, # Legacy data might not have decimals saved
                category=item.hasil_klasifikasi,
                condition_category="Miopia", # Default fallback
                recommendation=recommendation
            )
        )
        formatted_data.append(history_item)

    return {
        "status": "success",
        "data": formatted_data
    }
