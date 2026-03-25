import logging
from sqlalchemy.orm import Session
from app import models

logger = logging.getLogger(__name__)

def log_activity(db: Session, user_id: int, activity_type: str, description: str = None):
    try:
        new_activity = models.UserActivity(
            user_id=user_id,
            activity_type=activity_type,
            description=description
        )
        db.add(new_activity)
        db.commit()
    except Exception as e:
        logger.error(f"Gagal mencatat aktivitas: {str(e)}")
        db.rollback()

def create_notification(db: Session, user_id: int, title: str, message: str):
    try:
        new_notification = models.Notification(
            user_id=user_id,
            title=title,
            message=message,
            is_read=False
        )
        db.add(new_notification)
        db.commit()
    except Exception as e:
        logger.error(f"Gagal membuat notifikasi: {str(e)}")
        db.rollback()
