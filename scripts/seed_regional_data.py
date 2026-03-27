import sys
import os

# Add the current directory to sys.path
sys.path.append(os.getcwd())

from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app import models

def seed_data():
    db = SessionLocal()
    try:
        print("Seeding Full Regional Emergency Contacts (44 entries)...")
        
        emergency_data = [
            # --- DKI JAKARTA ---
            {"nama": "JEC @ Kedoya", "nomor_telepon": "0804-122-1000", "kategori": "RS Mata (UGD 24J)", "region": "Jakarta", "address": "Jl. Terusan Arjuna Utara No.1, Kedoya, Jakarta Barat. WA: 0877-2922-1000"},
            {"nama": "JEC @ Menteng", "nomor_telepon": "0804-122-1000", "kategori": "RS Mata", "region": "Jakarta", "address": "Jl. Cik Ditiro No.46, Menteng, Jakarta Pusat"},
            {"nama": "JEC @ Tambora", "nomor_telepon": "021-29221000", "kategori": "RS Mata (BPJS)", "region": "Jakarta", "address": "Jl. Imam Mahbud, Duri Pulo, Jakarta Pusat"},
            {"nama": "JEC @ Tanjung Priok", "nomor_telepon": "021-29221000", "kategori": "RS Mata", "region": "Jakarta", "address": "Jl. Kebon Bawang, Tanjung Priok, Jakarta Utara"},
            {"nama": "JEC @ Cibubur", "nomor_telepon": "0804-122-1000", "kategori": "RS Mata (BPJS)", "region": "Jakarta/Bekasi", "address": "Jl. Alternatif Cibubur, Jatikarya"},
            {"nama": "RS Mata SMEC Jakarta", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Jakarta", "address": "Jl. Prof. DR. Soepomo No.70-B, Tebet, Jakarta Selatan. WA: 0811-901-1234"},
            {"nama": "RS Mata SMEC Patria", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Jakarta", "address": "Jl. Cendrawasih No.1, Palmerah, Jakarta Barat"},
            {"nama": "RS Mata SMEC Rawamangun", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Jakarta", "address": "Jl. Pemuda No.36, Rawamangun, Jakarta Timur"},
            {"nama": "RS Mata Aini", "nomor_telepon": "021-5732241", "kategori": "RS Mata", "region": "Jakarta", "address": "RS Jakarta Lt.3, Jl. Jend. Sudirman No.Kav 49. WA: 081585512655"},
            {"nama": "KMN EyeCare @ Kemayoran", "nomor_telepon": "021-654-66", "kategori": "Klinik Mata", "region": "Jakarta", "address": "The Mansion Kemayoran, Fontana Tower Lt. 18-19"},
            {"nama": "KMN EyeCare @ Lebak Bulus", "nomor_telepon": "021-7516688", "kategori": "Klinik Mata", "region": "Jakarta", "address": "Jl. R.A. Kartini No.99, Lebak Bulus, Jakarta Selatan"},
            {"nama": "Ciputra SMG Eye Clinic Jakarta", "nomor_telepon": "021-29888137", "kategori": "Klinik Mata", "region": "Jakarta", "address": "Lotte Shopping Avenue Fl.5, Kuningan"},

            # --- JAWA BARAT & BANTEN ---
            {"nama": "RS Mata Cicendo Bandung", "nomor_telepon": "022-4231280", "kategori": "RS Mata Nasional", "region": "Bandung", "address": "Jl. Cicendo No.4, Bandung. WA: 0811-2001-005"},
            {"nama": "Klinik Utama Mata Cicendo Garut II", "nomor_telepon": "022-4231280", "kategori": "Klinik Mata", "region": "Garut", "address": "Jl. Otista No.275, Garut"},
            {"nama": "RS Mata Achmad Wardi", "nomor_telepon": "0254-7915503", "kategori": "RS Mata", "region": "Serang", "address": "Lontarbaru, Serang, Banten"},
            {"nama": "SMEC Bekasi", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Bekasi", "address": "Ruko Festival No.1-3, Jl. Sultan Agung Km 27"},
            {"nama": "JEC @ Bekasi", "nomor_telepon": "0804-122-1000", "kategori": "RS Mata", "region": "Bekasi", "address": "Jl. Jendral Sudirman No.5, Bekasi. WA: 0877-2922-1000"},
            {"nama": "SMEC Depok", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Depok", "address": "Jl. Tole Iskandar No.101, Sukamaju"},

            # --- JAWA TENGAH & DIY ---
            {"nama": "RS Mata Dr. Yap", "nomor_telepon": "0274-584423", "kategori": "RS Mata", "region": "Yogyakarta", "address": "Jl. Cik Di Tiro No.5, Yogyakarta. WA: 0888-0281-1256"},
            {"nama": "Candi Eye Center", "nomor_telepon": "024-8501426", "kategori": "Klinik Mata (JEC)", "region": "Semarang", "address": "Jl. Dokter Wahidin FHG No.2, Semarang"},
            {"nama": "RS Mata Solo", "nomor_telepon": "0271-713333", "kategori": "RS Mata", "region": "Solo", "address": "Jl. Adi Sucipto No.169, Surakarta"},
            {"nama": "KMN EyeCare Semarang", "nomor_telepon": "024-3511111", "kategori": "Klinik Mata", "region": "Semarang", "address": "Jl. Ahmad Yani, Karangkidul"},
            {"nama": "SMEC Kudus", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Kudus", "address": "Jl. Raya Pati-Kudus Km 5"},

            # --- JAWA TIMUR ---
            {"nama": "RS Mata Masyarakat Jatim", "nomor_telepon": "031-820-10000", "kategori": "RS Mata (UGD 24J)", "region": "Surabaya", "address": "Jl. Ketintang Baru Selatan I No.1, Surabaya. WA: 085161519442"},
            {"nama": "RS Mata Undaan", "nomor_telepon": "031-5343806", "kategori": "RS Mata", "region": "Surabaya", "address": "Jl. Undaan Kulon No.19, Surabaya (6 Lantai)"},
            {"nama": "Ciputra SMG Eye Clinic Surabaya", "nomor_telepon": "031-51201000", "kategori": "Klinik Mata", "region": "Surabaya", "address": "SkyLoft SOHO Fl.8 Ciputra World"},
            {"nama": "SMEC Malang", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Malang", "address": "Jl. Sunandar Priyo Sudarmo No.55"},

            # --- BALI ---
            {"nama": "RS Mata Bali Mandara", "nomor_telepon": "0361-243350", "kategori": "RS Mata (UGD 24J)", "region": "Bali", "address": "Jl. Angsoka No.8, Denpasar. WA: 0816-1325-8888"},

            # --- SUMATERA ---
            {"nama": "SMEC Medan", "nomor_telepon": "0811-6202-020", "kategori": "RS Mata", "region": "Medan", "address": "Jl. Iskandar Muda No.278-280, Petisah Tengah"},
            {"nama": "SMEC Lubuk Pakam", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Deli Serdang", "address": "Ruko The Premier, Jl. Ahmad Yani No.88"},
            {"nama": "SMEC Siantar", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Pematang Siantar", "address": "Jl. Sisingamangaraja, Suka Dame"},
            {"nama": "Klinik Mata SMEC Kabanjahe", "nomor_telepon": "0804-1-227788", "kategori": "Klinik Mata", "region": "Karo", "address": "Jl. Perwira No.1-2, Padang Mas"},
            {"nama": "RSU Bunda Padang", "nomor_telepon": "0751-23164", "kategori": "RS Umum (Eye Center)", "region": "Padang", "address": "Jl. Proklamasi, Ganting, Padang (Sejak 1967)"},
            {"nama": "SMEC Pekanbaru", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Pekanbaru", "address": "Jl. Arifin Ahmad No.92, Sidomulyo Timur"},
            {"nama": "SMEC Tanjung Pinang", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Tanjungpinang", "address": "Jl. W.R. Supratman No.1A, Batu 11"},
            {"nama": "RSIA Az-Zahra Palembang", "nomor_telepon": "0711-822723", "kategori": "RSIA (Eye Care)", "region": "Palembang", "address": "Bukit Sangkal, Palembang (Sejak 2001)"},

            # --- KALIMANTAN ---
            {"nama": "Singkawang Eye Center", "nomor_telepon": "0821-4805-7119", "kategori": "Klinik Mata", "region": "Singkawang", "address": "Jl. R.A. Kartini, Singkawang Tengah"},
            {"nama": "SMEC Balikpapan", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Balikpapan", "address": "Ruko Sentra Eropa Blok AA 2B No.16"},
            {"nama": "SMEC Samarinda", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Samarinda", "address": "Jl. Letjen Suprapto No.11 B.01"},

            # --- SULAWESI ---
            {"nama": "RS Mata Prov Sulut", "nomor_telepon": "0431-851309", "kategori": "RS Mata (Kelas C)", "region": "Manado", "address": "Jl. W. Z. Johanis No.I, Manado"},
            {"nama": "SMEC Palu", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Palu", "address": "Jl. DR. Abdurrahman Saleh No.92"},
            {"nama": "RSK Mata Makassar", "nomor_telepon": "0411-873747", "kategori": "RS Mata", "region": "Makassar", "address": "Jl. Wijaya Kusuma Raya No.19"},
            {"nama": "SMEC Gorontalo", "nomor_telepon": "0804-1-227788", "kategori": "RS Mata", "region": "Gorontalo", "address": "Jl. Dr. Hi. Medi Botutihe SE No.24"},
        ]
        
        for data in emergency_data:
            exists = db.query(models.EmergencyContact).filter(models.EmergencyContact.nama == data["nama"]).first()
            if not exists:
                contact = models.EmergencyContact(**data)
                db.add(contact)
            else:
                # Update existing
                for key, value in data.items():
                    setattr(exists, key, value)

        db.commit()
        print(f"Data Seeding COMPLETED. Total unique contacts seeded/updated: {len(emergency_data)}")
        
    except Exception as e:
        db.rollback()
        print(f"Error during seeding: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_data()
