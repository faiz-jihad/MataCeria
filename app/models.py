from sqlalchemy import Column, Integer, String, Enum, DateTime, Float, ForeignKey, Text, Boolean, JSON
from sqlalchemy.orm import declarative_base, relationship
import enum
import datetime

# Base class untuk semua tabel
Base = declarative_base()

# ==========================================
# 1. DEFINISI ENUM (PILIHAN DROPDOWN)
# ==========================================
class UserRole(str, enum.Enum):
    USER = "user"
    ADMIN = "admin"

class JenisKelamin(str, enum.Enum):
    LAKI_LAKI = "Laki-laki"
    PEREMPUAN = "Perempuan"

class JenjangPendidikan(str, enum.Enum):
    SD = "SD"
    SMP = "SMP"
    SMA = "SMA"
    D3 = "D3"
    D4_S1 = "D4/S1"
    S2_S3 = "S2/S3"
    LAINNYA = "Lainnya"

class StatusPekerjaan(str, enum.Enum):
    PELAJAR_MAHASISWA = "Pelajar/Mahasiswa"
    BEKERJA = "Bekerja"
    TIDAK_BEKERJA = "Tidak Bekerja"


# ==========================================
# 2. MODEL TABEL: USERS (Data Pasien & Admin)
# ==========================================
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


# ==========================================
# 3. MODEL TABEL: RIWAYAT TES (Hasil AI)
# ==========================================
class RiwayatTes(Base):
    __tablename__ = "riwayat_tes"

    id = Column(Integer, primary_key=True, index=True)
    
    # Foreign Key ke tabel users
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    # Data Gambar & Hasil Klasifikasi AI
    image_path = Column(String, nullable=False)        # Misal: "uploads/images/mata_faiz_1.jpg"
    hasil_klasifikasi = Column(String, nullable=False) # Misal: "Miopia Ringan"
    estimasi_dioptri = Column(String, nullable=False)  # Misal: "-1.00 s/d -1.50"
    confidence_score = Column(Float, nullable=False)   # Misal: 0.95 (95% yakin)
    
    # Catatan Opsional dari Dokter/Admin
    catatan_admin = Column(Text, nullable=True)
    
    # Timestamp
    waktu_tes = Column(DateTime, default=datetime.datetime.utcnow)

    # Relasi balik ke tabel User
    pemilik = relationship("User", back_populates="riwayat_tes")


# ==========================================
# 4. MODEL TABEL: NOTIFIKASI
# ==========================================
class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String, nullable=False)
    message = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    pemilik = relationship("User", back_populates="notifications")


# ==========================================
# 5. MODEL TABEL: ARTIKEL / TIPS
# ==========================================
class Article(Base):
    __tablename__ = "articles"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    content = Column(Text, nullable=False)
    image_url = Column(String, nullable=True)
    category = Column(String, nullable=True, default="Umum")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)


# ==========================================
# 6. MODEL TABEL: KONTAK DARURAT
# ==========================================
class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id = Column(Integer, primary_key=True, index=True)
    nama = Column(String, nullable=False)
    nomor_telepon = Column(String, nullable=False)
    kategori = Column(String, nullable=False)


# ==========================================
# 7. MODEL TABEL: AKTIVITAS USER
# ==========================================
class UserActivity(Base):
    __tablename__ = "user_activities"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    activity_type = Column(String, nullable=False) 
    description = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    pemilik = relationship("User", back_populates="activities")


# ==========================================
# 8. MODEL TABEL: CHAT MESSAGES
# ==========================================
class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    session_id = Column(String, nullable=True)
    role = Column(String, nullable=False) # "user" atau "bot" (disesuaikan dengan flutter)
    message = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    metadata_json = Column(JSON, nullable=True) # Untuk suggestions dll
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    pemilik = relationship("User")


# ==========================================
# 9. MODEL TABEL: CHAT FEEDBACK
# ==========================================
class ChatFeedback(Base):
    __tablename__ = "chat_feedback"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    message_id = Column(Integer, ForeignKey("chat_messages.id", ondelete="CASCADE"), nullable=True)
    rating = Column(Integer, nullable=False) 
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    pemilik = relationship("User")
