# 🤖 Panduan CI/CD: MataCeria Auto-Deploy

Panduan ini menjelaskan bagaimana sistem otomatisasi (GitHub Actions) bekerja untuk melakukan pengujian dan pengiriman kode dari repositori GitHub langsung ke server VPS Anda.

---

## 🏗️ 1. ALUR KERJA (WORKFLOW)

Proyek ini memiliki dua alur kerja utama di folder `.github/workflows/`:

### A. CI (Continuous Integration) - `ci.yml`
- **Kapan Jalan?**: Setiap kali ada *Push* atau *Pull Request* ke branch `main`, `master`, atau `develop`.
- **Apa yang Dilakukan?**: 
  - Memeriksa kesalahan penulisan kode (*Linting*).
  - Menjalankan *Unit Tests* (Pytest).
  - Mencoba *Build Docker Image* untuk memastikan `Dockerfile` tidak error.

### B. CD (Continuous Deployment) - `deploy.yml`
- **Kapan Jalan?**: Hanya saat ada *Push* ke branch `main` atau `master`.
- **Apa yang Dilakukan?**: 
  - Masuk ke server VPS via SSH.
  - Melakukan `git pull` terbaru.
  - Membangun ulang kontainer Docker (`build`).
  - Menjalankan database seeding secara otomatis.

---

## 🔐 2. KONFIGURASI GITHUB SECRETS (WAJIB)

Agar GitHub dapat mengakses server Anda, Anda **HARUS** mendaftarkan variabel rahasia di repositori GitHub Anda:
1. Buka Repositori di GitHub.
2. Klik **Settings** > **Secrets and variables** > **Actions**.
3. Klik **New repository secret** dan masukkan daftar berikut:

| Nama Secret | Deskripsi |
| :--- | :--- |
| `VPS_HOST` | Alamat IP atau Domain Server VPS Anda. |
| `VPS_USER` | Username SSH (misal: `root` atau `ubuntu`). |
| `VPS_SSH_KEY` | Private Key SSH Anda (Isi dari file `~/.ssh/id_rsa`). |
| `VPS_PATH` | Path folder proyek di server (misal: `/home/ubuntu/MataCeria`). |
| `GIT_TOKEN` | Personal Access Token GitHub (agar VPS bisa `git pull`). |
| `DB_NAME` | Nama database produksi. |
| `DB_USER` | Username database produksi. |
| `DB_PASSWORD` | Password database produksi. |
| `SECRET_KEY` | Kunci keamanan JWT (Acak saja). |
| `GEMINI_API_KEY` | API Key dari Google AI Studio. |

---

## 🛠️ 3. CARA MONITORING DEPLOYMENT
1. Setelah Anda melakukan `git push origin main`, buka tab **Actions** di GitHub.
2. Pilih workflow **Deploy MataCeria to VPS**.
3. Klik run yang sedang berjalan untuk melihat log proses deploy secara real-time.

---

## ❓ PENANGANAN MASALAH (TROUBLESHOOTING)

### Build Gagal di Tahap SSH?
- Pastikan IP `VPS_HOST` benar.
- Pastikan firewall server mengizinkan koneksi SSH (Port 22).
- Pastikan `VPS_SSH_KEY` sudah ditambahkan ke `~/.ssh/authorized_keys` di server.

### Error "Bind: Port already in use"?
- Ini terjadi jika ada service lain di VPS yang menggunakan port 8000 atau 3001. Matikan service tersebut atau ubah port di `docker-compose.yaml`.

---
*Otomatisasi ini menjaga server Anda tetap mutakhir dengan satu kali push!* 🚀
