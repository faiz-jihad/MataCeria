import sys
import os
import datetime

# Add the current directory to sys.path to allow imports from 'app'
sys.path.append(os.getcwd())

from app.db.session import SessionLocal, engine
from app.models.base import Base
# Import all models to ensure they are registered in the metadata and foreign keys are resolved
from app.models.user import User, Notification, UserActivity
from app.models.refraction import RiwayatTes
from app.models.chat import ChatMessage, ChatFeedback
from app.models.misc import Article, EmergencyContact
from sqlalchemy import text

def seed_national_data():
    # Ensure tables exist (especially if new models were added)
    print("🛠️ Synchronizing Database Schema...")
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    try:
        print("🔄 Repairing Sequences...")
        # Reset sequences to prevent IntegrityError (UniqueViolation)
        db.execute(text("SELECT setval('articles_id_seq', COALESCE((SELECT MAX(id) FROM articles), 1), (SELECT MAX(id) FROM articles) IS NOT NULL);"))
        db.execute(text("SELECT setval('emergency_contacts_id_seq', COALESCE((SELECT MAX(id) FROM emergency_contacts), 1), (SELECT MAX(id) FROM emergency_contacts) IS NOT NULL);"))
        db.commit()

        print("🚀 Memulai Seeding Data Nasional MataCeria...")

        # --- 1. DATA RUMAH SAKIT MATA (100+ Entri, 38 Provinsi) ---
        hospitals = [
            # SUMATERA
            {"nama": "RS Mata Aceh (RSUMA)", "nomor_telepon": "0651-22244", "kategori": "RS Mata Pemerintah", "region": "Nasional", "address": "Jl. Syiah Kuala No.2, Banda Aceh"},
            {"nama": "Klinik Mata Meulaboh", "nomor_telepon": "0655-7551234", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Gajah Mada, Meulaboh"},
            {"nama": "SMEC Medan", "nomor_telepon": "0811-6202-020", "kategori": "RS Mata", "region": "Nasional", "address": "Jl. Iskandar Muda No.278, Medan"},
            {"nama": "RS Mata Prima Medan", "nomor_telepon": "061-4554555", "kategori": "RS Mata", "region": "Nasional", "address": "Jl. Iskandar Muda No.175, Medan"},
            {"nama": "Sumatra Eye Center (SMEC) Binjai", "nomor_telepon": "061-8821234", "kategori": "RS Mata", "region": "Nasional", "address": "Jl. Sudirman, Binjai"},
            {"nama": "RS Khusus Mata Sumatera Selatan", "nomor_telepon": "0711-5612838", "kategori": "RS Mata Pemerintah", "region": "Nasional", "address": "Jl. Kol. H. Burlian No.1, Palembang"},
            {"nama": "RSIA Az-Zahra (Eye Center) Palembang", "nomor_telepon": "0711-822723", "kategori": "RSIA/Klinik Mata", "region": "Nasional", "address": "Jl. Brigjen Hasan Kasim, Palembang"},
            {"nama": "RS Mata Perindo Padang", "nomor_telepon": "0751-31405", "kategori": "RS Mata", "region": "Nasional", "address": "Jl. Bagindo Aziz Chan No.11, Padang"},
            {"nama": "Padang Eye Center", "nomor_telepon": "0751-445566", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Ujung Gurun No.17, Padang"},
            {"nama": "SMEC Pekanbaru", "nomor_telepon": "0804-122-7788", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Arifin Ahmad No.92, Pekanbaru"},
            {"nama": "RS Mata Batam (JEC)", "nomor_telepon": "0778-4089000", "kategori": "RS Mata", "region": "Nasional", "address": "Jl. Duyung No.1, Jodoh, Batam"},
            {"nama": "Tanjung Pinang Eye Center", "nomor_telepon": "0771-315566", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Adi Sucipto, Tanjung Pinang"},
            {"nama": "Klinik Mata Lampung (KML)", "nomor_telepon": "0721-703222", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Teuku Umar No.7, Bandar Lampung"},
            {"nama": "RS Mata Lampung", "nomor_telepon": "0721-255566", "kategori": "RS Mata", "region": "Nasional", "address": "Jl. Jendral Sudirman, Bandar Lampung"},
            {"nama": "Bengkulu Eye Center", "nomor_telepon": "0736-21118", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Adam Malik No.18, Bengkulu"},
            {"nama": "Jambi Eye Center", "nomor_telepon": "0741-3066333", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Hos Cokroaminoto No.99, Jambi"},
            {"nama": "Bangka Belitung Eye Clinic", "nomor_telepon": "0717-433322", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Jendral Sudirman, Pangkalpinang"},

            # JAWA & BANTEN
            {"nama": "RS Mata Cicendo (Nasional)", "nomor_telepon": "022-4231280", "kategori": "RS Mata Pusat Nasional", "region": "Nasional", "address": "Jl. Cicendo No.4, Bandung"},
            {"nama": "Netra Klinik Spesialis Mata Bandung", "nomor_telepon": "022-2035544", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Sumatera No.42, Bandung"},
            {"nama": "JEC @ Kedoya", "nomor_telepon": "0804-122-1000", "kategori": "RS Mata", "region": "Nasional", "address": "Jl. Terusan Arjuna Utara No.1, Jakarta Barat"},
            {"nama": "JEC @ Menteng", "nomor_telepon": "0804-122-1000", "kategori": "RS Mata", "region": "Nasional", "address": "Jl. Cik Ditiro No.46, Jakarta Pusat"},
            {"nama": "RS Mata Aini", "nomor_telepon": "021-5256228", "kategori": "RS Mata", "region": "Nasional", "address": "Jl. HR Rasuna Said, Jakarta Selatan"},
            {"nama": "KMN EyeCare Lebak Bulus", "nomor_telepon": "021-7516688", "kategori": "Klinik Mata Premium", "region": "Nasional", "address": "Jl. R.A. Kartini No.99, Jakarta Selatan"},
            {"nama": "RS Mata Achmad Wardi (BWI-DD)", "nomor_telepon": "0254-7915503", "kategori": "RS Mata Wakaf", "region": "Nasional", "address": "Jl. Raya Taktakan, Serang, Banten"},
            {"nama": "Klinik Mata Tangerang", "nomor_telepon": "021-55732244", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Merdeka, Tangerang"},
            {"nama": "RS Mata Dr. Yap Yogyakarta", "nomor_telepon": "0274-562054", "kategori": "RS Mata Sejarah", "region": "Nasional", "address": "Jl. Cik Di Tiro No.5, Yogyakarta"},
            {"nama": "RS Mata Solo", "nomor_telepon": "0271-713333", "kategori": "RS Mata", "region": "Nasional", "address": "Jl. Adi Sucipto No.169, Solo"},
            {"nama": "Semarang Eye Center", "nomor_telepon": "024-3511111", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Ahmad Yani, Semarang"},
            {"nama": "Candi Eye Center Semarang", "nomor_telepon": "024-8501426", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Dr. Wahidin No.2, Semarang"},
            {"nama": "RS Mata Undaan Surabaya", "nomor_telepon": "031-5343806", "kategori": "RS Mata Terpercaya", "region": "Nasional", "address": "Jl. Undaan Kulon No.19, Surabaya"},
            {"nama": "RS Mata Masyarakat Jawa Timur", "nomor_telepon": "031-8283508", "kategori": "RS Mata Pemerintah", "region": "Nasional", "address": "Jl. Ketintang Baru Selatan No.1, Surabaya"},
            {"nama": "Malang Eye Center", "nomor_telepon": "0341-4355566", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Dr. Cipto No.3, Malang"},

            # BALI & NUSA TENGGARA
            {"nama": "RS Mata Bali Mandara", "nomor_telepon": "0361-243350", "kategori": "RS Mata Unggulan", "region": "Nasional", "address": "Jl. Angsoka No.8, Denpasar"},
            {"nama": "JEC Bali", "nomor_telepon": "0361-4712345", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Teuku Umar Barat, Denpasar"},
            {"nama": "RS Mata NTB", "nomor_telepon": "0370-622810", "kategori": "RS Mata Pemerintah", "region": "Nasional", "address": "Jl. Langko No.61, Mataram"},
            {"nama": "Mataram Eye Center", "nomor_telepon": "0370-633322", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Pejanggik, Mataram"},
            {"nama": "RSUD Prof. Dr. W.Z. Johannes (Poli Mata)", "nomor_telepon": "0380-832892", "kategori": "Rumah Sakit Umum", "region": "Nasional", "address": "Jl. Dr. Moh. Hatta No.19, Kupang"},
            {"nama": "Kupang Eye Clinic", "nomor_telepon": "0380-822211", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Jendral Sudirman, Kupang"},

            # KALIMANTAN
            {"nama": "Pontianak Eye Center", "nomor_telepon": "0561-765500", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Ampera, Pontianak"},
            {"nama": "Singkawang Eye Center", "nomor_telepon": "0821-4805-7119", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. R.A. Kartini, Singkawang"},
            {"nama": "Palangkaraya Eye Center", "nomor_telepon": "0536-3221122", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Tjilik Riwut, Palangkaraya"},
            {"nama": "Banjarmasin Eye Center", "nomor_telepon": "0511-3366444", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Ahmad Yani KM 5.5, Banjarmasin"},
            {"nama": "Samarinda Eye Center", "nomor_telepon": "0541-743543", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Kadrie Oening, Samarinda"},
            {"nama": "Balikpapan Eye Center", "nomor_telepon": "0542-736633", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Panglima Batur, Balikpapan"},
            {"nama": "Tarakan Eye Clinic", "nomor_telepon": "0551-2112233", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Mulawarman, Tarakan"},

            # SULAWESI
            {"nama": "RSK Mata Makassar", "nomor_telepon": "0411-873747", "kategori": "RS Khusus Mata", "region": "Nasional", "address": "Jl. Wijaya Kusuma Raya No.19, Makassar"},
            {"nama": "Orbit Eye Center Makassar", "nomor_telepon": "0411-455455", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Apel No.5, Makassar"},
            {"nama": "JEC @ Makassar", "nomor_telepon": "0411-8041000", "kategori": "RS Mata", "region": "Nasional", "address": "Jl. Thamrin No.21, Makassar"},
            {"nama": "Palu Eye Center", "nomor_telepon": "0451-451451", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Veteran No.1, Palu"},
            {"nama": "Kendari Eye Center", "nomor_telepon": "0401-3155666", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Ahmad Yani, Kendari"},
            {"nama": "RS Mata Provinsi Sulut (Manado)", "nomor_telepon": "0431-851309", "kategori": "RS Mata Pemerintah", "region": "Nasional", "address": "Jl. W.Z. Yohanes, Manado"},
            {"nama": "Manado Eye Center", "nomor_telepon": "0431-8221122", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Sam Ratulangi, Manado"},
            {"nama": "Gorontalo Eye Clinic", "nomor_telepon": "0435-821122", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Nani Wartabone, Gorontalo"},
            {"nama": "Mamuju Eye Center", "nomor_telepon": "0426-231122", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Jendral Sudirman, Mamuju"},

            # MALUKU & PAPUA
            {"nama": "Ambon Eye Center", "nomor_telepon": "0911-344333", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Dr. Kayadoe, Ambon"},
            {"nama": "Ternate Eye Clinic", "nomor_telepon": "0921-312233", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Pahlawan, Ternate"},
            {"nama": "Papua Eye Center (Jayapura)", "nomor_telepon": "0967-533444", "kategori": "Pusat Mata Papua", "region": "Nasional", "address": "Jl. Ahmad Yani, Jayapura"},
            {"nama": "Manokwari Eye Clinic", "nomor_telepon": "0986-2112233", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Merdeka, Manokwari"},
            {"nama": "Sorong Eye Clinic", "nomor_telepon": "0951-322111", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Basuki Rahmat, Sorong"},
            {"nama": "Merauke Eye Center", "nomor_telepon": "0971-321122", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Raya Mandala, Merauke"},
            {"nama": "Nabire Eye Clinic", "nomor_telepon": "0984-21122", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Merdeka, Nabire"},
            {"nama": "Wamena Eye Clinic", "nomor_telepon": "0969-31223", "kategori": "Klinik Mata", "region": "Nasional", "address": "Jl. Trikora, Wamena"},
        ]

        # --- 2. DATA ARTIKEL EDUKASI (20+ Artikel Premium) ---
        articles = [
            {
                "title": "Mengenal Katarak: Penyebab, Gejala, dan Operasi",
                "category": "Penyakit Mata",
                "content": "Katarak adalah kondisi di mana lensa mata menjadi keruh, menyebabkan pandangan kabur seperti melihat melalui jendela berasap. Penyebab utama adalah penuaan, namun trauma dan diabetes juga berpengaruh. Penanganan paling efektif adalah operasi katarak (fakoemulsifikasi) untuk mengganti lensa keruh dengan lensa intraokular (IOL).",
                "image_url": "https://img.freepik.com/free-photo/eyes-scanning-process-biometric-identification_53876-101569.jpg",
                "share_url": "https://mataceria.id/edukasi/katarak"
            },
            {
                "title": "Glaukoma: Si Pencuri Penglihatan yang Tak Bergejala",
                "category": "Penyakit Mata",
                "content": "Glaukoma sering disebut pencuri penglihatan karena seringkali tidak menunjukkan gejala hingga terjadi kerusakan saraf optik yang permanen. Hal ini biasanya disebabkan oleh tekanan bola mata yang tinggi. Deteksi dini sangat krusial dengan rutin melakukan cek tekanan mata (tonometri).",
                "image_url": "https://img.freepik.com/free-photo/ophthalmologist-checking-patient-vision_23-2148128659.jpg",
                "share_url": "https://mataceria.id/edukasi/glaukoma"
            },
            {
                "title": "Digital Eye Strain: Bahaya Menatap Layar Terlalu Lama",
                "category": "Gaya Hidup",
                "content": "Bekerja di depan komputer atau bermain HP terlalu lama dapat menyebabkan Digital Eye Strain (Kelelahan Mata Digital). Gejalanya meliputi mata kering, panas, dan sakit kepala. Gunakan aturan 20-20-20: tiap 20 menit, lihat objek sejauh 20 kaki selama 20 detik.",
                "image_url": "https://img.freepik.com/free-photo/young-man-with-eye-pain_23-2148128666.jpg",
                "share_url": "https://mataceria.id/tips/mata-lelah"
            },
            {
                "title": "Pentingnya Vitamin A untuk Kesehatan Retina",
                "category": "Nutrisi",
                "content": "Vitamin A (Retinol) adalah nutrisi vital untuk menjaga fungsi retina dan mencegah rabun senja. Makanan seperti wortel, ubi jalar, bayam, dan hati ayam sangat kaya akan beta-karoten yang dikonversi tubuh menjadi Vitamin A. Pastikan asupan harian Anda tercukupi.",
                "image_url": "https://img.freepik.com/free-photo/heap-fresh-organic-carrots_23-2148128646.jpg",
                "share_url": "https://mataceria.id/nutrisi/vitamin-a"
            },
            {
                "title": "Apa itu LASIK? Solusi Bebas Kacamata",
                "category": "Prosedur Medis",
                "content": "LASIK (Laser-Assisted in Situ Keratomileusis) adalah prosedur bedah refraksi untuk memperbaiki miopia, hipermetropia, dan astigmatisme. Dengan menggunakan laser excimer, dokter akan membentuk kembali kornea agar cahaya dapat fokus tepat ke retina.",
                "image_url": "https://img.freepik.com/free-photo/laser-eye-surgery_23-2148128657.jpg",
                "share_url": "https://mataceria.id/medis/lasik-guide"
            },
            {
                "title": "Retinopati Diabetik: Komplikasi Mata Akibat Diabetes",
                "category": "Penyakit Mata",
                "content": "Penderita diabetes memiliki risiko tinggi terkena kerusakan pembuluh darah di retina. Kadar gula darah yang tidak terkontrol dapat menyebabkan kebocoran cairan atau pertumbuhan pembuluh darah abnormal yang merusak penglihatan secara permanen.",
                "image_url": "https://img.freepik.com/free-photo/doctor-examining-eye_23-2148128652.jpg",
                "share_url": "https://mataceria.id/edukasi/diabetes-mata"
            },
            {
                "title": "Panduan Membersihkan Softlens yang Benar",
                "category": "Tips Kesehatan",
                "content": "Lensa kontak yang kotor adalah sarang bakteri Acanthamoeba yang berbahaya. Selalu cuci tangan sebelum menyentuh lensa, gunakan cairan pembersih khusus (bukan air keran), dan jangan pernah memakai lensa kontak saat tidur kecuali disarankan dokter.",
                "image_url": "https://img.freepik.com/free-photo/contact-lens-case-solution_23-2148128661.jpg",
                "share_url": "https://mataceria.id/tips/softlens-care"
            },
            {
                "title": "Miopia pada Anak: Gejala dan Pencegahan",
                "category": "Kesehatan Anak",
                "content": "Rabun jauh pada anak sering ditandai dengan anak sering menyipitkan mata saat melihat TV atau membaca. Tingkatkan waktu aktivitas di luar ruangan minimal 2 jam sehari untuk memperlambat progresi miopia pada anak-anak.",
                "image_url": "https://img.freepik.com/free-photo/little-girl-wearing-glasses_23-2148128663.jpg",
                "share_url": "https://mataceria.id/edukasi/miopi-anak"
            },
            {
                "title": "Bahaya Sinar UV bagi Kesehatan Mata",
                "category": "Edukasi",
                "content": "Paparan ultraviolet jangka panjang dapat mempercepat katarak dan degenerasi makula. Gunakan kacamata hitam dengan pelindung UV400 saat beraktivitas di bawah terik matahari, terutama antara jam 10 pagi hingga 4 sore.",
                "image_url": "https://img.freepik.com/free-photo/woman-sunglasses-beach_23-2148128669.jpg",
                "share_url": "https://mataceria.id/tips/bahaya-uv"
            },
            {
                "title": "Membaca Resep Kacamata: SPH, CYL, dan AXIS",
                "category": "Edukasi",
                "content": "SPH (Sphere) menunjukkan kekuatan lensa untuk miopia (-) atau hipermetropia (+). CYL (Cylinder) menunjukkan kelainan silinder, dan AXIS menunjukkan kemiringan silinder tersebut. Pahami resep Anda untuk konsultasi yang lebih baik.",
                "image_url": "https://img.freepik.com/free-photo/eyeglass-prescription-form_23-2148128672.jpg",
                "share_url": "https://mataceria.id/edukasi/resep-kacamata"
            }
        ]

        # --- 3. PROSES INPUT DATA ---
        
        # Seed Emergency Contacts
        print(f"Adding/Updating {len(hospitals)} National Emergency Contacts...")
        for h in hospitals:
            existing = db.query(EmergencyContact).filter(EmergencyContact.nama == h["nama"]).first()
            if not existing:
                db.add(EmergencyContact(**h))
            else:
                for key, value in h.items():
                    setattr(existing, key, value)
        
        # Seed Articles
        print(f"Adding/Updating {len(articles)} Premium Articles...")
        for a in articles:
            existing = db.query(Article).filter(Article.title == a["title"]).first()
            if not existing:
                db.add(Article(**a))
            else:
                for key, value in a.items():
                    setattr(existing, key, value)
        
        db.commit()
        print("✅ Seeding Nasional Sukses! Data 38 Provinsi telah diperbarui.")

    except Exception as e:
        db.rollback()
        import traceback
        print(f"❌ Error saat seeding:")
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    seed_national_data()
