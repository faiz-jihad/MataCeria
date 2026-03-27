from sqlalchemy import Column, Integer, String, Text, DateTime, Float
import datetime
from app.models.base import Base

class Article(Base):
    __tablename__ = "articles"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    content = Column(Text, nullable=False)
    image_url = Column(String, nullable=True)
    share_url = Column(String, nullable=True) # Link to web article
    category = Column(String, nullable=True, default="Umum")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)


class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id = Column(Integer, primary_key=True, index=True)
    nama = Column(String, nullable=False)
    nomor_telepon = Column(String, nullable=False)
    kategori = Column(String, nullable=False)
    region = Column(String, nullable=True, default="Nasional")
    address = Column(Text, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
