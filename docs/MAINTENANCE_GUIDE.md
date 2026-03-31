# 🛡️ Panduan Pemeliharaan & Keamanan: MataCeria Production

Dokumen ini merinci langkah-langkah keamanan proaktif, kebijakan perlindungan data, dan prosedur pemulihan bencana (*Disaster Recovery*).

---

## 🔒 1. HARDENING SISTEM (KEAMANAN BERLAPIS)

| Lapisan | Implementasi |
| :--- | :--- |
| **Network** | Port Database (5432) dan Redis (6379) ditutup dari publik. Akses hanya melalui Docker Network. |
| **Container** | Aplikasi berjalan sebagai **Non-Root User** (`appuser`). |
| **Nginx** | Keamanan Header Host, CSP, dan HSTS aktif. |
| **Data** | Password dienkripsi dengan PBKDF2/SHA256 (Minimal 32 karakter). |

---

## 💾 2. PENCADANGAN DATABASE (BACKUP)

Pencadangan rutin adalah jaminan keberlangsungan data.

### Cara Backup Manual:
```bash
docker exec postgres_refraksi pg_dump -U user_admin db_refraksi > backup_$(date +%F).sql
```

### Cara Restore Data:
```bash
cat backup_file.sql | docker exec -i postgres_refraksi psql -U user_admin -d db_refraksi
```

---

## 🌩️ 3. PEMULIHAN BENCANA (DISASTER RECOVERY)

Jika terjadi kegagalan sistem total:
1.  **Skenario IP Diblokir**: Periksa status Cloudflare Tunnel. Lakukan restart kontainer `tunnel`.
2.  **Skenario Sistem Hang**: Lakukan `docker compose down` dan jalankan kembali `docker compose up -d`.
3.  **Skenario Serangan Brute Force**: Cek Redis log untuk mendeteksi IP penyerang. SlowAPI akan memblokir IP tersebut secara otomatis selama 1 jam.

---

## 📝 4. PENGELOLAAN LOG & TEMPAT PENYIMPANAN

- **Log API**: Disimpan di `/var/lib/docker/containers/` (Dikelola otomatis oleh Docker Rotator).
- **Log Nginx**: Dapat dilihat di `docker logs nginx_refraksi`.
- **Upload Gambar**: Disimpan di volume `/uploads/images` (Harus dicadangkan mingguan).

---

## ⚡ 5. KEBIJAKAN PEMBARUAN (UPDATE POLICY)

- **Library Update**: Dilakukan setiap bulan melalui `requirements.txt`.
- **Docker Image Update**: Mengikuti rilis Python 3.10-slim versi terbaru.
- **Security Audit**: Peninjauan berkala pada log autentikasi setiap minggu.

---
*Keamanan user dan stabilitas data adalah pondasi MataCeria.* 🦾✨
