# PANDUAN LENGKAP & DETAIL: DEPLOYMENT 3-TIER DI VIRTUALBOX
> **Studi Kasus:** Proyek Cloud Computing — Flutter Web SPA, Docker Nginx Load Balancer (Round-Robin), Dual Backend Container (Node.js/Express), dan MySQL 8.0 Container dengan Persistent Volume.  
> **Platform:** Oracle VM VirtualBox (Simulasi Private Cloud / On-Premise Multi-Node).  
> **Target:** 100% Memenuhi Seluruh Ketentuan Dosen.

---

## DAFTAR ISI
1. [Pemenuhan Ketentuan Tugas Dosen](#1-pemenuhan-ketentuan-tugas-dosen)
2. [Arsitektur Sistem & Alokasi IP VirtualBox](#2-arsitektur-sistem--alokasi-ip-virtualbox)
3. [FASE 1: Download & Persiapan Software](#fase-1-download--persiapan-software)
4. [FASE 2: Konfigurasi VirtualBox Network (Host-Only + NAT)](#fase-2-konfigurasi-virtualbox-network-host-only--nat)
5. [FASE 3: Instalasi VM Master & Trik Cloning Cepat (Hemat Waktu)](#fase-3-instalasi-vm-master--trik-cloning-cepat-hemat-waktu)
6. [FASE 4: Deployment Database Tier di `vm-database`](#fase-4-deployment-database-tier-di-vm-database)
7. [FASE 5: Deployment Backend Tier di `vm-backend` (Dual Container)](#fase-5-deployment-backend-tier-di-vm-backend-dual-container)
8. [FASE 6: Deployment Frontend & Nginx Load Balancer di `vm-frontend-lb`](#fase-6-deployment-frontend--nginx-load-balancer-di-vm-frontend-lb)
9. [FASE 7: Solusi Akses Kamera Selfie Presensi (HTTPS / Cloudflare Tunnel)](#fase-7-solusi-akses-kamera-selfie-presensi-https--cloudflare-tunnel)
10. [FASE 8: Pengujian QA, Screenshot Bukti, & Penilaian Dosen](#fase-8-pengujian-qa-screenshot-bukti--penilaian-dosen)
11. [FASE 9: Diagram Arsitektur & Panduan Laporan Akhir](#fase-9-diagram-arsitektur--panduan-laporan-akhir)

---

## 1. PEMENUHAN KETENTUAN TUGAS DOSEN

Rancangan ini dirancang khusus untuk memenuhi 100% rubrik tugas dosen Anda:
* ✅ **Front-end dipisahkan dari back-end pada VM berbeda:** Front-end berada di **VM 1 (`vm-frontend-lb`)**, Back-end berada di **VM 2 (`vm-backend`)**.
* ✅ **Minimal 2 instance application server pada back-end:** VM 2 menjalankan **2 container Node.js** (`backend_instance_1` port 5001 dan `backend_instance_2` port 5002).
* ✅ **Deploy application server sebagai container:** Backend berjalan di atas **Docker & Docker Compose**.
* ✅ **Deploy database pada VM berbeda sebagai container:** Database berada di **VM 3 (`vm-database`)** menjalankan kontainer **MySQL 8.0** dengan *persistent volume*.
* ✅ **Load balancer / reverse proxy:** Menggunakan **Nginx Load Balancer** di VM 1 yang mendistribusikan request secara **Round-Robin** ke 2 container backend.

---

## 2. ARSITEKTUR SISTEM & ALOKASI IP VIRTUALBOX

Setiap VM menggunakan **Dual Network Adapter**:
1. **Adapter 1 (NAT):** Untuk akses internet (update OS, unduh image Docker).
2. **Adapter 2 (Host-Only Network):** Untuk komunikasi privat antar-VM dan akses dari laptop host.

```
                           [ Laptop / Browser Anda ]
                                      │
                     Akses Web: http://192.168.56.101 (atau Cloudflare Tunnel HTTPS)
                                      ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│ VM 1: vm-frontend-lb (RAM: 1.5 GB, 1 vCPU)                                       │
│ Host-Only IP: 192.168.56.101                                                     │
├──────────────────────────────────────────────────────────────────────────────────┤
│  • Nginx Load Balancer Container (Port 80):                                      │
│    - Menyajikan File Flutter Web SPA (/var/www/html/absensi)                     │
│    - Reverse Proxy: location /api/ ──► Round-Robin ke VM 2 (Port 5001 & 5002)    │
└──────────────────────────────────────────┬───────────────────────────────────────┘
                                           │ Komunikasi Internal Host-Only
                                           ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│ VM 2: vm-backend (RAM: 1.5 GB, 1 vCPU)                                           │
│ Host-Only IP: 192.168.56.102                                                     │
├──────────────────────────────────────────────────────────────────────────────────┤
│  • Docker Compose:                                                               │
│    ├── Container 1: backend_instance_1 (Port Host 5001:5000)                     │
│    └── Container 2: backend_instance_2 (Port Host 5002:5000)                     │
│    └── Shared Volume: uploads (Foto selfie presensi)                             │
│  • Header: X-Served-By: <Nama_Instance>                                          │
└──────────────────────────────────────────┬───────────────────────────────────────┘
                                           │ Komunikasi Internal Host-Only
                                           ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│ VM 3: vm-database (RAM: 1 GB, 1 vCPU)                                            │
│ Host-Only IP: 192.168.56.103                                                     │
├──────────────────────────────────────────────────────────────────────────────────┤
│  • Docker Compose:                                                               │
│    └── Container: mysql_database (MySQL 8.0, Port Host 3306)                     │
│    └── Persistent Volume: db_data:/var/lib/mysql                                 │
│  • Database: db_absensi | User: app_user                                         │
└──────────────────────────────────────────────────────────────────────────────────┘
```
> **Total Konsumsi RAM Laptop:** 1.5 GB + 1.5 GB + 1.0 GB = **4.0 GB RAM**. Sangat aman dan lancar di laptop dengan RAM 8 GB atau 16 GB!

---

## FASE 1: DOWNLOAD & PERSIAPAN SOFTWARE

Unduh berkas instalasi berikut jika belum tersedia di laptop Anda:

1. **Oracle VM VirtualBox & Extension Pack:**
   - Link: [virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads)
   - Pasang VirtualBox di Windows, lalu pasang Extension Pack-nya.
2. **ISO Image Ubuntu Server 22.04 LTS (CLI / Tanpa Desktop):**
   - Link resmi: [releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso](https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso)
   - *Catatan:* Pilih versi **Live Server** (ukuran ~2 GB), bukan Desktop, agar hemat RAM dan instalasi sangat cepat.
3. **Git for Windows (Git Bash):**
   - Untuk melakukan SSH dan transfer file (`scp`) dari terminal laptop ke VM VirtualBox.

---

## FASE 2: KONFIGURASI VIRTUALBOX NETWORK (HOST-ONLY)

Agar ketiga VM bisa saling berkomunikasi dengan IP statis dan bisa diakses dari browser laptop:

1. Buka VirtualBox $\rightarrow$ Klik menu **Tools** (ikon garis tiga di kiri atas) $\rightarrow$ Pilih **Network** (atau **Host Network Manager**).
2. Klik tombol **Create** untuk membuat adapter baru bernama `VirtualBox Host-Only Ethernet Adapter`.
3. Klik tab **Adapter**, pastikan pengaturannya:
   * **IPv4 Address:** `192.168.56.1`
   * **IPv4 Network Mask:** `255.255.255.0`
4. Klik tab **DHCP Server**:
   * Centang **Enable Server**.
   * **Server Address:** `192.168.56.2`
   * **Server Mask:** `255.255.255.0`
   * **Lower Address Bound:** `192.168.56.101`
   * **Upper Address Bound:** `192.168.56.254`
5. Klik **Apply**.

---

## FASE 3: INSTALASI VM MASTER & TRIK CLONING CEPAT (HEMAT WAKTU)

> 💡 **Trik Cerdas:** Anda **TIDAK PERLU** menginstall Ubuntu 3 kali dari nol! Cukup install 1 VM Master, pasang Docker di dalamnya, lalu gunakan fitur **Clone** VirtualBox. Dalam 5 menit, Anda sudah punya 3 VM siap pakai!

### Langkah 3.1: Buat VM Master di VirtualBox
1. Klik **New** di VirtualBox:
   * **Name:** `vm-master`
   * **Type:** `Linux`, **Version:** `Ubuntu (64-bit)`
   * **ISO Image:** Pilih file ISO Ubuntu Server 22.04 yang sudah diunduh.
   * Centang **Skip Unattended Installation** (agar kita bisa mengatur username sendiri).
2. **Hardware:**
   * **Base Memory (RAM):** `1536 MB` (1.5 GB)
   * **Processors:** `1 CPU`
3. **Harddisk:**
   * **Virtual Hard disk:** `20.00 GB` (Dynamically Allocated).
4. **Pengaturan Jaringan (PENTING!):**
   * Sebelum menyalakan VM, klik VM `vm-master` $\rightarrow$ klik **Settings** $\rightarrow$ menu **Network**:
     * **Adapter 1:** Attached to: **NAT** (wajib aktif).
     * **Adapter 2:** Centang *Enable Network Adapter* $\rightarrow$ Attached to: **Host-Only Adapter** $\rightarrow$ Name: `VirtualBox Host-Only Ethernet Adapter`.
5. Klik **OK**, lalu nyalakan VM (`Start`).

### Langkah 3.2: Proses Instalasi Ubuntu Server di Layar
1. Pilih bahasa: **English** $\rightarrow$ Keyboard: **English (US)**.
2. Type of install: Pilih **Ubuntu Server (minimized)** (lebih cepat dan ringan).
3. Network connections: Biarkan otomatis (DHCP) $\rightarrow$ Klik **Done**.
4. Configure storage: Gunakan default (Use an entire disk) $\rightarrow$ Klik **Done** $\rightarrow$ **Continue**.
5. Profile setup:
   * **Your name:** `admin`
   * **Your server's name:** `ubuntu-master`
   * **Pick a username:** `ubuntu` *(gunakan username ini agar sama dengan panduan AWS)*
   * **Choose a password:** `admin123` (atau password mudah lainnya)
6. SSH Setup: **Centang "Install OpenSSH server"** (wajib agar bisa kita SSH dari laptop!).
7. Featured Server Snaps: Lewati saja $\rightarrow$ Klik **Done**.
8. Tunggu instalasi selesai, lalu pilih **Reboot Now**. Lepas ISO jika diminta, lalu tekan `Enter`.

### Langkah 3.3: Login & Pasang Docker di VM Master
Setelah reboot, login dengan username `ubuntu` dan password Anda. Lalu jalankan perintah ini:
```bash
# Update sistem dan pasang Docker
sudo apt update && sudo apt install -y docker.io docker-compose-v2 curl net-tools
sudo usermod -aG docker ubuntu

# Matikan VM untuk persiapan cloning
sudo poweroff
```

### Langkah 3.4: Clone Menjadi 3 VM Siap Pakai!
Setelah `vm-master` mati (*Powered Off*):

1. **Buat VM 1:**
   * Klik kanan `vm-master` $\rightarrow$ pilih **Clone**.
   * Name: `vm-frontend-lb`
   * MAC Address Policy: Pilih **Generate new MAC addresses for all network adapters** (Wajib!).
   * Clone type: **Full clone** $\rightarrow$ Klik **Finish**.
2. **Buat VM 2:**
   * Klik kanan `vm-master` $\rightarrow$ pilih **Clone**.
   * Name: `vm-backend`
   * MAC Address Policy: **Generate new MAC addresses...**
   * Clone type: **Full clone** $\rightarrow$ Klik **Finish**.
3. **Buat VM 3:**
   * Klik kanan `vm-master` $\rightarrow$ pilih **Clone**.
   * Name: `vm-database`
   * MAC Address Policy: **Generate new MAC addresses...**
   * Clone type: **Full clone** $\rightarrow$ Klik **Finish**.

> *Sekarang Anda memiliki 3 VM independen lengkap dengan Docker dalam hitungan menit!*

### Langkah 3.5: Nyalakan Ketiga VM & Catat IP Host-Only
Nyalakan ketiga VM (`vm-frontend-lb`, `vm-backend`, `vm-database`).  
Pada masing-masing layar VM, login dan ketik perintah:
```bash
ip a
```
Perhatikan interface kedua (biasanya bernama `enp0s8`). Anda akan melihat alamat IP seperti:
* `vm-frontend-lb`: misal `192.168.56.101`
* `vm-backend`: misal `192.168.56.102`
* `vm-database`: misal `192.168.56.103`

*(Catat ketiga IP ini. Selanjutnya, Anda bisa me-minimize layar VirtualBox dan melakukan semuanya dari terminal Git Bash laptop Anda via SSH!)*

---

## FASE 4: DEPLOYMENT DATABASE TIER DI `vm-database`

### Langkah 4.1: SSH ke `vm-database` dari Laptop
Buka terminal **Git Bash** di laptop Anda:
```bash
ssh ubuntu@192.168.56.103
# Masukkan password VM Anda
```

### Langkah 4.2: Buat Folder dan Salin File Database
Di dalam SSH `vm-database`:
```bash
mkdir -p ~/database
```
Buka jendela Git Bash baru di laptop Anda (pada folder proyek `Absensi_Karyawan`), salin file database:
```bash
scp backend/database/schema.sql backend/database/seed.sql backend/database/docker-compose.yml ubuntu@192.168.56.103:~/database/
```

### Langkah 4.3: Jalankan Kontainer MySQL
Kembali ke terminal SSH `vm-database`:
```bash
cd ~/database
docker compose up -d
docker ps
```
*Pastikan container `mysql_database` berjalan pada port `0.0.0.0:3306->3306/tcp`.*

---

## FASE 5: DEPLOYMENT BACKEND TIER DI `vm-backend` (DUAL CONTAINER)

### Langkah 5.1: Salin Source Code Backend ke `vm-backend`
Dari Git Bash laptop pada folder proyek:
```bash
# Salin seluruh folder backend ke VM 2
scp -r backend/ ubuntu@192.168.56.102:~/
```

### Langkah 5.2: Remote SSH & Konfigurasi `.env` di `vm-backend`
Buka SSH ke `vm-backend`:
```bash
ssh ubuntu@192.168.56.102
cd ~/backend
nano .env
```
Isi konfigurasinya mengarah ke IP `vm-database` (`192.168.56.103`):
```env
PORT=5000
DB_HOST=192.168.56.103
DB_PORT=3306
DB_USER=app_user
DB_PASSWORD=UserAppPassword123!
DB_NAME=db_absensi
JWT_SECRET=rahasia_super_aman_jwt_cloud_computing_2026
```
Simpan (`Ctrl + O`, `Enter`, lalu `Ctrl + X`).

### Langkah 5.3: Build & Jalankan 2 Kontainer Backend
Di terminal `vm-backend`:
```bash
docker compose up -d --build
docker ps
```
Output akan menunjukkan:
* `backend_instance_1` pada port `0.0.0.0:5001->5000/tcp`
* `backend_instance_2` pada port `0.0.0.0:5002->5000/tcp`

### Langkah 5.4: Uji Koneksi Internal
Jalankan uji dari dalam `vm-backend`:
```bash
curl -i http://localhost:5001/api/health
curl -i http://localhost:5002/api/health
```
Periksa header `X-Served-By` muncul sesuai nama container masing-masing.

---

## FASE 6: DEPLOYMENT FRONTEND & NGINX LOAD BALANCER DI `vm-frontend-lb`

Di VM 1, kita akan menjalankan **Nginx Load Balancer di dalam Docker** yang sekaligus melayani berkas statis Flutter Web SPA!

### Langkah 6.1: Build Flutter Web di Laptop
Di terminal laptop Anda (folder proyek):
```bash
flutter build web --release --base-href "/"
```
Hasil build berada di `build/web/`.

### Langkah 6.2: Buat Konfigurasi Nginx Load Balancer
Di folder proyek laptop Anda, kita sudah memiliki konsep Nginx. Mari buat file konfigurasi `nginx-lb.conf`:
```nginx
log_format upstreamlog '[$time_local] $remote_addr - $remote_user to: $upstream_addr: $request status: $status';

# 2 Instance Backend di VM 2 (Round-Robin)
upstream backend_cluster {
    server 192.168.56.102:5001;
    server 192.168.56.102:5002;
}

server {
    listen 80;
    server_name localhost;

    access_log /var/log/nginx/access.log upstreamlog;

    # 1. Melayani Flutter Web SPA
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # 2. Reverse Proxy Load Balancer ke Backend
    location /api/ {
        proxy_pass http://backend_cluster;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass_header X-Served-By;
    }

    # 3. Akses Foto Selfie Presensi
    location /uploads/ {
        proxy_pass http://backend_cluster/uploads/;
        proxy_set_header Host $host;
    }
}
```

### Langkah 6.3: Kirim Build Flutter & Konfigurasi Nginx ke `vm-frontend-lb`
Dari Git Bash di laptop:
```bash
# Buat folder di VM 1
ssh ubuntu@192.168.56.101 "mkdir -p ~/frontend_lb/web"

# Salin build flutter dan config nginx
scp -r build/web/* ubuntu@192.168.56.101:~/frontend_lb/web/
scp nginx-lb.conf ubuntu@192.168.56.101:~/frontend_lb/nginx.conf
```
bau rokok bngtt 
### Langkah 6.4: Jalankan Nginx Load Balancer Kontainer di `vm-frontend-lb`
Login ke `vm-frontend-lb`:
```bash
ssh ubuntu@192.168.56.101
cd ~/frontend_lb

# Jalankan kontainer Nginx
docker run -d \
  --name nginx_load_balancer \
  --restart always \
  -p 80:80 \
  -v $(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf:ro \
  -v $(pwd)/web:/usr/share/nginx/html:ro \
  nginx:alpine

docker ps
```
*Kontainer Nginx aktif pada port 80!*

---

## FASE 7: SOLUSI AKSES KAMERA SELFIE PRESENSI (HTTPS / CLOUDFLARE TUNNEL)

> ⚠️ **Catatan Penting Browser:** Google Chrome memblokir izin kamera jika web dibuka melalui HTTP dengan alamat IP lokal (`http://192.168.56.101`).

Ada 2 cara sangat mudah agar kamera selfie aktif:

### Solusi Terbaik (Gratis & 1 Baris Perintah): Cloudflare Tunnel
Di terminal `vm-frontend-lb`, jalankan utilitas resmi Cloudflare:
```bash
# Unduh binary cloudflared
curl -L --output cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared

# Jalankan tunnel publik gratis
./cloudflared tunnel --url http://localhost:80
```
Terminal akan langsung mencetak URL HTTPS publik, contoh:
```text
https://absensi-test-demo.trycloudflare.com
```
*Buka URL tersebut di Google Chrome laptop atau HP Anda $\rightarrow$ Izin kamera selfie presensi langsung aktif 100%!*

---

## FASE 8: PENGUJIAN QA, SCREENSHOT BUKTI, & PENILAIAN DOSEN

Ambil tangkapan layar untuk setiap skenario berikut (gunakan **Lightshot**):

### 1. Uji Fungsional End-to-End (E2E)
* **SS-E2E-01:** Halaman Login presensi terbuka sempurna di browser.
* **SS-E2E-02:** Registrasi Karyawan baru (sukses).
* **SS-E2E-03:** Login Karyawan baru dan masuk Dashboard.
* **SS-E2E-04:** **Absensi Masuk Kamera Selfie** (foto wajah terambil dan presensi berhasil).
* **SS-E2E-05:** Cek data di MySQL via **DBeaver** dari laptop (Host: `192.168.56.103`, Port: `3306`, User: `app_user`). Query `SELECT * FROM attendances;`.
* **SS-E2E-06:** Absensi Pulang.
* **SS-E2E-07:** Pengajuan Cuti Karyawan.
* **SS-E2E-08:** Login Admin (`admin@company.com` / `admin123`) dan klik **Approve** pengajuan cuti.

### 2. Uji Load Balancing Round-Robin (LB)
* **SS-LB-01 (10 Request Beruntun):**  
  Buka terminal laptop / Postman, kirim request berulang ke API:
  ```bash
  for i in {1..10}; do curl -s -I http://192.168.56.101/api/health | grep -i "x-served-by"; done
  ```
  Screenshot bahwa output bergantian:
  ```text
  X-Served-By: backend_instance_1
  X-Served-By: backend_instance_2
  X-Served-By: backend_instance_1
  X-Served-By: backend_instance_2
  ...
  ```
* **SS-LB-02 (Log Nginx):**  
  Di `vm-frontend-lb`, jalankan `docker logs --tail 20 nginx_load_balancer`. Screenshot bahwa trafik diteruskan ke `192.168.56.102:5001` dan `5002`.

### 3. Uji Redundansi / High Availability (HA)
* **SS-HA-01:** Di `vm-backend`, matikan Container 1:
  ```bash
  docker stop backend_instance_1
  docker ps
  ```
* **SS-HA-02:** Refresh aplikasi web di browser dan lakukan transaksi. Aplikasi **TIDAK DOWN** (*zero downtime*), seluruh request otomatis dilayani oleh Container 2.
* **SS-HA-03:** Nyalakan kembali (`docker start backend_instance_1`).

### 4. Uji Persistensi Basis Data (DB)
* **SS-DB-01:** Di `vm-database`, matikan dan hapus kontainer database:
  ```bash
  docker compose down
  ```
* **SS-DB-02:** Nyalakan kembali database:
  ```bash
  docker compose up -d
  ```
  Buka website presensi atau DBeaver: seluruh akun, riwayat absensi, dan cuti **tetap aman dan tidak hilang** (terbukti tersimpan di volume `mysql_persistent_data`).

---

## FASE 9: DIAGRAM ARSITEKTUR & PANDUAN LAPORAN AKHIR

Buka [app.diagrams.net](https://app.diagrams.net/) untuk membuat 2 diagram:
1. **Diagram Arsitektur Aplikasi:**
   Browser $\rightarrow$ Nginx Load Balancer (Port 80) $\rightarrow$ Upstream Cluster Round-Robin $\rightarrow$ [Backend Instance 1 & 2] $\rightarrow$ MySQL Database Container.
2. **Diagram Arsitektur Deployment (Private Cloud VirtualBox):**
   Gambarkan kotak VirtualBox Host-Only Network (`192.168.56.0/24`), 3 VM Ubuntu Server beserta IP masing-masing (`.101`, `.102`, `.103`), alokasi port host container (`80`, `5001`, `5002`, `3306`), dan aliran trafik.

Semua hasil screenshot dan diagram dimasukkan ke dalam Google Docs sesuai kerangka laporan, lalu diekspor menjadi **PDF** untuk pengumpulan tugas akhir!

