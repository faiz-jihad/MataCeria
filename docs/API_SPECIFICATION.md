# 📘 Spesifikasi Teknis API MataCeria

Dokumen ini merinci standar teknis, struktur data, dan penanganan keamanan informasi pada API MataCeria.

---

## 🏗️ 1. STANDAR KOMUNIKASI
- **Protocol**: HTTPS (Production) / HTTP (Local)
- **Format Data**: JSON (UTF-8)
- **Timezone**: UTC (Penyimpanan) / Local (Tampilan)
- **Versioning**: Prefix URL (e.g. `/api/v1` atau `/api/v2`)

---

## 🔐 2. AUTENTIKASI & KEAMANAN DATA
| Fitur | Implementasi |
| :--- | :--- |
| **Auth Type** | Bearer Token (JWT - JSON Web Token) |
| **Enkripsi** | PBKDF2 dengan SHA256 (Password) |
| **Data PII** | Masking pada log (Email & Nama tidak ditampilkan di log mentah) |
| **Rate Limit** | 50 request/menit per IP (Shared via Redis) |

---

## 👁️ 3. CORE API: AI REFRACTION (V2)

### `POST /api/v2/refraction/ai`
Endpoint hybrid untuk analisis mata menggunakan gambar Snellen & Frame Mata.

**Input Payload (JSON):**
```json
{
  "image_data": {
    "eye_frame_base64": "string (base64 encoded jpeg/png)"
  },
  "snellen_data": {
    "test_type": "near_vision | distance_vision",
    "smallest_row_read": "integer (1-11)",
    "missed_chars": "integer (0-5)",
    "astigmatism_found": "boolean"
  }
}
```

**Response Payload (200 OK):**
```json
{
  "visual_acuity": "20/20",
  "snellen_decimal": 1.0,
  "predicted_class": "string (Normal|Miopia|Impairment)",
  "confidence": 0.95,
  "recommendation": "string (Medical advice)",
  "source": "hybrid_model_onnx"
}
```

---

## 📊 4. PENANGANAN STATUS CODE

| Code | Nama | Skenario Penggunaan |
| :--- | :--- | :--- |
| **200** | OK | Request berhasil diproses. |
| **201** | Created | Data (user/riwayat) baru berhasil dibuat. |
| **400** | Bad Request | Parameter tidak lengkap atau format base64 rusak. |
| **401** | Unauthorized | Token hilang, expired, atau salah. |
| **422** | Validation Error | Tipe data salah (contoh: string dikirim ke field integer). |
| **429** | Too Many Requests | Melewati batas rate limit 50 req/menit. |
| **500** | Internal Error | Kegagalan server atau model AI tidak merespon. |

---

## 🛠️ 5. PEMBARUAN PROFIL (PATCH Logic)
API mendukung pembaruan parsial. Anda hanya perlu mengirimkan field yang ingin diubah tanpa harus mengirimkan seluruh data profil.

`PATCH /api/v1/users/profile`
```json
{
  "umur": 26,
  "status_pekerjaan": "Mahasiswa"
}
```
*(Field lain tetap menggunakan data lama di database)*.
