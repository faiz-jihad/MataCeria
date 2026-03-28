from sqlalchemy import Column, Integer, String, Enum, DateTime, Boolean, JSON, Text, ForeignKey
from sqlalchemy.orm import relationship
import datetime
from app.models.base import Base, UserRole, JenisKelamin, JenjangPendidikan, StatusPekerjaan

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    nama_lengkap = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    
    # Data Demografis
    umur = Column(Integer, nullable=False)
    kelamin = Column(Enum(JenisKelamin), nullable=False)
    jenjang_pendidikan = Column(Enum(JenjangPendidikan), nullable=False)
    status_pekerjaan = Column(Enum(StatusPekerjaan), nullable=False)
    
    # Data Profil & Keamanan (Sync Baru)
    profile_image = Column(String, nullable=True) # Path to image
    is_2fa_enabled = Column(Boolean, default=False)
    phone = Column(String, nullable=True)

    # Data Kesehatan Mata (Vision Data)
    vision_concerns = Column(JSON, nullable=True) # List of concerns
    allergies = Column(String, nullable=True)
    medical_history = Column(Text, nullable=True)
    vision_type = Column(String, nullable=True) # e.g. "Miopia", "Normal"
    
    # Hak Akses (Role)
    role = Column(Enum(UserRole), default=UserRole.USER)
    
    # Timestamp
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Token untuk Reset Password
    reset_token = Column(String, nullable=True)

    # Relasi
    riwayat_tes = relationship("RiwayatTes", back_populates="pemilik", cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="pemilik", cascade="all, delete-orphan")
    activities = relationship("UserActivity", back_populates="pemilik", cascade="all, delete-orphan")


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String, nullable=False)
    message = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    pemilik = relationship("User", back_populates="notifications")


class UserActivity(Base):
    __tablename__ = "user_activities"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    activity_type = Column(String, nullable=False) 
    description = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    pemilik = relationship("User", back_populates="activities")
