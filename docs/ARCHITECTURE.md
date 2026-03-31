# 🏗️ Arsitektur & Scaling MataCeria

Dokumen ini menjelaskan bagaimana sistem backend MataCeria dirancang untuk keandalan tinggi dan efisiensi sumber daya di lingkungan produksi.

---

## 🛰️ 1. DIAGRAM ALIR TRAFIK

```mermaid
graph TD
    User((User/Mobile)) -->|HTTP Port 8000| Nginx[Nginx Load Balancer]
    Nginx -->|Proxy| API1[API Replica 1]
    Nginx -->|Proxy| API2[API Replica 2]
    Nginx -->|Proxy| API3[API Replica 3]
    Nginx -->|Proxy| API4[API Replica 4]
    
    API1 & API2 & API3 & API4 -->|Shared State| Redis[(Redis - Rate Limiting)]
    API1 & API2 & API3 & API4 -->|Data Persist| Postgres[(PostgreSQL)]
    
    Prometheus[Prometheus] -->|Scrape Metrics| API1 & API2 & API3 & API4
    Grafana[Grafana] -->|Visualize| Prometheus
```

---

## 🚀 2. KOMPONEN UTAMA

| Komponen | Peran Utama |
| :--- | :--- |
| **Nginx** | Berperan sebagai Reverse Proxy dan Load Balancer. Menangani kompresi Gzip dan Caching file. |
| **FastAPI Replicas** | 4 instance kontainer yang berjalan secara paralel untuk menangani beban tinggi. |
| **Redis** | Digunakan untuk sinkronisasi *Rate Limiting*. Tanpa Redis, tiap replika akan memiliki hitungan kuota sendiri-sendiri (inkonsisten). |
| **PostgreSQL** | Database relasional untuk menyimpan data pengguna, hasil tes, dan artikel. |

---

## ⚡ 3. OPTIMASI "ULTRA-LIGHTWEIGHT"

Sistem ini didesain agar tidak membebani server (hemat RAM) melalui teknik:
- **ONNX Runtime (OR)**: Menggunakan engine ONNX untuk inferensi AI yang 10x lebih hemat memori dibanding TensorFlow.
- **Multi-stage Build**: Docker image tetap kecil karena compiler (*gcc*) hanya ada saat tahap build saja.
- **Resource Limits**: Tiap replika API dibatasi maksimal 1GB RAM untuk mencegah satu proses AI memakan seluruh memori server (16GB).

---

## 📊 4. MONITORING
- **Grafana**: Tersedia di port **3001** untuk melihat statistik performa secara real-time.
- **Prometheus**: Mengumpulkan data penggunaan API dari setiap instansi kontainer.
