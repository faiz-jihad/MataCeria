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

def notify_all_users(db: Session, title: str, message: str):
    """
    Kirim notifikasi ke semua user yang memiliki role 'user'.
    """
    try:
        users = db.query(models.User).filter(models.User.role == models.UserRole.USER).all()
        for user in users:
            new_notification = models.Notification(
                user_id=user.id,
                title=title,
                message=message,
                is_read=False
            )
            db.add(new_notification)
        db.commit()
        logger.info(f"Broadcast notifikasi '{title}' ke {len(users)} user berhasil.")
    except Exception as e:
        logger.error(f"Gagal broadcast notifikasi: {str(e)}")
        db.rollback()
