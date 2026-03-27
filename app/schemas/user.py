from pydantic import BaseModel, EmailStr, ConfigDict
from typing import Optional, List
import datetime

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

class UserActivityResponse(BaseModel):
    id: int
    activity_type: str
    description: Optional[str] = None
    created_at: datetime.datetime

    model_config = ConfigDict(from_attributes=True)

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
