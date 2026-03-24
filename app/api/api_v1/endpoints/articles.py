from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
import locale

from app import models, schemas
from app.db.session import get_db

router = APIRouter()

# Fungsi helper untuk format tanggal Indonesia
def format_indo_date(dt):
    # Nama bulan manual karena locale sistem mungkin bukan ID
    months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"]
    return f"{dt.day} {months[dt.month-1]} {dt.year}"

@router.get("/", response_model=List[schemas.ArticleResponse])
async def get_articles(db: Session = Depends(get_db)):
    articles = db.query(models.Article).order_by(models.Article.created_at.desc()).all()
    
    # Transform data agar sesuai schema (imageUrl, date string)
    result = []
    for art in articles:
        result.append({
            "id": art.id,
            "title": art.title,
            "imageUrl": art.image_url,
            "category": art.category or "Edukasi",
            "date": format_indo_date(art.created_at),
            "content": art.content
        })
    return result
