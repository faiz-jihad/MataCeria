# 🛠️ Pemeliharaan & Pemulihan Bencana: MataCeria Production

Dokumen ini merinci prosedur rutin pemeliharaan sistem dan langkah-langkah pemulihan jika terjadi kegagalan sistem.

---

## 💾 1. PENCADANGAN DATABASE (BACKUP)

Pencadangan rutin harus dilakukan harian untuk mencegah kehilangan data.

### A. Pencadangan Manual
Jalankan perintah berikut untuk membuat file backup `.sql`:
```bash
docker exec postgres_refraksi pg_dump -U user_admin db_refraksi > backup_$(date +%F).sql
```

### B. Strategi Rotasi
Simpan minimal 7 file cadangan terakhir (Harian) dan 4 file cadangan mingguan (Bulanan).

---

## 🔄 2. PEMULIHAN DATA (RESTORATION)

Jika terjadi kerusakan database, gunakan langkah berikut untuk memulihkan data:
1. Pastikan kontainer `db` berjalan.
2. Salin data dari file backup:
```bash
cat backup_nama_file.sql | docker exec -i postgres_refraksi psql -U user_admin -d db_refraksi
```

---

## 🏗️ 3. PEMELIHARAAN SISTEM (MAINTENANCE)

| Tugas | Frekuensi | Perintah |
| :--- | :--- | :--- |
| **Update Docker Image** | Bulanan | `docker compose pull && docker compose up -d` |
| **Pembersihan Log** | Mingguan | Docker otomatis melakukan rotasi log (max 10MB per file). |
| **Refresh Data Seeding** | Saat Rilis | `docker compose exec -T api python -m scripts.seed_data` |

---

## 🚑 4. PEMULIHAN BENCANA (DISASTER RECOVERY)

### Skenario A: Service Mati Mendadak
Jika satu replika API mati, Nginx akan otomatis memindahkan trafik. Jika seluruh sistem mati:
1. Lakukan `docker compose down`.
2. Hapus volume cache jika perlu (HATI-HATI): `docker volume prune`.
3. Jalankan kembali: `docker compose up -d`.

### Skenario B: Serangan Cyber / Kebocoran Kunci
1. Ubah `SECRET_KEY` di file `.env`.
2. Ubah `DB_PASSWORD` di file `.env`.
3. Lakukan rilis ulang: `docker compose up -d --build`.

---

## 📊 5. LOG ROTATION CFG
Konfigurasi rotasi log telah diterapkan di `docker-compose.yaml`:
- **Max-size**: 10MB per kontainer.
- **Max-file**: 3 file cadangan log.
*(Hal ini mencegah disk server penuh tiba-tiba).*

---
*Keandalan sistem adalah jaminan kualitas MataCeria.* 🦾✨
