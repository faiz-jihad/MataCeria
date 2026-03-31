# 📖 Panduan API Terpadu: MataCeria Technical Reference

Dokumen ini adalah sumber kebenaran tunggal untuk semua interaksi teknis dengan API MataCeria.

---

## 🛰️ 1. BASE URL & VERSI

| Lingkungan | Base URL |
| :--- | :--- |
| **Produksi** | `https://api.mataceria.com` (Example) |
| **Pengujian** | `http://localhost:8000` |

---

## 🔐 2. AUTENTIKASI (JWT)

Semua endpoint kecuali `/auth`, `/health`, dan `/docs` membutuhkan Header Autentikasi:
`Authorization: Bearer <JWT_ACCESS_TOKEN>`

---

## 👁️ 3. CORE API: AI REFRACTION (V2)

### `POST /api/v2/refraction/ai`
Endpoint hybrid untuk deteksi miopia menggunakan gambar & data Snellen.

**Request Schema:**
-   `image_data`: Objek berisi `eye_frame_base64`.
-   `snellen_data`: Data hasil tes manual (Near vision, row read, dll).

**Sample Response (200 OK):**
```json
{
  "visual_acuity": "20/20",
  "snellen_decimal": 1.0,
  "predicted_class": "Normal",
  "confidence": 0.95,
  "recommendation": "Mata Anda dalam kondisi sehat.",
  "source": "hybrid_model_onnx"
}
```

---

## 🏥 4. DATA MODUL: RUMAH SAKIT & ARTIKEL

### `GET /api/v1/emergency/hospitals`
Mendapatkan daftar rumah sakit mata nasional.
- **Filter**: `region` (contoh: Bandung, Jakarta).

---

## 💬 5. SMART CHATBOT (V2)

### `POST /api/v2/chat/completion`
Interaksi dengan asisten AI berbasis Gemini 1.5 Flash (RAG).

---

## ⚠️ 6. PENANGANAN ERROR & PAYLOAD

Semua error dikembalikan dalam format standard Pydantic:
```json
{
  "detail": [
    {
      "loc": ["body", "email"],
      "msg": "invalid email format",
      "type": "value_error"
    }
  ]
}
```

### Daftar Status Code Penting:
| Code | Arti | Keterangan |
| :--- | :--- | :--- |
| **401** | Unauthorized | Token salah, hilang, atau kedaluwarsa. |
| **422** | Unprocessable Entity | Validasi input skema gagal. |
| **429** | Too Many Requests | Melewati batas 50 request/menit. |
| **500** | Internal Error | Masalah server atau model AI tidak merespon. |

---
*Dokumentasi ini diperbarui secara berkala sesuai perkembangan fitur.* 🦾✨
