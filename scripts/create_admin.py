import sys
from app.db.session import SessionLocal
from app.models import User, UserRole, JenisKelamin, JenjangPendidikan, StatusPekerjaan
from app.core.security import hash_password

def create_admin(email, password, name):
    db = SessionLocal()
    try:
        # Check if user exists
        user = db.query(User).filter(User.email == email).first()
        if user:
            print(f"Error: User dengan email {email} sudah terdaftar.")
            return

        new_admin = User(
            nama_lengkap=name,
            email=email,
            hashed_password=hash_password(password),
            umur=30,
            kelamin=JenisKelamin.LAKI_LAKI,
            jenjang_pendidikan=JenjangPendidikan.D4_S1,
            status_pekerjaan=StatusPekerjaan.BEKERJA,
            role=UserRole.ADMIN
        )
        db.add(new_admin)
        db.commit()
        print(f"Sukses! Admin {name} ({email}) berhasil dibuat.")
    except Exception as e:
        db.rollback()
        print(f"Terjadi kesalahan: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Penggunaan: python create_admin.py <email> <password> <nama_lengkap>")
        print("Contoh: python create_admin.py admin2@example.com rahasia123 'Admin Baru'")
    else:
        create_admin(sys.argv[1], sys.argv[2], sys.argv[3])
