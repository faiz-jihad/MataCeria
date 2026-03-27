import os
import base64
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from app.core.ratelimit import limiter
import logging

from app import models, schemas
from app.db.session import get_db
from app.core.security import get_current_user
from app.services.refraction_service import RefractionService
from app.services.ai_inference_service import AIRefractionService
from app.services.face_detection_service import FaceDetectionService
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
        
    # Log raw data for debugging (as requested by user)
    # Mask image data to keep logs readable
    debug_data = test_request.model_dump()
    if "image_data" in debug_data:
        debug_data["image_data"]["eye_frame_base64"] = "[MASKED]"
    logger.info(f"AI RAW DATA: {debug_data}")
        
    # 2. Process Screening via AI Service
    try:
        results = AIRefractionService.predict(test_request)
        
        # 3. Simpan Gambar & Log ke Database untuk Riwayat
        image_path = "uploads/refraction/default.jpg"
        try:
            # Pastikan direktori ada
            os.makedirs("uploads/refraction", exist_ok=True)
            
            # Decode dan simpan gambar
            img_data = test_request.image_data.eye_frame_base64
            if ',' in img_data:
                img_data = img_data.split(',')[1]
            
            filename = f"refraction_ai_{uuid.uuid4().hex[:8]}.jpg"
            file_path = os.path.join("uploads/refraction", filename)
            
            with open(file_path, "wb") as f:
                f.write(base64.b64decode(img_data))
            
            image_path = file_path
            
            # Simpan ke Table RiwayatTes
            new_record = models.RiwayatTes(
                user_id=int(test_request.user_id) if test_request.user_id.isdigit() else 0,
                image_path=image_path,
                hasil_klasifikasi=results.predicted_class,
                estimasi_dioptri=results.visual_acuity, # Simpan snellen fraction sebagai estimasi sementara
                confidence_score=results.confidence,
                catatan_admin=f"AI Recommendation: {results.recommendation}"
            )
            db.add(new_record)
            db.commit()
            db.refresh(new_record)
            logger.info(f"[AI DB] Success saved record ID {new_record.id} for user {test_request.user_id}")
            
        except Exception as e:
            logger.error(f"Failed to save AI record to database: {e}")
            db.rollback()

        logger.info(f"[AI Log] User {test_request.user_id} Result: {results.predicted_class} (Conf: {results.confidence})")
        
        # 4. Kirim Notifikasi ke User (Gunakan data user_id dari request)
        # Note: Kita asumsikan user_id valid dari Mobile. 
        # Untuk keamanan lebih, idealnya matching dengan current_user, tapi V2 didesain fleksibel.
        try:
            target_user_id = int(test_request.user_id) if test_request.user_id.isdigit() else None
            if target_user_id:
                create_notification(
                    db, 
                    target_user_id, 
                    "AI Refraksi Selesai! 🤖", 
                    f"Hasil deteksi AI: {results.predicted_class}. Akurasi: {int(results.confidence*100)}%."
                )
        except Exception:
            pass

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

@router_v2.post("/detect-distance", response_model=schemas.RefractionAIDetectDistanceResponse)
async def detect_face_distance(
    request: schemas.RefractionAIDetectDistanceRequest
):
    """
    Endpoint untuk deteksi wajah & mata secara real-time guna menghitung jarak (Pixel IPD).
    Digunakan sebagai feedback untuk user saat melakukan tes Snellen.
    """
    return FaceDetectionService.detect_face_and_eyes(request.image)
