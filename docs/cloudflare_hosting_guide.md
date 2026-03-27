# Panduan Hosting MataCeria dengan Cloudflare Tunnel

Panduan ini menjelaskan cara memindahkan API dari **Quick Tunnel** (link acak `.trycloudflare.com`) ke **Named Tunnel** dengan **Domain Kustom** (misal: `api.mataceria.com`) agar link API tetap permanen.

## 📋 Prasyarat
1.  **Akun Cloudflare**: Daftar gratis di [dash.cloudflare.com](https://dash.cloudflare.com/sign-up).
2.  **Domain**: Anda harus memiliki domain yang DNS-nya sudah diarahkan ke Cloudflare (misal: beli di Niagahoster/Rumahweb lalu hubungkan ke Cloudflare).

---

## 🛠️ Langkah-Langkah

### 1. Buat Tunnel di Dashboard Cloudflare
1.  Buka Dashboard Cloudflare > **Zero Trust**.
2.  Pilih **Networks** > **Tunnels**.
3.  Klik **Create a Tunnel**.
4.  Pilih **Cloudflared** > Klik **Next**.
5.  Beri nama tunnel (misal: `mataceria-server`) > Klik **Save Tunnel**.
6.  Di bagian **Install and run a connector**, pilih **Docker**.
7.  Copy bagian string panjang setelah `--token` (Ini adalah `TUNNEL_TOKEN` Anda).

### 2. Atur Public Hostname
1.  Setelah membuat tunnel, klik tab **Public Hostname**.
2.  Klik **Add a public hostname**.
3.  Isi detail berikut:
    - **Subdomain**: `api` (atau kosongkan jika ingin domain utama).
    - **Domain**: Pilih domain Anda (misal: `mataceria.com`).
    - **Service Type**: `HTTP`.
    - **URL**: `api:8000` (sesuai nama service di docker-compose).
4.  Klik **Save Hostname**.

### 3. Konfigurasi di Backend (Laptop Bapak)
1.  Buka file `.env` di folder root project.
2.  Tambahkan baris baru:
    ```env
    TUNNEL_TOKEN=masukkan_token_anda_disini
    ```
3.  Buka file `docker-compose.yaml`.
4.  Ubah bagian `tunnel` menjadi seperti ini:
    ```yaml
    tunnel:
      image: cloudflare/cloudflared:latest
      container_name: cloudflared_refraksi
      restart: always
      environment:
        - TUNNEL_TOKEN=${TUNNEL_TOKEN}
      command: tunnel run
      depends_on:
        - api
    ```

### 4. Jalankan Ulang
Jalankan perintah ini di terminal:
```bash
docker-compose up -d
```

---

## ✅ Keuntungan Menggunakan Metode Ini:
1.  **Link Tetap**: Link API Anda tidak akan pernah berubah (misal: `https://api.mataceria.com`).
2.  **Keamanan**: Tidak perlu membuka port di router atau firewall laptop.
3.  **HTTPS Otomatis**: Cloudflare menyediakan sertifikat SSL gratis untuk domain Anda.
4.  **Akses Global**: Aplikasi Flutter dapat mengakses API dari mana saja selama ada internet.

---
*Dikembangkan untuk kemudahan integrasi MataCeria.*
