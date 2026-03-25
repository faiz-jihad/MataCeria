from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from app.core.ratelimit import limiter
import logging

from app import models, schemas
from app.db.session import get_db
from app.core.security import get_current_user
from app.services.refraction_service import RefractionService
from app.services.ai_inference_service import AIRefractionService
from app.utils import create_notification

router = APIRouter()
router_v2 = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/test", response_model=schemas.RefractionTestResponse, status_code=status.HTTP_200_OK)
@limiter.limit("5/minute")
async def submit_refraction_test(
    request: Request, 
    test_request: schemas.RefractionTestRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    Endpoint for Medical Refraction Screening based on Visual Acuity (Snellen).
    """
    # 1. Input Validation
    # Near vision distance validation (e.g., must be between 30 and 50 cm)
    if test_request.test_type == "near_vision":
        if not (30.0 <= test_request.raw_data.avg_distance_cm <= 50.0):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Untuk near vision, jarak harus 30-50 cm. Diterima: {test_request.raw_data.avg_distance_cm} cm."
            )
            
    # Validate logical non-negative/zero values
    if test_request.device_info.screen_ppi <= 0 or test_request.device_info.screen_width_px <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Informasi device (PPI dan Lebar Layar) harus bernilai lebih dari 0."
        )
        
    if test_request.raw_data.avg_distance_cm <= 0 or \
       test_request.raw_data.smallest_row_read <= 0 or \
       test_request.raw_data.missed_chars < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Data raw tes (jarak, baris terkecil baca, missed chars) tidak valid (0 atau negatif)."
        )
    
    # 2. Process Screening logic via Service
    try:
        results = RefractionService.process_screening(
            raw_data=test_request.raw_data,
            device_info=test_request.device_info
        )
        
        # 3. Kirim Notifikasi ke User
        create_notification(
            db, 
            current_user.id, 
            "Hasil Tes Tersedia! 🩺", 
            f"Tes refraksi Anda selesai. Hasil: {results.category}. Estimasi: {results.visual_acuity}."
        )

        # 4. Return JSON response
        return schemas.RefractionTestResponse(
            status="success",
            results=results
        )
    
    except Exception as e:
        logger.error(f"Error processing refraction test: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Terjadi kesalahan saat memproses tes refraksi."
        )

# --- V2 AI ENDPOINT ---
@router_v2.post("/ai", response_model=schemas.RefractionAIResponse, status_code=status.HTTP_200_OK)
@limiter.limit("10/minute")
async def process_hybrid_ai_refraction(
    request: Request,
    test_request: schemas.RefractionAIRequest,
    db: Session = Depends(get_db)
):
    """
    Endpoint for Hybrid AI Inference of Medical Refraction Screening.
    Combines rule-based Snellen scores with ML model predictions.
    """
    # 1. Validasi Input Dasar
    if test_request.device_info.screen_ppi <= 0:
        raise HTTPException(status_code=400, detail="Invalid PPI.")
    if test_request.snellen_data.avg_distance_cm <= 0:
        raise HTTPException(status_code=400, detail="Invalid distance.")
        
    # 2. Process Screening via AI Service
    try:
        results = AIRefractionService.predict(test_request)
        
        # 3. Opsional: Log ke Database untuk future training (disimpan di background / database)
        # Note: Kita bisa buat table log khusus, misal AILog, tapi untuk kecepatan
        # print saja ke log atau buat entry standard.
        logger.info(f"[AI Log] User {test_request.user_id} Result: {results.predicted_class} (Conf: {results.confidence})")

        return schemas.RefractionAIResponse(
            status="success",
            results=results
        )
    except ValueError as ve:
        logger.warning(f"Validation error in AI service: {ve}")
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"Critical error in AI service: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Terjadi kegagalan pemrosesan AI."
        )
