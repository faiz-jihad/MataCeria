from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from app.core.security import get_current_admin
from sqlalchemy.orm import Session
from typing import List
import os
import shutil
import uuid

from app import models, schemas
from app.db.session import get_db
from app.utils import create_notification
from app.services.research_service import ResearchService

router = APIRouter()
UPLOAD_ART_DIR = "uploads/articles"
os.makedirs(UPLOAD_ART_DIR, exist_ok=True)

# Fungsi helper untuk format tanggal Indonesia
def format_indo_date(dt):
    # Nama bulan manual karena locale sistem mungkin bukan ID
    months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"]
    return f"{dt.day} {months[dt.month-1]} {dt.year}"

@router.get("", response_model=List[schemas.ArticleResponse])
async def get_articles(db: Session = Depends(get_db)):
    articles = db.query(models.Article).order_by(models.Article.created_at.desc()).all()
    
    # Transform for date formatting (required by the response schema)
    for art in articles:
        setattr(art, "date", format_indo_date(art.created_at))
    return articles
@router.post("", response_model=schemas.ArticleResponse, status_code=status.HTTP_201_CREATED)
async def create_article(
    article: schemas.ArticleCreate, 
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    new_article = models.Article(**article.model_dump())
    db.add(new_article)
    db.commit()
    db.refresh(new_article)
    
    # Notifikasi ke semua user
    users = db.query(models.User).filter(models.User.role == models.UserRole.USER).all()
    for user in users:
        create_notification(
            db, 
            user.id, 
            "Artikel Baru! 📖", 
            f"Admin baru saja mengunggah artikel: '{new_article.title}'. Yuk baca sekarang!"
        )

    # Transform for response
    return {
        **new_article.__dict__,
        "imageUrl": new_article.image_url,
        "date": format_indo_date(new_article.created_at)
    }

@router.put("/{article_id}", response_model=schemas.ArticleResponse)
async def update_article(
    article_id: int,
    article_data: schemas.ArticleUpdate,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    article = db.query(models.Article).filter(models.Article.id == article_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Artikel tidak ditemukan")
    
    update_data = article_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(article, key, value)
    
    db.commit()
    db.refresh(article)
    
    return {
        **article.__dict__,
        "imageUrl": article.image_url,
        "date": format_indo_date(article.created_at)
    }

@router.delete("/{article_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_article(
    article_id: int,
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    article = db.query(models.Article).filter(models.Article.id == article_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Artikel tidak ditemukan")
    
    db.delete(article)
    db.commit()
    return None

@router.post("/upload-image")
async def upload_article_image(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    admin: models.User = Depends(get_current_admin)
):
    """
    Upload gambar dari perangkat untuk digunakan di artikel.
    Mengembalikan path yang bisa diakses publik.
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File harus berupa gambar")
        
    file_extension = os.path.splitext(file.filename)[1]
    filename = f"art_{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(UPLOAD_ART_DIR, filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    # Kembalikan URL yang bisa diakses (Base URL ditangani Flutter, kita kasih path-nya)
    # Misal: "uploads/articles/art_xxxx.jpg"
    return {"message": "Gambar berhasil diunggah", "image_url": file_path}

@router.get("/research-search")
async def search_medical_research(
    query: str,
    db: Session = Depends(get_db)
):
    """
    Cari informasi medis dari API eksternal (ClinicalTrials, WHO, PubMed, FDA)
    berdasarkan query pencarian artikel.
    """
    if not query or len(query) < 3:
        return {"status": "success", "results": "Query terlalu pendek."}
        
    research_results = ResearchService.get_research_context(query)
    
    return {
        "status": "success",
        "query": query,
        "results": research_results or "Tidak ada hasil penelitian medis yang relevan ditemukan."
    }
