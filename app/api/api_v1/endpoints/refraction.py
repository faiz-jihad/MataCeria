from fastapi import APIRouter, Depends, HTTPException, status
import logging

from app.schemas import RefractionTestRequest, RefractionTestResponse
from app.services.refraction_service import RefractionService

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/test", response_model=RefractionTestResponse, status_code=status.HTTP_200_OK)
async def submit_refraction_test(request: RefractionTestRequest):
    """
    Endpoint for Medical Refraction Screening based on Visual Acuity (Snellen).
    """
    # 1. Input Validation
    # Near vision distance validation (e.g., must be between 30 and 50 cm)
    if request.test_type == "near_vision":
        if not (30.0 <= request.raw_data.avg_distance_cm <= 50.0):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Untuk near vision, jarak harus 30-50 cm. Diterima: {request.raw_data.avg_distance_cm} cm."
            )
            
    # Validate logical non-negative/zero values
    if request.device_info.screen_ppi <= 0 or request.device_info.screen_width_px <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Informasi device (PPI dan Lebar Layar) harus bernilai lebih dari 0."
        )
        
    if request.raw_data.avg_distance_cm <= 0 or \
       request.raw_data.smallest_row_read <= 0 or \
       request.raw_data.missed_chars < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Data raw tes (jarak, baris terkecil baca, missed chars) tidak valid (0 atau negatif)."
        )
    
    # 2. Process Screening logic via Service
    try:
        results = RefractionService.process_screening(
            raw_data=request.raw_data,
            device_info=request.device_info
        )
        
        # 3. Return JSON response
        return RefractionTestResponse(
            status="success",
            results=results
        )
    
    except Exception as e:
        logger.error(f"Error processing refraction test: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Terjadi kesalahan saat memproses tes refraksi."
        )
