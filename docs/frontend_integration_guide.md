# MataCeria Backend: Front-End Integration Guide (Flutter)

This guide provides technical details for integrating the latest MataCeria Backend features into the Flutter mobile application.

## 1. Education & Articles
**Endpoint:** `GET /api/v1/articles`

To ensure compatibility across different model versions, the API now returns both **camelCase** and **snake_case** for critical fields.

| Preferred Key (New) | Alt Key (Legacy) | Type | Description |
| :--- | :--- | :--- | :--- |
| `imageUrl` | `image_url` | `String?` | Full URL to the article cover image. |
| `shareUrl` | `share_url` | `String?` | Deep-link for sharing the article. |
| `category` | `category` | `String` | Article category (e.g., "Edukasi"). |

## 2. Emergency Contacts
**Endpoint:** `GET /api/v1/emergency/contacts?region=Nasional`

We have standardized the fields to use English aliases to match typical Flutter `fromJson` models.

| Key | Alias | Type | Description |
| :--- | :--- | :--- | :--- |
| `name` | `nama` | `String` | Hospital/Clinic Name |
| `phone` | `nomor_telepon` | `String` | Contact Number |
| `nomorTelepon` | `nomor_telepon` | `String` | CamelCase helper for phone |
| `category` | `kategori` | `String` | Type (Pusat, Swasta, Klinik) |
| `address` | `address` | `String?` | Physical address |

> [!TIP]
> Use `region=Nasional` to get the master list of 65+ eye hospitals across Indonesia.

## 3. Multi-Condition Refraction Screening
**Endpoint:** `POST /api/v1/refraction/test`

The screening system now detects Miopia, Hypermetropia, and Astigmatism.

### Request Payload
```json
{
  "user_id": "123",
  "test_type": "near_vision", // Use "distance_vision" for Snellen
  "device_info": {
    "screen_ppi": 400.0,
    "screen_width_px": 1080
  },
  "raw_data": {
    "avg_distance_cm": 40.0,
    "smallest_row_read": 5,
    "missed_chars": 1,
    "astigmatism_found": true // Set to true if user sees distorted lines on dial chart
  }
}
```

### Response Highlights
- `condition_category`: Returns specific diagnosis (e.g., "Hipermetropia / Presbiopia & Astigmatisme").
- `is_cylinder`: Boolean flag for cylinder detection.
- `recommendation`: Condition-specific medical advice.

## 4. AI Chatbot V2
**Endpoint:** `POST /api/v2/chat/send`

The new chatbot endpoint is now active and handles general eye health questions and refraction context.

**Authentication:** Requires Bearer Token (JWT) in Headers.
**Structure:**
```json
{
  "message": "Kenapa mata saya sering buram saat baca dekat?",
  "session_id": "uuid-string-optional",
  "refraction_result": "Hipermetropia" // Optional context
}
```

## 5. AI Refraction: Image Capture Standards
To ensure the AI Model (Hybrid Snellen + ML) provides accurate results, the following standards must be followed when sending images to `POST /api/v2/refraction/ai`.

### Technical Specifications
- **Format**: `JPG` or `PNG` (Base64 string).
- **Minimum Resolution**: 720p (1280x720) for raw capture.
- **Preprocessing (Recommended)**: Although the backend resizes to `224x224`, the Front-End should ideally **crop the image** to only show the "Eye Box" (both eyes clearly visible, no forehead or chin).
- **Lighting**: Use bright, indirect lighting. Avoid direct camera flash and strong shadows on the eye region.

### User-Facing Prompts (UX)
Use these prompts in the mobile UI to guide the patient:
1. **Initial**: "Posisikan mata Anda tepat di dalam kotak yang tersedia."
2. **Distance**: "Jauhkan ponsel sekitar 30-40 cm dari wajah Anda." (Gunakan sensor jarak/AR jika tersedia).
3. **Lighting**: "Pastikan wajah Anda berada di area yang terang dan tidak tertutup bayangan."
4. **Stable**: "Tahan sebentar... Sedang memproses gambar Anda."

### Request Example (AI Hybrid)
```json
{
  "user_id": "1",
  "device_info": { "screen_ppi": 400.0 },
  "snellen_data": {
    "avg_distance_cm": 40.0,
    "smallest_row_read": 8,
    "missed_chars": 0,
    "response_time": 12.5
  },
  "image_data": {
    "eye_frame_base64": "data:image/jpeg;base64,...(cropped_eyes)..."
  }
}
```

---

## 6. Profile Synchronization (Update Profile)
**Endpoint:** `PUT /api/v1/user/me`

Backend supports partial updates (only fields provided in JSON will be updated).

### Request Specification
```json
{
  "nama_lengkap": "string",
  "umur": 25,
  "kelamin": "Laki-laki",
  "jenjang_pendidikan": "S1",
  "status_pekerjaan": "Karyawan",
  "phone": "08123456789",
  "vision_type": "Miopi",
  "allergies": "Tidak ada",
  "medical_history": "Pernah laser eye surgery 2022",
  "vision_concerns": ["Sering buram saat baca", "Mata kering"]
}
```

### Response Success
```json
{
  "status": "success",
  "data": {
    "id": 1,
    "nama_lengkap": "...",
    ...
  }
}
```

---
*For questions, please refer to the [Swagger UI](http://localhost:8000/docs).*
