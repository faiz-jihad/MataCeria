# 📋 Dokumentasi Endpoint API MataCeria

Dokumen ini berisi daftar lengkap endpoint API untuk diintegrasikan dengan aplikasi Mobile (Flutter).

**Base URL (Local)**: `http://localhost:8000/api/v1`
**Base URL (Cloudflare)**: `https://<your-tunnel-url>.trycloudflare.com/api/v1`

---

## 🔐 1. Autentikasi (`/auth`)
| Method | Endpoint | Deskripsi | Payload (JSON) |
|---|---|---|---|
| POST | `/auth/register` | Daftar user baru | `nama_lengkap`, `email`, `password`, `umur`, `kelamin`, `jenjang_pendidikan`, `status_pekerjaan` |
| POST | `/auth/login` | Login user/admin | `username` (email), `password` (FormData) |
| POST | `/auth/forgot-password` | Request reset password | `email` |
| POST | `/auth/reset-password` | Reset password dengan token | `token`, `new_password` |

---

## 👤 2. Profil Pengguna (`/user`)
| Method | Endpoint | Deskripsi | Header |
|---|---|---|---|
| GET | `/user/me` | Ambil data profil sendiri | Bearer Token |
| PUT | `/user/me` | Update data profil | Bearer Token |
| POST | `/user/profile-image` | Upload foto profil | Bearer Token (Multipart) |
| GET | `/user/activities` | Riwayat aktivitas terakhir | Bearer Token |

---

## 👁️ 3. Tes Refraksi (`/refraction` & `/api/v2`)
| Method | Endpoint | Deskripsi | Versi |
|---|---|---|---|
| POST | `/api/v1/refraction-test` | Simpan hasil tes Snellen | V1 (Standard) |
| GET | `/api/v1/refraction-test` | Ambil riwayat tes user | V1 |
| POST | `/api/v2/refraction/ai` | **Tes AI Hybrid** (Kirim foto mata) | **V2 (AI Enhanced)** |
| POST | `/api/v2/refraction/detect-distance` | **Deteksi Jarak/Wajah** (Real-time Feedback) | **V2** |

---

## 📖 4. Artikel & Riset (`/articles`)
| Method | Endpoint | Deskripsi |
|---|---|---|
| GET | `/articles/` | Daftar semua artikel (Terformat) |
| GET | `/articles/research-search` | **Cari data medis** (WHO, PubMed, FDA) |
| POST | `/articles/upload-image` | Upload gambar artikel (Admin) |

---

## 📢 5. Notifikasi (`/notifications`)
| Method | Endpoint | Deskripsi |
|---|---|---|
| GET | `/notifications/` | Daftar notifikasi user |
| PUT | `/notifications/{id}/read` | Tandai sudah dibaca |
| PUT | `/notifications/read-all` | Tandai semua sudah dibaca |
| DELETE | `/notifications/{id}` | Hapus notifikasi |

---

## 🛡️ 6. Admin Tools (`/admin`)
| Method | Endpoint | Deskripsi | Keamanan |
|---|---|---|---|
| GET | `/admin/stats/overview` | Statistik Dashboard (User, Tes, dll) | Admin Only |
| GET | `/admin/users` | Daftar semua User | Admin Only |
| DELETE | `/admin/users/{id}` | Hapus User & Datanya | Admin Only |
| DELETE | `/admin/tests/{id}` | Hapus record tes | Admin Only |
| POST | `/admin/notifications/broadcast` | Kirim pesan ke seluruh user | Admin Only |
| GET | `/admin/users/export` | Ekspor data lengkap ke JSON | Admin Only |

---

## 🏥 7. Kontak Darurat (`/emergency/contacts`)
| Method | Endpoint | Deskripsi |
|---|---|---|
| GET | `/emergency/contacts/` | Daftar kontak darurat |
| POST | `/emergency/contacts/` | Tambah kontak (Admin) |

---

## 💬 8. AI Chatbot (`/chat`)
| Method | Endpoint | Deskripsi |
|---|---|---|
| POST | `/chat/` | Kirim pesan ke Chatbot AI |
| GET | `/chat/history/{session_id}` | Ambil riwayat chat |

---
*Gunakan Swagger di `/docs` untuk mencoba endpoint secara interaktif.*
