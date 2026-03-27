from app.db.session import SessionLocal
from app.models import User, Notification
import requests

def verify():
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == "test@user.com").first()
        if not user:
            print("User not found.")
            return

        notifs = db.query(Notification).filter(Notification.user_id == user.id).all()
        print(f"Total notifications for {user.email}: {len(notifs)}")
        for n in notifs:
            print(f"- [{n.created_at}] {n.title}: {n.message}")

    finally:
        db.close()

if __name__ == "__main__":
    verify()
