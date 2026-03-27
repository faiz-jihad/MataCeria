from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship
import datetime
from app.models.base import Base

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
