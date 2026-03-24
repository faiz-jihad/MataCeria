# Eye Refraksi - Aplikasi Deteksi Refraksi Mata

**Eye Refraksi** adalah aplikasi Flutter yang dirancang untuk membantu pengguna melakukan deteksi dini masalah refraksi mata, memantau kesehatan mata lewat analitik, dan berkonsultasi melalui fitur chat.

## 🚀 Fitur Utama

-   **Deteksi Refraksi Mata**: Menggunakan kamera untuk melakukan pengecekan awal kondisi mata.
-   **Dashboard Analitik**: Visualisasi data kesehatan mata dan riwayat prediksi.
-   **Chat & Konsultasi**: Fitur pesan untuk berinteraksi dengan sistem atau tenaga ahli.
-   **Artikel Kesehatan**: Edukasi mengenai kesehatan mata dan tips perawatan.
-   **Manajemen Pengguna**: Sistem autentikasi (Login/Register) yang aman.
-   **Pengingat Istirahat Mata**: Fitur untuk membantu pengguna menjaga kesehatan mata saat menggunakan gadget.

## 🛠️ Tech Stack

-   **Framework**: Flutter (Dart)
-   **State Management**: Provider
-   **Networking**: Dio & Http
-   **Storage**: Shared Preferences
-   **Font**: Google Fonts (GoogleSans)
-   **Utilities**: Flutter Dotenv, Permission Handler, Camera, Image Picker.

## ⚙️ Persyaratan Sistem & Konfigurasi

Proyek ini menggunakan konfigurasi Gradle terbaru untuk mendukung fitur Android terkini.

-   **Flutter SDK**: ^3.9.2
-   **Java/JDK**: v17 atau lebih tinggi (disarankan Java 24 untuk performa optimal di sistem ini).
-   **Gradle**: 8.11.1
-   **Android Gradle Plugin (AGP)**: 8.9.1

## 🏃 Cara Menjalankan Proyek

### 1. Persiapan
Pastikan semua dependensi terpasang:
```bash
flutter pub get
```

### 2. Menjalankan Mode Debug
Untuk menjalankan aplikasi di perangkat yang terhubung:
```bash
flutter run
```

### 3. Menjalankan Mode Release
Jika ingin mencoba performa maksimal (tanpa debugging):
```bash
flutter run --release
```

## 🔧 Troubleshooting

Jika Anda menghadapi masalah saat melakukan build (terutama di Android), pastikan hal-hal berikut:

1.  **Versi Gradle**: Pastikan `android/gradle/wrapper/gradle-wrapper.properties` menggunakan `gradle-8.11.1-all.zip`.
2.  **Versi AGP**: Pastikan `android/settings.gradle.kts` menggunakan plugin version `8.9.1`.
3.  **Conflict Process**: Jika build terasa lama atau membeku, pastikan tidak ada proses `java.exe` yang menggantung di Background.

---
*Dibuat untuk portofolio pengembangan aplikasi kesehatan digital.*
