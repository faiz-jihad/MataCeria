# 👁️ Eye Refraksi - Smart Eye Health Assistant

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Material 3](https://img.shields.io/badge/Material--3-6750A4?style=for-the-badge&logo=material-design&logoColor=white)](https://m3.material.io/)

**Eye Refraksi** adalah aplikasi cerdas berbasis mobile yang dirancang untuk memberikan solusi kesehatan mata preventif. Dengan integrasi AI, aplikasi ini mempermudah deteksi dini masalah refraksi (Miopia) dan memberikan edukasi kesehatan mata yang dipersonalisasi.

---

## ✨ Fitur Unggulan

> [!TIP]
> **Deteksi Refraksi Pintar**
> Gunakan kamera ponsel Anda untuk melakukan pemindaian awal kondisi mata dengan teknologi Computer Vision.

-   📊 **Dashboard Analitik**: Pantau tren kesehatan mata Anda melalui grafik interaktif dan riwayat pemeriksaan.
-   💬 **AI Assistant Chat (V2)**: Konsultasi cerdas dengan dukungan Rich Text (Markdown), saran interaktif (chips), dan lampiran dokumen/foto.
-   👁️ **AI Refraction Test (NEW)**: Pemeriksaan ketajaman visual (Snellen) adaptif berbasis AI dengan deteksi jarak wajah real-time dan ekstraksi area mata otomatis.
-   🛡️ **Admin Management**: Dashboard khusus admin untuk pengelolaan artikel, kontak darurat, dan ekspor data pengguna (CSV).
-   ⏱️ **Eye Rest Timer**: Fitur cerdas untuk mengingatkan Anda beristirahat saat terlalu lama menatap layar.
-   🚨 **Kontak Darurat**: Akses cepat ke database Rumah Sakit Mata dan kontak bantuan medis terintegrasi.

---

## 🛠️ Tech Stack & Arsitektur

### Core Framework
| Komponen | Teknologi |
| :--- | :--- |
| **UI Framework** | Flutter (Material 3) |
| **Bahasa** | Dart |
| **State Management** | Provider |
| **Networking** | Dio & Http Client |

### Utilities
- **Camera API**: Untuk pengambilan gambar presisi tinggi.
- **Shared Preferences**: Penyimpanan lokal yang efisien.
- **Google Fonts**: Tipografi modern menggunakan *GoogleSans*.

---

## ⚙️ Persyaratan Sistem

Untuk memastikan proses build berjalan lancar, pastikan lingkungan pengembangan Anda sesuai dengan spesifikasi berikut:

- **Flutter SDK**: `^3.9.2`
- **Java/JDK**: Version `17+` (Disarankan Java 24 pada sistem Windows)
- **Gradle**: `8.11.1`
- **Android Gradle Plugin**: `8.9.1`

---

## 🚀 Cara Memulai

### 1. Kloning Repositori
```bash
git clone -b frontend https://github.com/faiz-jihad/MataCeria.git
```

### 2. Instal Dependensi
```bash
flutter pub get
```

### 3. Jalankan Aplikasi
```bash
# Debug Mode
flutter run

# Release Mode (Performansi Terbaik)
flutter run --release
```

---

## 🔧 Panduan Troubleshooting

> [!WARNING]
> Jika Anda menemui error saat build Android, periksa file konfigurasi berikut:
> 1. `android/gradle/wrapper/gradle-wrapper.properties` -> Gunakan `gradle-8.11.1-all.zip`
> 2. `android/settings.gradle.kts` -> Gunakan `id("com.android.application") version "8.9.1"`

---
*Dikembangkan dengan ❤️ untuk mendukung kesehatan mata masyarakat Indonesia.*
