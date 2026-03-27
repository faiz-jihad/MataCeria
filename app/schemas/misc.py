from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
import datetime

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
    region: Optional[str] = "Nasional"
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class EmergencyContactCreate(EmergencyContactBase):
    pass

class EmergencyContactUpdate(BaseModel):
    nama: Optional[str] = None
    nomor_telepon: Optional[str] = None
    kategori: Optional[str] = None
    region: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class EmergencyContactResponse(EmergencyContactBase):
    id: int
    nama: str
    nomor_telepon: str
    kategori: str

    model_config = ConfigDict(from_attributes=True)

# --- NOTIFICATION SCHEMAS ---
class NotificationBase(BaseModel):
    title: str
    message: str

class NotificationCreate(NotificationBase):
    pass

class NotificationResponse(NotificationBase):
    id: int
    is_read: bool
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)
