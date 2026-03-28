# 📖 API REFERENCE: MATACERIA BACKEND
### Versi 2.0 (Production Ready)

Selamat datang di referensi API resmi MataCeria. API ini dirancang menggunakan standar RESTful dengan format pertukaran data JSON.

---

## 🔐 1. KEAMANAN & AUTENTIKASI
Seluruh endpoint kecuali `/auth` dan `/health` memerlukan header autentikasi **Bearer Token**.

**Header:**
`Authorization: Bearer <your_access_token>`

---

## 🛠️ 2. AUTHENTICATION (`/api/v1/auth`)

### A. Registrasi User
`POST /api/v1/auth/register`

**Request Body:**
```json
{
  "nama_lengkap": "Budi Santoso",
  "email": "budi@example.com",
  "password": "password123",
  "umur": 25,
  "kelamin": "Laki-laki",
  "jenjang_pendidikan": "S1",
  "status_pekerjaan": "Karyawan Swasta"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "email": "budi@example.com",
  "nama_lengkap": "Budi Santoso",
  "role": "user"
}
```

### B. Login
`POST /api/v1/auth/login`

**Request Body (Multipart/form-data):**
- `username`: email@example.com
- `password`: password123

**Response (200 OK):**
```json
{
  "access_token": "eyJhbGci...",
  "token_type": "bearer",
  "role": "user"
}
```

---

## 👁️ 3. AI REFRACTION (`/api/v2/refraction`)

### A. Hybrid AI Screening (V2)
`POST /api/v2/refraction/ai`

**Request Body:**
```json
{
  "image_base64": "data:image/jpeg;base64,...",
  "device_info": {
    "screen_ppi": 441,
    "screen_width_px": 1080
  },
  "snellen_data": {
    "avg_distance_cm": 35.5,
    "smallest_row_read": 8,
    "missed_chars": 1
  }
}
```

**Response (200 OK):**
```json
{
  "test_id": "uuid-v4-string",
  "ai_results": {
    "category": "Miopia Ringan",
    "confidence": 0.92,
    "estimated_diopter": -1.25,
    "recommendation": "Gunakan kacamata saat berkendara dan kurangi durasi layar."
  }
}
```

---

## 💬 4. SMART CHATBOT (`/api/v1/chat`)

### A. Kirim Pesan (Integrasi RAG)
`POST /api/v1/chat/send`

**Request Body:**
```json
{
  "message": "Apa itu Miopia?",
  "session_id": null,
  "refraction_result": "Miopia Ringan"
}
```

**Response (200 OK):**
```json
{
  "session_id": "uuid-session",
  "bot_response": {
    "message": "Miopia adalah kondisi di mana...",
    "metadata": {
      "suggestions": ["Mencegah Myopia", "Cek Dokter"]
    }
  }
}
```

---

## 🏥 5. KONTAK DARURAT & RS
`GET /api/v1/emergency/contacts/`

**Query Params:**
- `region`: (opsional) Filter berdasarkan kota.

**Response:**
```json
[
  {
    "nama_rs": "RS Mata Nasional Cicendo",
    "telepon": "022-4231280",
    "alamat": "Jl. Cicendo No. 4, Bandung",
    "latitude": -6.911,
    "longitude": 107.604
  }
]
```

---

## ⚠️ 6. PENANGANAN ERROR
| Code | Deskripsi |
|---|---|
| 400 | Bad Request (Input salah) |
| 401 | Unauthorized (Token tidak valid/expire) |
| 403 | Forbidden (Bukan Admin) |
| 422 | Unprocessable Entity (Validasi Pydantic gagal) |
| 429 | Rate Limit Exceeded (Tunggu beberapa menit) |
| 500 | Internal Server Error |
