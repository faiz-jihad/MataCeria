from sqlalchemy.orm import Session
from app.db.session import SessionLocal, engine
from app import models
from app.core.security import hash_password
import datetime
import random

def seed_data():
    # PENTING: Re-create semua tabel untuk memastikan kolom baru terdeteksi
    print("Refreshing database schema (Re-creating tables)...")
    models.Base.metadata.drop_all(bind=engine)
    models.Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    # 1. TAMBAHKAN USER ADMIN
    admin_user = models.User(
        nama_lengkap="Administrator Utama",
        email="admin@refraksi.com",
        hashed_password=hash_password("admin123"),
        umur=35,
        kelamin=models.JenisKelamin.LAKI_LAKI,
        jenjang_pendidikan=models.JenjangPendidikan.S2_S3,
        status_pekerjaan=models.StatusPekerjaan.BEKERJA,
        role=models.UserRole.ADMIN,
        profile_image="uploads/profiles/default_admin.png",
        is_2fa_enabled=True,
        phone="08123456789",
        vision_type="Normal",
        vision_concerns=["Lelah", "Kering"]
    )
    db.add(admin_user)
    print("Admin user created with sync fields.")

    # 2. TAMBAHKAN ARTIKEL EDUKASI MATA
    raw_articles = [
        {
            "title": "5 Cara Menjaga Kesehatan Mata di Depan Layar",
            "content": "Gunakan aturan 20-20-20. Setiap 20 menit, lihatlah sesuatu yang berjarak 20 kaki selama 20 detik. Atur tingkat kecerahan layar agar tidak terlalu silau. Gunakan kacamata anti-radiasi blue light. Perbanyak kedipan mata untuk menghindari mata kering. Pastikan jarak pandang minimal 50-60 cm.",
            "image_url": "https://img.freepik.com/free-photo/healthy-food-vegetables_23-2148849764.jpg",
            "share_url": "https://mataceria.id/tips/layar",
            "category": "Tips Kesehatan"
        },
        {
            "title": "Mengenal Rabun Jauh (Miopi) pada Anak",
            "content": "Miopi pada anak seringkali tidak disadari. Gejalanya termasuk menyipitkan mata saat melihat TV, duduk terlalu dekat dengan buku, sering mengucek mata, dan sulit fokus pada papan tulis di sekolah. Segera periksakan anak ke dokter mata jika gejala ini muncul.",
            "image_url": "https://img.freepik.com/free-photo/human-eye-anatomy_23-2148894180.jpg",
            "share_url": "https://mataceria.id/edukasi/miopi-anak",
            "category": "Edukasi"
        },
        {
            "title": "Nutrisi Terbaik untuk Melawan Mata Minus",
            "content": "Lutein dan Zeaxanthin adalah zat warna alami pada bayam dan kale yang melindungi retina. Omega-3 dari ikan membantu kelembapan mata. Vitamin A dari wortel dan ubi jalar mencegah rabun senja. Makanlah makanan bergizi untuk kesehatan mata jangka panjang.",
            "image_url": "https://img.freepik.com/free-photo/vegetables-flat-lay_23-2148849764.jpg",
            "share_url": "https://mataceria.id/nutrisi/mata-minus",
            "category": "Nutrisi"
        },
        {
            "title": "Bahaya Bermain Ponsel Sebelum Tidur",
            "content": "Sinar biru dari layar gadget menekan produksi melatonin, hormon tidur. Selain mata lelah, hal ini mengganggu siklus tidur. Cobalah untuk menjauhkan ponsel 1 jam sebelum tidur agar mata dan otak beristirahat maksimal.",
            "image_url": "https://img.freepik.com/free-photo/man-using-phone-bed-dark_23-2148906644.jpg",
            "share_url": "https://mataceria.id/gaya-hidup/hp-tidur",
            "category": "Gaya Hidup"
        },
        {
            "title": "Apa itu Astigmatisme (Mata Silinder)?",
            "content": "Astigmatisme terjadi karena kelengkungan kornea tidak rata. Cahaya tidak jatuh tepat pada satu titik di retina. Penglihatan menjadi kabur atau berbayang. Kacamata silinder atau lensa kontak khusus bisa membantu mengoreksi pandangan ini.",
            "image_url": "https://img.freepik.com/free-photo/vision-concept_23-2148894190.jpg",
            "share_url": "https://mataceria.id/edukasi/silinder",
            "category": "Edukasi"
        }
    ]

    # Tambahkan variasi "Unformatif"
    unformatted_content = "Ini adalah artikel dengan teks yang sangat panjang dan tidak terformat untuk menguji bagaimana UI Flutter Anda menangani overflow atau teks yang berlebih tanpa paragraf yang jelas. " * 50
    raw_articles.append({
        "title": "TEST UI: Artikel Teks Sangat Panjang (Unformatif)",
        "content": unformatted_content,
        "image_url": "https://img.freepik.com/free-photo/vision-concept_23-2148894190.jpg",
        "share_url": "https://mataceria.id/testing/long-text",
        "category": "Testing"
    })

    # Duplikasi data untuk mencapai jumlah "Banyak" (misal 30 artikel)
    all_articles = []
    for i in range(30):
        base = random.choice(raw_articles)
        all_articles.append(models.Article(
            title=f"{base['title']} #{i+1}",
            content=base['content'],
            image_url=base['image_url'],
            share_url=base['share_url'],
            category=base['category'],
            created_at=datetime.datetime.now() - datetime.timedelta(days=i)
        ))

    db.add_all(all_articles)
    print(f"{len(all_articles)} Articles seeded with share_urls.")

    # 3. TAMBAHKAN KONTAK DARURAT
    emergency_data = [
        {"nama": "RS Mata Cicendo", "nomor_telepon": "(022) 4231280", "kategori": "Pusat"},
        {"nama": "JEC Kedoya", "nomor_telepon": "(021) 29221000", "kategori": "Swasta"},
        {"nama": "KMN Jakarta", "nomor_telepon": "(021) 7516688", "kategori": "Klinik"},
        {"nama": "RS Mata Bali", "nomor_telepon": "(0361) 243481", "kategori": "Daerah"},
        {"nama": "RS Mata Undaan", "nomor_telepon": "(031) 5343806", "kategori": "Daerah"},
        {"nama": "RS Mata Dr. Yap", "nomor_telepon": "(0274) 562054", "kategori": "Sejarah"}
    ]

    for data in emergency_data:
        db.add(models.EmergencyContact(**data))
    
    print(f"{len(emergency_data)} Emergency contacts seeded.")

    # 4. TAMBAHKAN NOTIFIKASI DEFAULT
    db.commit() # Commit agar ID admin_user terisi (1)
    
    notif = models.Notification(
        user_id=admin_user.id,
        title="Sistem Siap!",
        message="Database telah di-refresh dengan 30 artikel baru. Selamat melakukan pengujian!",
        is_read=False
    )
    db.add(notif)
    db.commit()

    db.close()
    print("Database seeding and schema refresh completed successfully!")

if __name__ == "__main__":
    seed_data()
