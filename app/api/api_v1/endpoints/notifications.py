from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app import models, schemas
from app.db.session import get_db
from app.core.security import get_current_user

router = APIRouter()

@router.get("/", response_model=List[schemas.NotificationResponse])
async def get_notifications(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    notifications = db.query(models.Notification)\
        .filter(models.Notification.user_id == current_user.id)\
        .order_by(models.Notification.created_at.desc())\
        .all()
    return notifications

@router.put("/{notification_id}/read", response_model=schemas.NotificationResponse)
async def mark_notification_as_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    notification = db.query(models.Notification)\
        .filter(models.Notification.id == notification_id, models.Notification.user_id == current_user.id)\
        .first()
        
    if not notification:
        raise HTTPException(status_code=404, detail="Notifikasi tidak ditemukan")
        
    notification.is_read = True
    db.commit()
    db.refresh(notification)
    return notification

@router.put("/read-all")
async def mark_all_notifications_as_read(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    db.query(models.Notification)\
        .filter(models.Notification.user_id == current_user.id, models.Notification.is_read == False)\
        .update({"is_read": True}, synchronize_session=False)
    db.commit()
    return {"message": "Semua notifikasi ditandai sebagai terbaca"}

@router.delete("/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    notification = db.query(models.Notification)\
        .filter(models.Notification.id == notification_id, models.Notification.user_id == current_user.id)\
        .first()
        
    if not notification:
        raise HTTPException(status_code=404, detail="Notifikasi tidak ditemukan")
        
    db.delete(notification)
    db.commit()
    return None
