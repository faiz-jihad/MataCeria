from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Optional, List
import datetime

# --- AUTH SCHEMAS ---

class UserCreate(BaseModel):
    nama_lengkap: str
    email: EmailStr
    password: str
    umur: int
    kelamin: str
    jenjang_pendidikan: str
    status_pekerjaan: str

class UserUpdate(BaseModel):
    nama_lengkap: Optional[str] = None
    umur: Optional[int] = None
    kelamin: Optional[str] = None
    jenjang_pendidikan: Optional[str] = None
    status_pekerjaan: Optional[str] = None
    phone_number: Optional[str] = None
    vision_concerns: Optional[List[str]] = None
    allergies: Optional[str] = None
    medical_history: Optional[str] = None
    vision_type: Optional[str] = None

class UserSecurityUpdate(BaseModel):
    is_2fa_enabled: bool

class UserResponse(BaseModel):
    id: int
    nama_lengkap: str
    email: EmailStr
    umur: int
    kelamin: str
    role: str
    profile_image: Optional[str] = None
    is_2fa_enabled: bool = False
    phone_number: Optional[str] = None
    vision_concerns: Optional[List[str]] = None
    allergies: Optional[str] = None
    medical_history: Optional[str] = None
    vision_type: Optional[str] = None
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)

# --- TEST SCHEMAS ---
class RiwayatTesResponse(BaseModel):
    id: int
    waktu_tes: datetime.datetime
    hasil_klasifikasi: str
    estimasi_dioptri: str
    confidence_score: float
    image_path: str

    model_config = ConfigDict(from_attributes=True)

# --- ARTICLE SCHEMAS ---
class ArticleBase(BaseModel):
    title: str
    content: str
    image_url: Optional[str] = None
    share_url: Optional[str] = None
    category: Optional[str] = "Tips Kesehatan"

class ArticleCreate(ArticleBase):
    pass

class ArticleUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    image_url: Optional[str] = None
    share_url: Optional[str] = None
    category: Optional[str] = None

class ArticleResponse(ArticleBase):
    id: int
    title: str
    content: str
    imageUrl: Optional[str] = Field(None, alias="image_url")
    shareUrl: Optional[str] = Field(None, alias="share_url")
    category: Optional[str] = "Tips Kesehatan"
    date: str # Terformat untuk Flutter (e.g. "24 Mar 2026")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

# --- EMERGENCY SCHEMAS ---
class EmergencyContactBase(BaseModel):
    nama: str
    nomor_telepon: str
    kategori: str

class EmergencyContactCreate(EmergencyContactBase):
    pass

class EmergencyContactUpdate(BaseModel):
    nama: Optional[str] = None
    nomor_telepon: Optional[str] = None
    kategori: Optional[str] = None

class EmergencyContactResponse(EmergencyContactBase):
    id: int
    nama: str
    nomor_telepon: str
    kategori: str

    model_config = ConfigDict(from_attributes=True)

# --- NOTIFICATION SCHEMAS ---
class NotificationResponse(BaseModel):
    id: int
    title: str
    message: str
    is_read: bool
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)

# --- CHAT SCHEMAS ---
class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None
    refraction_result: Optional[str] = None

class BotResponseDetail(BaseModel):
    id: int
    role: str = "bot"
    message: str
    created_at: datetime.datetime
    metadata: Optional[dict] = None

class ChatResponse(BaseModel):
    session_id: str
    bot_response: BotResponseDetail

class ChatMessageResponse(BaseModel):
    id: int
    role: str
    message: str
    created_at: datetime.datetime
    metadata: Optional[dict] = Field(None, alias="metadata_json")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

class ChatUnreadCountResponse(BaseModel):
    unread_count: int

class ChatFeedbackRequest(BaseModel):
    message_id: int
    rating: int
    comment: Optional[str] = None

# --- ACTIVITY SCHEMAS ---
class UserActivityResponse(BaseModel):
    id: int
    activity_type: str
    description: Optional[str] = None
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)

# --- TOKEN & PASSWORD SCHEMAS ---
class Token(BaseModel):
    access_token: str
    token_type: str
    role: str

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str

# --- REFRACTION TEST SCHEMAS ---
class RefractionDeviceInfo(BaseModel):
    screen_ppi: float
    screen_width_px: int

class RefractionRawData(BaseModel):
    avg_distance_cm: float
    smallest_row_read: int
    missed_chars: int

class RefractionTestRequest(BaseModel):
    user_id: str
    test_type: str
    device_info: RefractionDeviceInfo
    raw_data: RefractionRawData

class RefractionTestResult(BaseModel):
    visual_acuity: str
    snellen_decimal: float
    category: str
    recommendation: str

class RefractionTestResponse(BaseModel):
    status: str
    results: RefractionTestResult

# --- V2 AI REFRACTION API SCHEMAS ---
class RefractionAIDeviceInfo(BaseModel):
    screen_ppi: float

class RefractionAISnellenData(BaseModel):
    avg_distance_cm: float
    smallest_row_read: int
    missed_chars: int
    response_time: float

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
    confidence: float
    source: str

class RefractionAIResponse(BaseModel):
    status: str
    results: RefractionAIResultDetail
