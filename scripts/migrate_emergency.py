from sqlalchemy import text
from app.db.session import SessionLocal

def migrate():
    db = SessionLocal()
    try:
        print("Migrating emergency_contacts table...")
        db.execute(text("ALTER TABLE emergency_contacts ADD COLUMN IF NOT EXISTS region VARCHAR DEFAULT 'Nasional'"))
        db.execute(text("ALTER TABLE emergency_contacts ADD COLUMN IF NOT EXISTS address TEXT"))
        db.execute(text("ALTER TABLE emergency_contacts ADD COLUMN IF NOT EXISTS latitude FLOAT"))
        db.execute(text("ALTER TABLE emergency_contacts ADD COLUMN IF NOT EXISTS longitude FLOAT"))
        db.commit()
        print("Migration SUCCESSFUL.")
    except Exception as e:
        print(f"Migration FAILED: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    migrate()
