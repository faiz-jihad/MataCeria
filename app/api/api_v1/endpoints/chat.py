from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import logging
import uuid
import datetime

from app import models, schemas
from app.db.session import get_db
from app.core.security import get_current_user
from app.services import ai_service
from app.utils import log_activity

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/unread-count", response_model=schemas.ChatUnreadCountResponse)
async def get_chat_unread_count(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    count = db.query(models.ChatMessage)\
        .filter(models.ChatMessage.user_id == current_user.id, models.ChatMessage.is_read == False)\
        .count()
    return {"unread_count": count}

@router.post("/send", response_model=schemas.ChatResponse)
async def chat_with_ai(
    request: schemas.ChatRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    # 1. Tentukan Session ID
    session_id = request.session_id or str(uuid.uuid4())
    
    logger.info(f"User {current_user.email} bertanya ke AI di sesi {session_id}")
    
    # 2. Ambil 5 artikel terbaru saja untuk RAG (Hemat Token)
    articles = db.query(models.Article).order_by(models.Article.created_at.desc()).limit(5).all()
    
    # 3. Panggil Gemini
    # Kita sertakan refraction_result jika ada untuk context tambahan
    user_query = request.message
    if request.refraction_result:
        user_query = f"[Hasil Tes: {request.refraction_result}] {user_query}"
        
    reply = ai_service.get_chat_response(user_query, articles)
    
    # 4. Simpan pesan User ke DB
    user_msg = models.ChatMessage(
        user_id=current_user.id, 
        session_id=session_id,
        role="user", 
        message=request.message, 
        is_read=True
    )
    
    # 5. Metadata untuk balasan Bot
    metadata = {
        "type": "default",
        "suggestions": ["Cara mencegah myopia", "Kapan harus ke dokter?", "Nutrisi untuk mata"]
    }
    
    # 6. Simpan pesan Bot ke DB
    bot_msg = models.ChatMessage(
        user_id=current_user.id, 
        session_id=session_id,
        role="bot", 
        message=reply, 
        is_read=True,
        metadata_json=metadata
    )
    
    db.add_all([user_msg, bot_msg])
    db.commit()
    db.refresh(bot_msg)

    log_activity(db, current_user.id, "Chat AI", f"Bertanya: {request.message[:20]}...")

    # 7. Return sesuai struktur yang diminta Flutter
    # Kita gunakan dictionary agar pydantic memproses Alias pilihan imageUrl/image_url dll
    return {
        "session_id": session_id,
        "bot_response": {
            "id": bot_msg.id,
            "session_id": session_id,
            "role": "bot",
            "message": reply,
            "created_at": bot_msg.created_at,
            "metadata": metadata
        }
    }

@router.get("/history", response_model=List[schemas.ChatMessageResponse])
@router.get("/messages", response_model=List[schemas.ChatMessageResponse])
async def get_chat_history(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    history = db.query(models.ChatMessage)\
        .filter(models.ChatMessage.user_id == current_user.id)\
        .order_by(models.ChatMessage.created_at.asc())\
        .all()
    
    # Tandai pesan bot sebagai terbaca
    db.query(models.ChatMessage)\
        .filter(models.ChatMessage.user_id == current_user.id, models.ChatMessage.role == "bot")\
        .update({"is_read": True})
    db.commit()
    
    # Data dikembalikan sebagai list of schemas.ChatMessageResponse
    # Metadata akan diambil dari metadata_json (via Alias di Pydantic)
    return history

@router.post("/feedback")
async def send_chat_feedback(
    request: schemas.ChatFeedbackRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    new_feedback = models.ChatFeedback(
        user_id=current_user.id,
        message_id=request.message_id,
        rating=request.rating,
        comment=request.comment
    )
    db.add(new_feedback)
    db.commit()
    log_activity(db, current_user.id, "Chat Feedback", f"Rating: {request.rating} bintang")
    return {"message": "Terima kasih atas feedback Anda!"}
