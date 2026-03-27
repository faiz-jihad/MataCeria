from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from app.core.config import settings

engine = create_engine(
    settings.SQLALCHEMY_DATABASE_URL,
    pool_size=10, 
    max_overflow=20, 
    pool_pre_ping=True, # Membantu koneksi stabil setelah database restart
    pool_recycle=3600   # Recycle koneksi setiap 1 jam
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
