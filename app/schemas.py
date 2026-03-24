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

class UserResponse(BaseModel):
    id: int
    nama_lengkap: str
    email: EmailStr
    umur: int
    kelamin: str
    role: str
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
class ArticleResponse(BaseModel):
    id: int
    title: str
    content: str
    imageUrl: Optional[str] = Field(None, alias="image_url")
    category: Optional[str] = "Tips Kesehatan"
    date: str # Terformat untuk Flutter (e.g. "24 Mar 2026")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

# --- EMERGENCY SCHEMAS ---
class EmergencyContactResponse(BaseModel):
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
