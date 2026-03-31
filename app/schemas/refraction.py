from pydantic import BaseModel, ConfigDict
from typing import Optional, List
import datetime

class RiwayatTesResponse(BaseModel):
    id: int
    waktu_tes: datetime.datetime
    hasil_klasifikasi: str
    estimasi_dioptri: str
    confidence_score: float
    image_path: str

    model_config = ConfigDict(from_attributes=True)



class RefractionDeviceInfo(BaseModel):
    screen_ppi: float
    screen_width_px: int

class RefractionRawData(BaseModel):
    avg_distance_cm: float
    smallest_row_read: int
    missed_chars: int
    astigmatism_found: Optional[bool] = False # True if user sees distorted lines

class RefractionTestRequest(BaseModel):
    user_id: str
    test_type: str # "distance_vision" or "near_vision"
    device_info: RefractionDeviceInfo
    raw_data: RefractionRawData

class RefractionTestResult(BaseModel):
    visual_acuity: str
    snellen_decimal: float
    category: str # e.g. "Mild Impairment"
    condition_category: str # e.g. "Miopia", "Hipermetropia", "Astigmatisme"
    is_cylinder: bool = False
    recommendation: str

class RefractionTestResponse(BaseModel):
    status: str
    results: RefractionTestResult

# V2 AI REFRACTION API SCHEMAS
class RefractionAIDeviceInfo(BaseModel):
    screen_ppi: float

class RefractionAISnellenData(BaseModel):
    avg_distance_cm: float
    smallest_row_read: int
    missed_chars: int
    response_time: float
    test_type: str = "distance_vision" # "distance_vision" or "near_vision"
    astigmatism_found: bool = False

class RefractionAIImageData(BaseModel):
    eye_frame_base64: str

class RefractionAIRequest(BaseModel):
    user_id: str
    device_info: RefractionAIDeviceInfo
    snellen_data: RefractionAISnellenData
    image_data: RefractionAIImageData

class RefractionAIResultDetail(BaseModel):
    visual_acuity: str
    snellen_decimal: float
    predicted_class: str
    condition_category: str # "Miopia", "Hipermetropia", "Astigmatisme"
    is_cylinder: bool = False
    confidence: float
    recommendation: str
    action_required: bool
    can_consult_chatbot: bool
    source: str

class RefractionAIResponse(BaseModel):
    status: str
    results: RefractionAIResultDetail

# V2 DISTANCE DETECTION SCHEMAS
class RefractionAIDetectDistanceRequest(BaseModel):
    image: str # Base64 string
    device_info: Optional[dict] = None

class RefractionAILandmarks(BaseModel):
    left_eye: List[float] # [x, y]
    right_eye: List[float] # [x, y]
    bounding_box: List[float] # [x, y, w, h]

class RefractionAIDetectDistanceResponse(BaseModel):
    success: bool
    pixel_ipd: float
    face_found: bool
    landmarks: Optional[RefractionAILandmarks] = None
    message: str

class RefractionHistoryItem(BaseModel):
    id: int
    created_at: datetime.datetime
    image_url: str
    predicted_class: str
    confidence: float
    results: RefractionTestResult

class RefractionHistoryResponse(BaseModel):
    status: str = "success"
    data: List[RefractionHistoryItem]
