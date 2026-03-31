# 🛡️ Kebijakan & Hardening Keamanan: MataCeria Production

Dokumen ini merinci langkah-langkah keamanan proaktif yang telah diterapkan pada infrastruktur backend MataCeria.

---

## 🔒 1. PROTEKSI AKSES & ISOLASI

| Komponen | Proteksi |
| :--- | :--- |
| **Akses Database** | DB (5432) dan Redis (6379) ditutup dari publik. Hanya bisa diakses secara internal melalui jaringan Docker. |
| **Layanan API** | Semua trafik luar harus melalui **Nginx Load Balancer** (Port 8000). |
| **Non-Root User** | Semua kontainer aplikasi berjalan menggunakan `appuser`. Jika ada peretasan, penyerang tidak memiliki hak akses *Root* di sistem. |

---

## 🔐 2. AUTENTIKASI & OTORISASI (JWT)

Sistem menggunakan **JWT (JSON Web Token)** untuk menjaga kerahasiaan sesi pengguna:
- **Enkripsi**: Algoritma `HS256`.
- **Masa Berlaku**: Token otomatis kedaluwarsa setelah **24 jam** (1440 menit) untuk keamanan tinggi.
- **Refresh Policy**: Memberikan token baru hanya jika kredensial user (email/password) valid.

---

## 🛡️ 3. HARDENING NGINX (SECURITY HEADERS)

Konfigurasi Nginx telah diperkuat dengan *Security Headers* berikut:
- **Server Tokens Off**: Menyembunyikan versi Nginx agar tidak mudah di-*exploit*.
- **HSTS (Strict-Transport-Security)**: Memaksa browser menggunakan koneksi aman (HTTPS).
- **X-Frame-Options**: Mencegah serangan *Clickjacking* (iframe tertutup).
- **Content-Security-Policy (CSP)**: Membatasi sumber skrip (hanya dari CDN terpercaya dan self-hosted).

---

## ⚡ 4. PENCEGAHAN ABUSE (RATE LIMITING)

Penerapan pembatasan request (*Rate Limiting*) dilakukan secara berlapis:
1.  **Distributed Rate Limit**: Menggunakan **Redis** agar kuota 50 request/menit berlaku secara global di seluruh replika API.
2.  **IP-Based Throttling**: Membatasi satu IP Address agar tidak membanjiri server dengan request berulang (*Brute Force*).

---

## 📝 5. AUDIT & LOGGING

Semua aktivitas penting dicatat secara otomatis:
- **Login Succeeded/Failed**: Dicatat beserta timestamp.
- **AI Inference Log**: Mencatat performa model tanpa menyimpan data sensitif user.
- **Log Rotation**: Membatasi ukuran kepingan log Docker maksimal 10MB per file (3 file) agar disk server tidak penuh.

---
*Keamanan data pengguna adalah prioritas tertinggi kami.* 👁️🔐
