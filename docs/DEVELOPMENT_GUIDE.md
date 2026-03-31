# 🛠️ Panduan Pengembangan: MataCeria Backend

Selamat datang di tim pengembang MataCeria! Dokumen ini dirancang untuk membantu Anda memulai pengembangan lokal dengan cepat dan menjaga standar kualitas kode yang tinggi.

---

## 🏗️ 1. PERSIAPAN LINGKUNGAN LOKAL

Meskipun sistem kami menggunakan Docker untuk produksi, untuk pengembangan harian yang cepat, disarankan menggunakan virtual environment lokal.

### A. Instalasi Awal
1. Pastikan Anda memiliki **Python 3.10+** dan **PostgreSQL** terinstal.
2. Buat virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   venv\Scripts\activate     # Windows
   ```
3. Instal dependensi:
   ```bash
   pip install -r requirements.txt
   pip install pytest flake8 black
   ```

### B. Konfigurasi Lingkungan
Buat file `.env` di root folder dan sesuaikan `DB_HOST=localhost` untuk koneksi lokal ke database.

---

## 📂 2. STRUKTUR PROYEK & KAPAN MENGGUNAKAN APA

| Folder | Isi / Tanggung Jawab |
| :--- | :--- |
| **app/api/** | Router FastAPI. Tempat mendefinisikan endpoint. |
| **app/models/** | Model SQLAlchemy. Tempat mendefinisikan tabel database. |
| **app/schemas/** | Pydantic Schemas. Tempat validasi input/output API. |
| **app/services/** | Logika Bisnis & AI. Semua perhitungan berat ada di sini. |
| **app/core/** | Konfigurasi global (Security, Config, Rate Limit). |

---

## ⚡ 3. WORKFLOW MENAMBAH FITUR BARU

Jangan langsung menulis kode secara acak! Ikuti alur **"Data-First"** berikut:
1.  **Define Schema**: Buat skema Pydantic untuk input/output di `app/schemas/`.
2.  **Define Model**: Buat tabel database di `app/models/`.
3.  **Implement Service**: Tulis logika bisnis atau fungsi database di `app/services/`.
4.  **Create Endpoint**: Hubungkan semuanya di `app/api/`.

---

## 📏 4. STANDAR PENULISAN KODE (STYLE GUIDE)

- **Variable Naming**: Gunakan `snake_case` untuk variabel dan fungsi. Gunakan `PascalCase` untuk Class.
- **Async First**: Gunakan `async def` untuk semua endpoint API agar tidak menghambat trafik.
- **Error Handling**: Gunakan `raise HTTPException(status_code=..., detail=...)` untuk mengembalikan error yang rapi ke frontend.
- **Linting**: Jalankan `flake8 .` sebelum melakukan rilis untuk memastikan tidak ada kesalahan sintaks.

---

## 🧪 5. PENGUJIAN (TESTING)

Kami sangat menghargai kode yang teruji.
- **Unit Test**: Gunakan `pytest` di folder `tests/`.
- **Menjalankan Test**:
  ```bash
  pytest tests/
  ```

---
*Kode yang bersih adalah kode yang bahagia!* 🚀✨
