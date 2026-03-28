# MataCeria Backend 👁️✨

[![MataCeria CI](https://github.com/faiz-jihad/MataCeria/actions/workflows/ci.yml/badge.svg)](https://github.com/faiz-jihad/MataCeria/actions)
[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)

Sistem backend cerdas berbasis AI untuk **MataCeria** — aplikasi asisten kesehatan mata pintar dan deteksi dini refraksi (Miopia). Dirancang dengan arsitektur **Clean & Modular**, backend ini menghadirkan pengalaman AI yang responsif dan skalabel untuk skala produksi.

---

## 🚀 Fitur Utama & Pembaruan Produksi

- 🧬 **Hybrid AI Refraction (V2)**: Gabungan model **TensorFlow** (Local) dan **Gemini Vision 1.5 Flash** (Fallback) untuk hasil analisis mata yang dinamis dan akurat.
- 📱 **Mobile-First Synchronization**: 
    - **Nested History JSON**: Struktur ringkas untuk sinkronisasi riwayat pemeriksaan yang lebih cepat di Flutter.
    - **Partial Profile Sync**: Pembaruan profil yang fleksibel (PATCH behavior) untuk data kependudukan dan riwayat kesehatan mata.
- 💬 **AI Consultation (Gemini v2)**: Chatbot medis berbasis LLM terintegrasi untuk bimbingan kesehatan mata.
- 🗺️ **National Data Hub**: Database 65+ rumah sakit mata nasional dan 20+ artikel kesehatan mata premium siap guna.
- 🛡️ **Production Ready**: 
    - **Modular Structure**: Pemisahan Model, Schema, dan Endpoint untuk maintainability tinggi.
    - **Security Headers**: Proteksi bawaan terhadap XSS, Clickjacking, dan HSTS.
    - **Rate Limiting**: Pencegahan abuse API menggunakan SlowAPI.
- 🔄 **CI/CD Pipeline**: Integrasi otomatis melalui **GitHub Actions** untuk linting, testing, dan build verification.

---

## 📂 Struktur Proyek Baru

```text
.
├── app/                # Core application (FastAPI)
│   ├── api/            # API Routers (V1 & V2)
│   ├── core/           # Config, Security, Logging
│   ├── db/             # Database session & models init
│   ├── models/         # Modular SQLAlchemy Models
│   ├── schemas/        # Modular Pydantic Schemas
│   └── services/       # Business Logic & AI Inference
├── scripts/            # Utility scripts (Seeding, Migrasi, Tools)
├── tests/              # Automated API & Unit Tests
├── docs/               # Technical Guides & API Endpoints
├── uploads/            # Persistent storage for images
└── Docker-compose.yaml # Production deployment config
```

---

## 🚀 Cara Instalasi & Menjalankan

### 1. Persiapan File Environment
Buat file `.env` di root folder (gunakan `.env.example` sebagai referensi):
```env
DB_USER=user_admin
DB_PASSWORD=password_kuat
DB_NAME=db_refraksi
GEMINI_API_KEY=AIzaSy...
SECRET_KEY=...
```

### 2. Jalankan Sistem (Docker)
Sistem menggunakan *Multi-stage Build* untuk efisiensi produksi:
```bash
docker-compose up --build -d
```

### 3. Inisialisasi Data (WAJIB!)
Gunakan perintah modular untuk mengisi database awal:
```bash
# Isi Data Dasar (Admin, RS, & Artikel)
docker exec -it fastapi_refraksi python -m scripts.seed_data

# Isi Data Nasional & Premium (RS Mata & Artikel)
docker exec -it fastapi_refraksi python -m scripts.seed_national_data
```

---

## 🧪 Pengujian & Verifikasi

Untuk menjalankan pengujian otomatis:
```bash
docker exec -it fastapi_refraksi pytest tests/
```

---

## 📖 Dokumentasi Lanjutan

- **API Docs (Swagger)**: `http://localhost:8000/docs`
- **Laporan Proyek Detil**: Lihat `docs/project_report.md` untuk rincian mekanisme AI dan proposal teknis.
- **Health Check**: `http://localhost:8000/health`

---
Developed with ❤️ by the MataCeria Team.
**Vision for Everyone.**
