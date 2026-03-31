# 🚢 Panduan Operasional & Infrastruktur: MataCeria Production

Dokumen ini merinci orkestrasi server, orkestrasi kontainer, konfigurasi Nginx, dan prosedur rilis harian.

---

## 🏗️ 1. RINGKASAN INFRASTRUKTUR (SCALING)

Sistem MataCeria menggunakan **Micro-instance Scaling** yang didistribusikan oleh Nginx.

| Komponen | Peran |
| :--- | :--- |
| **Nginx** | Reverse Proxy & Load Balancer. Menangani kompresi data (Gzip). |
| **FastAPI Pooling** | 4 replika API berjalan secara paralel dengan isolasi resource CPU/RAM. |
| **Redis Sync** | Menghubungkan 4 replika tersebut untuk pembatasan request global (*Rate Limiting*). |

---

## ⚡ 2. KONFIGURASI DOCKER & RESOURCE LIMITS

Semua layanan diatur melalui `Docker-compose.yaml`:
- **CPU Limit**: 0.5 core per replika (mencegah lag server).
- **RAM Limit**: 1024MB per replika.
- **Max Logging**: 10MB per kontainer (mencegah disk penuh).

---

## 🚀 3. PROSEDUR RILIS OTOMATIS (CI/CD)

Rilis kode baru ke server dilakukan melalui **GitHub Actions**:
1.  **Langkah 1**: *Git Push* ke branch `main`.
2.  **Langkah 2**: CI menjalankan *Linting* & pengujian kontainer.
3.  **Langkah 3**: CD masuk ke server via SSH.
4.  **Langkah 4**: Server melakukan `docker compose up -d --build`.

**Variabel Rahasia (Secrets):**
Semua kunci (API Key, Password DB, SSH Key) dikelola melalui **GitHub Repository Secrets**.

---

## 🛠️ 4. PERINTAH OPERASIONAL PENTING

| Kebutuhan | Perintah |
| :--- | :--- |
| **Pembaruan Manual** | `docker compose up -d --build` |
| **Status Replika** | `docker compose ps` |
| **Monitoring Log AI** | `docker compose logs -f api` |
| **Database Seeding** | `docker compose exec -T api python -m scripts.seed_data` |

---

## 🛰️ 5. KONFIGURASI CLOUDFLARE (TUNNEL)

Sistem kami tidak membuka port server ke publik (No Port Forwarding).
Trafik disalurkan melalui **Cloudflare Tunnel** menggunakan token yang aman.
`api.mataceria.com` --> `Cloudflare` --> `Nginx` --> `API Replicas`.

---
*Stabilitas sistem adalah jaminan pelayanan MataCeria.* 🦾✨
