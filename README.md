# MataCeria Backend 👁️✨

[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![TensorFlow](https://img.shields.io/badge/TensorFlow-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white)](https://www.tensorflow.org/)
[![Google Gemini](https://img.shields.io/badge/Gemini-8E75C2?style=for-the-badge&logo=google-gemini&logoColor=white)](https://ai.google.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)

Sistem backend cerdas berbasis AI untuk **MataCeria** — aplikasi asisten kesehatan mata pintar dan deteksi dini refraksi (Miopia). Dirancang dengan arsitektur modular menggunakan **FastAPI**, backend ini menghadirkan pengalaman AI yang responsif dan skalabel.

---

## 🚀 Fitur Utama & Pembaruan Terbaru
- 🧬 **AI Eye Refraction (Hybrid V2)**: Gabungan model **TensorFlow** (60%) dan **Rule-based Snellen** (40%) untuk akurasi klinis maksimal.
- 💬 **Medical Research RAG (V3)**: Chatbot pintar yang terintegrasi dengan database medis dunia:
    - **ClinicalTrials.gov**: Uji klinis mata terbaru.
    - **WHO GHO**: Statistik kesehatan mata global.
    - **OpenFDA**: Izin alat kesehatan terbaru (LASIK, Lensa).
    - **PubMed**: Jurnal ilmiah kedokteran terkini.
- 🔔 **Notifikasi Otomatis**: Sistem broadcast notifikasi untuk Registrasi, Hasil Tes, dan Pembaruan Artikel.
- 🛡️ **Keamanan & Throttling**: Perlindungan dari abuse menggunakan **SlowAPI** (Rate Limiting) pada seluruh endpoint sensitif.
- 🌐 **Remote Access**: Deployment instan menggunakan **Cloudflare Tunnel** (akses publik tanpa port-forwarding).

---

## 📋 Prasyarat Sistem (Wajib Instal!)

Sebelum memulai, pastikan komputer Bapak atau rekan tim sudah menginstal:

1.  **Docker Desktop** (Paling Penting): Digunakan untuk menjalankan database PostgreSQL dan aplikasi API secara otomatis tanpa perlu instalasi manual.
    *   [Download di sini](https://www.docker.com/products/docker-desktop/) (Windows/Mac/Linux).
2.  **Git**: Untuk mendownload source code dan melakukan push/pull dari repositori GitHub.
    *   [Download di sini](https://git-scm.com/downloads).
3.  **Google AI API Key**: Diperlukan untuk mengakses otak AI Gemini.
    *   Dapatkan gratis di: [Google AI Studio](https://aistudio.google.com/).

---

## 🚀 Cara Instalasi & Menjalankan

### 1. Pengaturan File Environment
Buat file `.env` di root folder (gunakan `.env.example` sebagai referensi):
```env
DATABASE_URL=postgresql://user_admin:password_kuat@db:5432/db_refraksi
GEMINI_API_KEY=AIzaSy... (Masukkan Key Bapak di sini)
SECRET_KEY=... (Gunakan string acak panjang untuk JWT)
```

### 2. Jalankan Seluruh Sistem (Docker)
Cukup satu perintah saja:
```bash
docker-compose up --build -d
```
*Tunggu hingga proses build selesai. Docker akan menyiapkan Database dan API secara otomatis.*

### 3. Masukkan Data Awal (Seeding) - WAJIB!
Agar aplikasi tidak kosong, masukkan data awal dengan perintah:
```bash
# Isi Data Dasar (Admin & RS)
docker exec -it fastapi_refraksi python seed_data.py

# Isi Artikel Resmi (Scraped Data)
docker exec -it fastapi_refraksi python seed_articles.py
```

---

## 🌐 Cara Akses Publik & HP (Cloudflare)
Agar aplikasi Flutter di HP bisa mengakses API Bapak, gunakan link Tunnel:
1.  Jalankan perintah ini: `docker logs cloudflared_refraksi`.
2.  Cari link yang berakhiran `.trycloudflare.com`.
3.  Gunakan link tersebut sebagai BASE_URL di aplikasi Flutter Bapak.

---

## 📖 Dokumentasi API & Database
- **Swagger UI (Daftar Endpoint)**: `http://localhost:8000/docs`.
- **Ekspor DB**: `docker exec -t postgres_refraksi pg_dump -U user_admin db_refraksi > backup.sql`.
- **Impor DB**: `cat backup.sql | docker exec -i postgres_refraksi psql -U user_admin -d db_refraksi`.

Detailed maintenance guide in `database_guide.md`.

---

Developed with ❤️ for better eye health.
**M a t a C e r i a**
