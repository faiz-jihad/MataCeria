# Daftar Lengkap API Endpoints (v1) 🚀

Semua endpoint berikut menggunakan base URL: `http://localhost:8000/api/v1` (atau `http://10.0.2.2:8000/api/v1` untuk Android Emulator).

## 1. Authentication (Autentikasi)
| Method | Path | Deskripsi | Auth? |
| :--- | :--- | :--- | :---: |
| `POST` | `/auth/register` | Pendaftaran user baru | ❌ |
| `POST` | `/auth/login` | Login user (x-www-form-urlencoded) | ❌ |
| `POST` | `/auth/forgot-password` | Kirim token reset password | ❌ |
| `POST` | `/auth/reset-password` | Reset password dengan token | ❌ |
| `POST` | `/logout` | Logout user | ❌ |

## 2. User Profile & Activities
| Method | Path | Deskripsi | Auth? |
| :--- | :--- | :--- | :---: |
| `GET` | `/user/me` | Ambil data profil user saat ini | ✅ |
| `POST` | `/user/change-password` | Ubah password (login dulu) | ✅ |
| `GET` | `/user/activities` | Ambil riwayat aktivitas terakhir | ✅ |

## 3. AI Eye Refraction Test
| Method | Path | Deskripsi | Auth? |
| :--- | :--- | :--- | :---: |
| `POST` | `/refraction-test` | Upload gambar mata untuk tes AI | ✅ |
| `GET` | `/predictions` | Ambil riwayat hasil tes AI | ✅ |

## 4. AI Chat Assistant (Gemini RAG)
| Method | Path | Deskripsi | Auth? |
| :--- | :--- | :--- | :---: |
| `POST` | `/chat/send` | Kirim pesan ke asisten AI Gemini | ✅ |
| `GET` | `/chat/history` | Ambil seluruh riwayat percakapan | ✅ |
| `GET` | `/chat/messages` | Alias riwayat chat (untuk Flutter) | ✅ |
| `GET` | `/chat/unread-count` | Cek jumlah pesan baru (badge) | ✅ |
| `POST` | `/chat/feedback` | Kirim rating/ulasan jawaban AI | ✅ |

## 5. Knowledge Base & Services
| Method | Path | Deskripsi | Auth? |
| :--- | :--- | :--- | :---: |
| `GET` | `/articles` | Daftar artikel kesehatan mata | ❌ |
| `GET` | `/emergency/contacts` | Daftar RS/Klinik mata darurat | ❌ |
| `GET` | `/notifications` | Daftar notifikasi sistem user | ✅ |
| `GET` | `/conditions` | Daftar penyakit mata (untuk UI) | ❌ |

## 6. System & Health
| Method | Path | Deskripsi | Auth? |
| :--- | :--- | :--- | :---: |
| `GET` | `/health` | Cek status kesehatan server | ❌ |
| `GET` | `/` | Pesan selamat datang (Root) | ❌ |

---
**Tips:** Seluruh dokumentasi detail (body request & response) dapat dilihat di: `http://localhost:8000/docs`
