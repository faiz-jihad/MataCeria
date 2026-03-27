from app.db.session import SessionLocal
from app.models import User, UserRole, JenisKelamin, JenjangPendidikan, StatusPekerjaan
from app.core.security import hash_password

def create_test_user():
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == "test@user.com").first()
        if not user:
            user = User(
                nama_lengkap="Test User",
                email="test@user.com",
                hashed_password=hash_password("user123"),
                umur=25,
                kelamin=JenisKelamin.LAKI_LAKI,
                jenjang_pendidikan=JenjangPendidikan.D4_S1,
                status_pekerjaan=StatusPekerjaan.BEKERJA,
                role=UserRole.USER
            )
            db.add(user)
            db.commit()
            print("Test user created.")
        else:
            print("Test user already exists.")
    finally:
        db.close()

if __name__ == "__main__":
    create_test_user()
