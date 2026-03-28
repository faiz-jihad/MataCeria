# 📜 DAFTAR LENGKAP ENDPOINT API MATACERIA

Berikut adalah daftar seluruh endpoint yang tersedia di sistem Backend MataCeria, dikelompokkan berdasarkan modul fungsinya.

---

## 🔐 1. AUTHENTICATION (`/api/v1/auth`)
| Method | Path | Deskripsi |
|---|---|---|
| POST | `/register` | Registrasi pengguna baru |
| POST | `/login` | Login (OAuth2 Password Bearer) |
| POST | `/forgot-password` | Request token reset password |
| POST | `/reset-password` | Reset password dengan token |

---

## 👤 2. USER PROFILE (`/api/v1/user`)
| Method | Path | Deskripsi |
|---|---|---|
| GET | `/me` | Ambil data profil saya |
| PUT | `/me` | Update data profil |
| PUT | `/settings` | Update pengaturan user |
| POST | `/profile-image` | Upload foto profil (Multipart) |
| POST | `/change-password` | Ganti password saat login |
| GET | `/emergency-contacts`| Daftar kontak darurat simpanan user |
| GET | `/activities` | Riwayat aktivitas log user |

---

## 👁️ 3. REFRACTION & AI (`/api/v1` & `/api/v2`)
| Method | Path | Deskripsi | Versi |
|---|---|---|---|
| POST | `/api/v1/refraction/test` | Input hasil tes Snellen manual | V1 |
| POST | `/api/v2/refraction/ai` | **Inference AI Hybrid (Mata)** | **V2** |
| POST | `/api/v2/refraction/detect-distance` | **Deteksi Jarak/Wajah Realtime** | **V2** |

---

## 💬 4. AI CHATBOT (`/api/v1/chat`)
| Method | Path | Deskripsi |
|---|---|---|
| GET | `/unread-count` | Jumlah pesan belum terbaca |
| POST | `/send` | Kirim pesan ke AI Gemini (RAG) |
| GET | `/history` | Riwayat pesan seluruh sesi |
| GET | `/messages` | Alias untuk riwayat pesan |
| POST | `/feedback` | Rating jawaban AI |

---

## 📖 5. ARTICLES & RESEARCH (`/api/v1/articles`)
| Method | Path | Deskripsi |
|---|---|---|
| GET | `/` | List seluruh artikel kesehatan |
| POST | `/` | Tambah artikel baru (Admin) |
| PUT | `/{id}` | Update artikel (Admin) |
| DELETE | `/{id}` | Hapus artikel (Admin) |
| POST | `/upload-image` | Upload gambar artikel |
| GET | `/research-search` | Cari data medis (PubMed/WHO) |

---

## 🏥 6. EMERGENCY CONTACTS (`/api/v1/emergency`)
| Method | Path | Deskripsi |
|---|---|---|
| GET | `/` | List Rumah Sakit Mata |
| POST | `/` | Tambah RS baru (Admin) |
| PUT | `/{id}` | Update data RS (Admin) |
| DELETE | `/{id}` | Hapus data RS (Admin) |

---

## 📢 7. NOTIFICATIONS (`/api/v1/notifications`)
| Method | Path | Deskripsi |
|---|---|---|
| GET | `/` | List notifikasi user |
| PUT | `/{id}/read` | Tandai satu dibaca |
| PUT | `/read-all` | Tandai semua dibaca |
| DELETE | `/{id}` | Hapus notifikasi |

---

## 🛡️ 8. ADMIN DASHBOARD (`/api/v1/admin`)
| Method | Path | Deskripsi |
|---|---|---|
| GET | `/stats/overview` | Statistik ringkasan (User/Tes) |
| GET | `/users` | List seluruh user terdaftar |
| GET | `/users/export` | Download data user (JSON/CSV) |
| POST | `/notifications/broadcast` | Kirim push notif ke semua user |
| DELETE | `/users/{id}` | Hapus user |
| DELETE | `/tests/{id}` | Hapus riwayat tes |

---

## 🧪 9. MISC & TESTING
| Method | Path | Deskripsi |
|---|---|---|
| GET | `/api/v1/misc/conditions` | List kondisi kesehatan mata |
| POST | `/api/v1/misc/logout` | Proses logout user |
| POST | `/api/v1/testing/refraction-test` | Endpoint dummy untuk testing |
| GET | `/api/v1/testing/refraction-test` | Get dummy test |
| GET | `/api/v1/testing/predictions` | List prediksi (Debug) |
| GET | `/health` | Status kesehatan server |

---
**Catatan:** Gunakan Swagger UI di `/docs` untuk melihat detail skema Request/Response setiap endpoint.
