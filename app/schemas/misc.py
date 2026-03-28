from pydantic import BaseModel, Field, ConfigDict, computed_field
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
    category: Optional[str] = "Tips Kesehatan"
    date: str # Terformat untuk Flutter (e.g. "24 Mar 2026")

    @computed_field
    @property
    def imageUrl(self) -> Optional[str]:
        return self.image_url

    @computed_field
    @property
    def shareUrl(self) -> Optional[str]:
        return self.share_url

    model_config = ConfigDict(from_attributes=True)

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

    @computed_field
    @property
    def name(self) -> str:
        return self.nama

    @computed_field
    @property
    def phone(self) -> str:
        return self.nomor_telepon

    @computed_field
    @property
    def nomorTelepon(self) -> str:
        return self.nomor_telepon

    @computed_field
    @property
    def category(self) -> str:
        return self.kategori

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
