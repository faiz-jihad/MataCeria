# 📖 Pusat Dokumentasi MataCeria Backend

Selamat datang di portal dokumentasi teknis **MataCeria AI & Monitoring**. Dokumen ini dirancang untuk memberikan panduan yang konsisten dan lengkap bagi pengembang, administrator sistem, dan pemangku kepentingan tingkat produksi.

---

## 🏛️ 4 PILAR DOKUMENTASI (PRODUCTION-GRADE)

Pilihlah panduan di bawah ini sesuai dengan peran dan kebutuhan Anda:

| Pilar | Dokumen | Target Pembaca | Kategori Konten |
| :---: | :--- | :--- | :--- |
| **01** | **[PANDUAN PENGEMBANGAN](DEVELOPMENT_GUIDE.md)** | Developer | Onboarding, Coding Standards, Local Setup, & Testing. |
| **02** | **[PANDUAN TEKNIS API](API_GUIDE.md)** | Frontend/Mobile | Spesifikasi Endpoint, Skema JSON, Autentikasi, & Error. |
| **03** | **[PANDUAN INFRASTRUKTUR](OPERATIONS_GUIDE.md)** | DevOps / Admin | Scaling, Nginx, Cluster Optimization, & CI/CD. |
| **04** | **[PEMELIHARAAN & KEAMANAN](MAINTENANCE_GUIDE.md)** | SysAdmin / Security | Security Hardening, Backup, Recovery, & Incident Response. |

---

## ⚡ RINGKASAN CEPAT (QUICK LINKS)

- **Swagger API Docs**: `http://localhost:8000/docs`
- **Dashboard Admin**: `http://localhost:8000/admin/dashboard`
- **Monitoring Grafana**: `http://localhost:3001` (admin/admin)
- **Health Check**: `http://localhost:8000/health`

---

## 🛠️ STATUS SISTEM (V2.1 - STABLE)
Sistem ini menggunakan arsitektur **Hybrid AI** dengan **Load Balancing x4 Replicas**. Seluruh trafik dijamin oleh **Redis Global Rate Limiter** dan **Nginx Security Layer**.

---
*Dokumentasi ini adalah sumber kebenaran tunggal untuk rilis produksi MataCeria.* 🦾✨
