# PANDUAN LENGKAP & SISTEMATIS: DEPLOYMENT SISTEM ABSENSI KARYAWAN 3-TIER DI AWS
> **Studi Kasus:** Proyek Cloud Computing — Flutter Web SPA, Nginx Load Balancer (Round-Robin), Dual Backend Container (Node.js/Express), dan MySQL 8.0 Container dengan Persistent Volume.  
> **Target Pelaksana:** Mahasiswa yang merangkap seluruh peran (Peran 1 s/d 5) secara mandiri (*Solo Execution*).

---

## DAFTAR ISI
1. [Daftar Tools & Aplikasi yang Perlu Diunduh (Prerequisites)](#1-daftar-tools--aplikasi-yang-perlu-diunduh-prerequisites)
2. [Arsitektur Sistem & Spesifikasi Target](#2-arsitektur-sistem--spesifikasi-target)
3. [FASE 1: Instalasi & Penyiapan Tools di Komputer Lokal](#fase-1-instalasi--penyiapan-tools-di-komputer-lokal)
4. [FASE 2: Penyesuaian Kode Sumber Lokal (Backend & Flutter)](#fase-2-penyesuaian-kode-sumber-lokal-backend--flutter)
5. [FASE 3: Pembuatan Konfigurasi Docker (Dockerfile & Compose)](#fase-3-pembuatan-konfigurasi-docker-dockerfile--compose)
6. [FASE 4: Kompilasi (Build) Flutter Web Release](#fase-4-kompilasi-build-flutter-web-release)
7. [FASE 5: Provisioning Infrastruktur Cloud AWS (3 VM, Jaringan, & Domain)](#fase-5-provisioning-infrastruktur-cloud-aws-3-vm-jaringan--domain)
8. [FASE 6: Deployment Database Tier di `vm-database`](#fase-6-deployment-database-tier-di-vm-database)
9. [FASE 7: Deployment Backend Tier di `vm-backend` (Dual Container)](#fase-7-deployment-backend-tier-di-vm-backend-dual-container)
10. [FASE 8: Deployment Frontend & Nginx Load Balancer di `vm-frontend-lb`](#fase-8-deployment-frontend--nginx-load-balancer-di-vm-frontend-lb)
11. [FASE 9: Pengujian QA, Pengambilan Screenshot, & Verifikasi Kriteria](#fase-9-pengujian-qa-pengambilan-screenshot--verifikasi-kriteria)
12. [FASE 10: Pembuatan Diagram, Laporan Akhir (PDF), & Slide Presentasi](#fase-10-pembuatan-diagram-laporan-akhir-pdf--slide-presentasi)

---

## 1. DAFTAR TOOLS & APLIKASI YANG PERLU DIUNDUH (PREREQUISITES)

Sebelum memulai pengerjaan, unduh dan pasang aplikasi-aplikasi berikut pada laptop/komputer Anda:

### A. Perangkat Lunak di Komputer Lokal (Windows)
| No | Nama Software | Fungsi / Peran | Link Download Resmi |
|---|---|---|---|
| 1 | **Git for Windows** | Version Control & terminal Git Bash untuk perintah SSH/SCP. | [git-scm.com/download/win](https://git-scm.com/download/win) |
| 2 | **Visual Studio Code** | Code editor untuk memodifikasi kode Flutter, Backend, dan file konfigurasi. | [code.visualstudio.com](https://code.visualstudio.com/) |
| 3 | **Node.js (v18 atau v20 LTS)** | Runtime JavaScript untuk menjalankan & menguji Backend Express di lokal. | [nodejs.org](https://nodejs.org/) |
| 4 | **Flutter SDK (v3.24+)** | Framework untuk mengompilasi Flutter Web SPA (`flutter build web`). | [docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows) |
| 5 | **Google Chrome** | Browser untuk menjalankan Flutter Web, kamera selfie presensi, dan DevTools. | [google.com/chrome](https://www.google.com/chrome/) |
| 6 | **Docker Desktop for Windows** | Engine kontainer lokal untuk menguji Dockerfile dan Compose sebelum ke AWS. | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) |
| 7 | **Termius / OpenSSH Client** | SSH Client dengan antarmuka grafis yang nyaman untuk mengelola 3 VM EC2. | [termius.com](https://termius.com/) *(opsional, bisa pakai Git Bash)* |
| 8 | **DBeaver Community Edition** | Universal Database GUI untuk memeriksa isi tabel MySQL via SSH Tunnel. | [dbeaver.io/download](https://dbeaver.io/download/) |
| 9 | **Postman** | Pengujian endpoint REST API, JWT, upload foto, dan simulasi request berulang. | [postman.com/downloads](https://www.postman.com/downloads/) |
| 10 | **Lightshot / Snipping Tool** | Pengambilan tangkapan layar (screenshot) bukti pengujian dengan anotasi kotak/panah. | [app.prntscr.com](https://app.prntscr.com/) |

### B. Layanan Cloud & Akun Online Gratis
1. **Akun AWS (Amazon Web Services):**
   - Diperlukan untuk provisioning 3 instance EC2 (Tier Free Tier t3.micro/t2.micro).
   - Region yang disepakati: **`ap-southeast-1` (Singapore)**.
2. **Akun DuckDNS (Penyedia Dynamic DNS Gratis):**
   - Website: [duckdns.org](https://www.duckdns.org/)
   - Diperlukan untuk mendapatkan subdomain gratis (contoh: `absensi-kelompok.duckdns.org`) yang diarahkan ke AWS Elastic IP, karena Let's Encrypt membutuhkan domain (tidak bisa menerbitkan SSL untuk IP publik biasa).
3. **Draw.io (Diagrams.net):**
   - Website: [app.diagrams.net](https://app.diagrams.net/)
   - Digunakan untuk menggambar Diagram Arsitektur Aplikasi dan Deployment AWS.
4. **Google Docs & Google Slides:**
   - Digunakan untuk menyusun Laporan Akhir (dikonversi ke PDF) dan Slide Presentasi Ujian.

---

## 2. ARSITEKTUR SISTEM & SPESIFIKASI TARGET

Sistem dibangun menggunakan model 3-Tier terdistribusi pada 3 Virtual Machine (EC2):

```
                                  [ Browser Pengguna ]
                                           │
                                           │ HTTPS (Port 443)
                                           ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│ VM 1: vm-frontend-lb (Ubuntu 22.04 LTS - t3.micro)                               │
│ Public IP: Elastic IP (Terkoneksi ke Domain DuckDNS)                             │
│ Security Group: Port 22 (SSH), Port 80 (HTTP Redirect), Port 443 (HTTPS)         │
├──────────────────────────────────────────────────────────────────────────────────┤
│  • Nginx Web Server: Menyajikan Flutter Web SPA (/var/www/html/absensi)          │
│  • Certbot: Sertifikat SSL/TLS Let's Encrypt Otomatis                            │
│  • Nginx Reverse Proxy & Load Balancer:                                          │
│    location /api/ ───► upstream backend_cluster (Round-Robin 50:50)              │
└──────────────────────────────────────────┬───────────────────────────────────────┘
                                           │ Trafik Internal VPC (Port 5001 & 5002)
                                           ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│ VM 2: vm-backend (Ubuntu 22.04 LTS - t3.micro)                                   │
│ Private IP: 172.31.x.x (Hanya diakses dari vm-frontend-lb)                       │
│ Security Group: Port 22 (SSH Admin), Port 5001 & 5002 (HANYA dari sg-frontend-lb)│
├──────────────────────────────────────────────────────────────────────────────────┤
│  • Docker Engine & Docker Compose:                                               │
│    ├── Container 1: backend_instance_1 (Node.js Express, Host Port 5001)         │
│    └── Container 2: backend_instance_2 (Node.js Express, Host Port 5002)         │
│    └── Shared Volume: uploads_volume (Penyimpanan foto selfie absensi bersama)   │
│  • Header Bukti: X-Served-By: <Container_Hostname>                               │
└──────────────────────────────────────────┬───────────────────────────────────────┘
                                           │ Trafik Internal VPC (Port 3306)
                                           ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│ VM 3: vm-database (Ubuntu 22.04 LTS - t3.micro)                                  │
│ Private IP: 172.31.x.x (Hanya diakses dari vm-backend)                           │
│ Security Group: Port 22 (SSH Admin), Port 3306 (HANYA dari sg-backend)           │
├──────────────────────────────────────────────────────────────────────────────────┤
│  • Docker Engine & Docker Compose:                                               │
│    └── Container: mysql_database (MySQL 8.0)                                     │
│    └── Persistent Volume: db_data:/var/lib/mysql (Data tidak hilang jika restart)│
│  • Database: db_absensi | User: app_user (SELECT, INSERT, UPDATE, DELETE)       │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## FASE 1: INSTALASI & PENYIAPAN TOOLS DI KOMPUTER LOKAL

### Langkah 1.1: Verifikasi Instalasi CLI di Laptop
Buka **PowerShell** atau **Git Bash**, ketik perintah berikut untuk memastikan tool siap:
```bash
git --version
node -v
npm -v
flutter doctor
docker --version
```
*Pastikan Flutter doctor tidak memiliki pesan error kritis pada bagian Chrome & Web development.*

---

## FASE 2: PENYESUAIAN KODE SUMBER LOKAL (BACKEND & FLUTTER)

### Langkah 2.1: Menambahkan Header `X-Served-By` pada Backend Express
Header ini **wajib** ada agar penguji/dosen dapat melihat container mana yang menjawab request pada saat pengujian Load Balancing.

Buka file `backend/src/server.js`, pastikan ada middleware penambahan header sebelum rute didefinisikan:
```javascript
const os = require('os');

// Middleware untuk menyematkan identitas container/host
app.use((req, res, next) => {
    res.setHeader('X-Served-By', process.env.INSTANCE_ID || os.hostname());
    next();
});
```

### Langkah 2.2: Memastikan Rute Upload Foto Presensi Tersedia
Pastikan Express dapat menyajikan file gambar statis dari folder `uploads/`:
```javascript
const path = require('path');
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
```

### Langkah 2.3: Menyesuaikan Frontend Flutter Menggunakan HTTP Client
Aplikasi Flutter asli awalnya menggunakan `local_db_service.dart` atau Firebase mock. Kita harus memastikan request dialihkan ke backend via HTTP.

1. Buka `pubspec.yaml`, pastikan dependensi `http` dan `shared_preferences` tersedia:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     http: ^1.2.0
     shared_preferences: ^2.2.0
   ```
2. Tetapkan Base URL API pada Flutter secara dinamis atau relatif. Karena SPA Flutter Web di-host pada Nginx yang sama dengan reverse proxy `/api/`, gunakan path relatif:
   ```dart
   class AppConfig {
     // Pada Web production, gunakan path relatif '/api' agar otomatis mengikuti domain/HTTPS
     static const String baseUrl = '/api';
   }
   ```
3. Simpan token JWT setelah login sukses:
   ```dart
   final prefs = await SharedPreferences.getInstance();
   await prefs.setString('jwt_token', responseData['token']);
   ```
4. Kirim header Authorization pada setiap request data:
   ```dart
   headers: {
     'Content-Type': 'application/json',
     'Authorization': 'Bearer $token',
   }
   ```

---

## FASE 3: PEMBUATAN KONFIGURASI DOCKER (DOCKERFILE & COMPOSE)

### Langkah 3.1: Membuat `Dockerfile` untuk Backend
Buat file bernama `Dockerfile` di dalam folder `backend/`:
```dockerfile
# Menggunakan Node.js Alpine yang sangat ringan (menghemat RAM t3.micro)
FROM node:20-alpine

# Set direktori kerja
WORKDIR /app

# Salin package json dan install dependencies
COPY package*.json ./
RUN npm install --only=production

# Salin seluruh kode backend
COPY . .

# Buat folder untuk upload foto presensi jika belum ada
RUN mkdir -p uploads

# Port yang diekspos oleh container internal
EXPOSE 5000

# Jalankan server
CMD ["node", "src/server.js"]
```

### Langkah 3.2: Membuat `docker-compose.yml` untuk Backend (`vm-backend`)
Buat file `backend/docker-compose.yml` untuk menjalankan **2 Instance Container** sekaligus:
```yaml
version: '3.8'

services:
  backend_instance_1:
    build: .
    container_name: backend_instance_1
    restart: always
    ports:
      - "5001:5000"
    environment:
      - PORT=5000
      - INSTANCE_ID=backend_instance_1
      - DB_HOST=${DB_HOST}
      - DB_PORT=${DB_PORT:-3306}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_NAME=${DB_NAME}
      - JWT_SECRET=${JWT_SECRET}
    volumes:
      - attendance_uploads:/app/uploads

  backend_instance_2:
    build: .
    container_name: backend_instance_2
    restart: always
    ports:
      - "5002:5000"
    environment:
      - PORT=5000
      - INSTANCE_ID=backend_instance_2
      - DB_HOST=${DB_HOST}
      - DB_PORT=${DB_PORT:-3306}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_NAME=${DB_NAME}
      - JWT_SECRET=${JWT_SECRET}
    volumes:
      - attendance_uploads:/app/uploads

volumes:
  attendance_uploads:
    name: shared_attendance_uploads
```

### Langkah 3.3: Membuat `docker-compose.yml` untuk Database (`vm-database`)
Buat file `backend/database/docker-compose.yml`:
```yaml
version: '3.8'

services:
  db:
    image: mysql:8.0
    container_name: mysql_database
    restart: always
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword123
      MYSQL_DATABASE: db_absensi
      MYSQL_USER: app_user
      MYSQL_PASSWORD: UserAppPassword123!
    volumes:
      - db_data:/var/lib/mysql
      - ./schema.sql:/docker-entrypoint-initdb.d/01-schema.sql
      - ./seed.sql:/docker-entrypoint-initdb.d/02-seed.sql
    command: --default-authentication-plugin=mysql_native_password

volumes:
  db_data:
    name: mysql_persistent_data
```

---

## FASE 4: KOMPILASI (BUILD) FLUTTER WEB RELEASE

> ⚠️ **PERINGATAN PENTING:** Jangan pernah menjalankan `flutter build` di dalam server AWS EC2 t3.micro! Instance t3.micro hanya memiliki 1 GB RAM, proses kompilasi Flutter Web membutuhkan minimal 3–4 GB RAM sehingga server akan langsung *freeze/hang* (OOM Killer).

1. Buka terminal laptop di root folder proyek: `d:\SEMESTER 5\cloud computing\Absensi_Karyawan`
2. Jalankan perintah kompilasi release:
   ```bash
   flutter clean
   flutter pub get
   flutter build web --release --base-href "/"
   ```
3. Hasil build akan berada di direktori `build/web/` (berisi `index.html`, `main.dart.js`, `assets/`, dll). Folder inilah yang nantinya akan di-upload ke Nginx di `vm-frontend-lb`.

---

## FASE 5: PROVISIONING INFRASTRUKTUR CLOUD AWS (3 VM, JARINGAN, & DOMAIN)

### Langkah 5.1: Membuat Key Pair SSH (`.pem`)
1. Buka AWS Console $\rightarrow$ EC2 $\rightarrow$ Region pilih **Asia Pacific (Singapore) ap-southeast-1**.
2. Masuk ke **Network & Security** $\rightarrow$ **Key Pairs** $\rightarrow$ **Create key pair**.
3. Beri nama: `key-absensi-cloud`. Jenis: `RSA`, Format: `.pem`.
4. Simpan file `key-absensi-cloud.pem` di folder laptop yang aman (misalnya: `C:\Users\SALMAN\.ssh\`).

### Langkah 5.2: Membuat 3 Security Groups
Buka menu **EC2 $\rightarrow$ Security Groups $\rightarrow$ Create security group**:

1. **`sg-frontend-lb`:**
   - Inbound Rules:
     - SSH (TCP 22): Source `My IP`
     - HTTP (TCP 80): Source `0.0.0.0/0`
     - HTTPS (TCP 443): Source `0.0.0.0/0`
2. **`sg-backend`:**
   - Inbound Rules:
     - SSH (TCP 22): Source `My IP`
     - Custom TCP (Port 5001): Source $\rightarrow$ pilih Security Group `sg-frontend-lb`
     - Custom TCP (Port 5002): Source $\rightarrow$ pilih Security Group `sg-frontend-lb`
3. **`sg-database`:**
   - Inbound Rules:
     - SSH (TCP 22): Source `My IP`
     - MySQL/Aurora (Port 3306): Source $\rightarrow$ pilih Security Group `sg-backend`

### Langkah 5.3: Meluncurkan (Launch) 3 Instance EC2
Buka **EC2 $\rightarrow$ Instances $\rightarrow$ Launch instances**. Lakukan 3 kali dengan pengaturan:
- **AMI:** Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
- **Instance Type:** `t3.micro` (Free Tier eligible)
- **Key Pair:** Pilih `key-absensi-cloud`
- **Storage:** 20 GiB gp3 Root volume

Rincian ketiga instance:
1. **VM 1:** Beri nama `vm-frontend-lb` $\rightarrow$ Pasang Security Group `sg-frontend-lb`.
2. **VM 2:** Beri nama `vm-backend` $\rightarrow$ Pasang Security Group `sg-backend`.
3. **VM 3:** Beri nama `vm-database` $\rightarrow$ Pasang Security Group `sg-database`.

### Langkah 5.4: Mengalokasikan & Memasang Elastic IP
1. Masuk ke menu **EC2 $\rightarrow$ Elastic IPs $\rightarrow$ Allocate Elastic IP address**.
2. Klik tombol **Allocate**.
3. Pilih Elastic IP yang baru terbuat $\rightarrow$ Klik **Actions** $\rightarrow$ **Associate Elastic IP address**.
4. Pilih Instance: `vm-frontend-lb` $\rightarrow$ Klik **Associate**.

### Langkah 5.5: Mencatat Tabel IP & Port
Buka file `docs/02-tabel-ip-port.md`, lalu catat alamat aktual dari konsol AWS:
- `vm-frontend-lb`: IP Publik (Elastic IP) & IP Privat (contoh: `172.31.10.15`)
- `vm-backend`: IP Privat (contoh: `172.31.12.80`)
- `vm-database`: IP Privat (contoh: `172.31.14.99`)

### Langkah 5.6: Membuat Subdomain di DuckDNS
1. Buka [duckdns.org](https://www.duckdns.org/) dan login.
2. Pada kolom **domains**, ketik nama subdomain yang diinginkan, misal: `absensi-karyawan-cc`.
3. Pada kolom **current ip**, masukkan **Elastic IP** dari `vm-frontend-lb`.
4. Klik **update ip**. Sekarang domain Anda adalah: `absensi-karyawan-cc.duckdns.org`.

---

## FASE 6: DEPLOYMENT DATABASE TIER DI `vm-database`

### Langkah 6.1: Remote SSH ke `vm-database`
Buka Git Bash di laptop Anda:
```bash
ssh -i /path/to/key-absensi-cloud.pem ubuntu@<IP_PUBLIK_VM_DATABASE>
```

### Langkah 6.2: Install Docker Engine
Jalankan perintah ini di dalam VM:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose-v2 ufw
sudo usermod -aG docker ubuntu
newgrp docker
```

### Langkah 6.3: Atur Firewall UFW di `vm-database`
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
# Izinkan port 3306 HANYA dari IP Privat vm-backend
sudo ufw allow from <IP_PRIVAT_VM_BACKEND> to any port 3306 proto tcp
sudo ufw --force enable
sudo ufw status verbose
```

### Langkah 6.4: Buat Direktori & Jalankan Database
```bash
mkdir -p ~/database
cd ~/database
```
Buat file `docker-compose.yml`, `schema.sql`, dan `seed.sql` (bisa di-copy dari laptop via `scp` atau menggunakan editor `nano`).
Salin file dari laptop ke VM menggunakan Git Bash laptop:
```bash
scp -i /path/to/key-absensi-cloud.pem backend/database/* ubuntu@<IP_PUBLIK_VM_DATABASE>:~/database/
```
Kembali ke terminal `vm-database`, jalankan:
```bash
cd ~/database
docker compose up -d
docker ps
```
*Pastikan container `mysql_database` berstatus `Up (healthy)` atau `Up`.*

---

## FASE 7: DEPLOYMENT BACKEND TIER DI `vm-backend` (DUAL CONTAINER)

### Langkah 7.1: Remote SSH ke `vm-backend`
Buka Git Bash di laptop:
```bash
ssh -i /path/to/key-absensi-cloud.pem ubuntu@<IP_PUBLIK_VM_BACKEND>
```

### Langkah 7.2: Install Docker Engine & Setup UFW
```bash
sudo apt update && sudo apt install -y docker.io docker-compose-v2 ufw curl
sudo usermod -aG docker ubuntu
newgrp docker

# Setup UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
# Izinkan port 5001 dan 5002 HANYA dari IP Privat vm-frontend-lb
sudo ufw allow from <IP_PRIVAT_VM_FRONTEND_LB> to any port 5001 proto tcp
sudo ufw allow from <IP_PRIVAT_VM_FRONTEND_LB> to any port 5002 proto tcp
sudo ufw --force enable
```

### Langkah 7.3: Upload Source Code Backend dari Laptop ke `vm-backend`
Dari Git Bash di laptop Anda:
```bash
scp -i /path/to/key-absensi-cloud.pem -r backend/ ubuntu@<IP_PUBLIK_VM_BACKEND>:~/backend-deploy/
```

### Langkah 7.4: Buat File `.env` di `vm-backend`
Di terminal `vm-backend`:
```bash
cd ~/backend-deploy/backend
nano .env
```
Isi konfigurasi berikut (sesuaikan IP Privat Database dan password):
```env
PORT=5000
DB_HOST=<IP_PRIVAT_VM_DATABASE>
DB_PORT=3306
DB_USER=app_user
DB_PASSWORD=UserAppPassword123!
DB_NAME=db_absensi
JWT_SECRET=rahasia_super_aman_jwt_cloud_computing_2026
```
Simpan dengan menekan `Ctrl + O` $\rightarrow$ `Enter`, lalu keluar dengan `Ctrl + X`.

### Langkah 7.5: Build & Nyalakan 2 Kontainer Backend
```bash
docker compose up -d --build
docker ps
```
*Output harus menunjukkan dua kontainer aktif:*
- `backend_instance_1` pada port `0.0.0.0:5001->5000/tcp`
- `backend_instance_2` pada port `0.0.0.0:5002->5000/tcp`

### Langkah 7.6: Uji Verifikasi Endpoint Internal (curl)
Jalankan uji koneksi dari dalam `vm-backend`:
```bash
curl -i http://localhost:5001/api/health
curl -i http://localhost:5002/api/health
```
Periksa apakah header `X-Served-By` muncul dengan nilai `backend_instance_1` dan `backend_instance_2`.

---

## FASE 8: DEPLOYMENT FRONTEND & NGINX LOAD BALANCER DI `vm-frontend-lb`

### Langkah 8.1: Remote SSH ke `vm-frontend-lb`
```bash
ssh -i /path/to/key-absensi-cloud.pem ubuntu@<ELASTIC_IP>
```

### Langkah 8.2: Install Nginx, Certbot, dan UFW
```bash
sudo apt update && sudo apt install -y nginx certbot python3-certbot-nginx ufw
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

### Langkah 8.3: Upload Hasil Build Flutter Web ke Server
Buka Git Bash di laptop Anda, kirim folder `build/web/`:
```bash
scp -i /path/to/key-absensi-cloud.pem -r build/web/* ubuntu@<ELASTIC_IP>:/tmp/
```
Di dalam terminal `vm-frontend-lb`, pindahkan ke folder `/var/www/html/absensi`:
```bash
sudo mkdir -p /var/www/html/absensi
sudo mv /tmp/* /var/www/html/absensi/
sudo chown -R www-data:www-data /var/www/html/absensi
sudo chmod -R 755 /var/www/html/absensi
```

### Langkah 8.4: Penerbitan Sertifikat HTTPS SSL Let's Encrypt
Jalankan Certbot dengan memasukkan domain DuckDNS Anda:
```bash
sudo certbot --nginx -d absensi-karyawan-cc.duckdns.org
```
- Masukkan alamat email Anda saat diminta.
- Setujui Terms of Service (`Y`).
- Certbot akan secara otomatis memverifikasi DNS dan mengonfigurasi SSL di Nginx.

### Langkah 8.5: Konfigurasi Nginx Reverse Proxy & Load Balancer
Buka konfigurasi Nginx:
```bash
sudo nano /etc/nginx/sites-available/default
```

Ganti seluruh isinya dengan konfigurasi terintegrasi berikut:
```nginx
# Format log khusus untuk mencatat alamat IP backend yang menangani request ($upstream_addr)
log_format upstreamlog '[$time_local] $remote_addr - $remote_user to: $upstream_addr: $request uppercase_status: $status bytes: $body_bytes_sent';

# Upstream Load Balancer (Round-Robin 50:50 ke vm-backend)
upstream backend_cluster {
    server <IP_PRIVAT_VM_BACKEND>:5001 max_fails=3 fail_timeout=10s;
    server <IP_PRIVAT_VM_BACKEND>:5002 max_fails=3 fail_timeout=10s;
}

# Redirect HTTP (Port 80) ke HTTPS (Port 443)
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name absensi-karyawan-cc.duckdns.org;
    return 301 https://$host$request_uri;
}

# Blok HTTPS (Port 443)
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name absensi-karyawan-cc.duckdns.org;

    ssl_certificate /etc/letsencrypt/live/absensi-karyawan-cc.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/absensi-karyawan-cc.duckdns.org/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Logging
    access_log /var/log/nginx/access.log upstreamlog;
    error_log /var/log/nginx/error.log;

    # Batas upload file foto presensi (misal max 10MB)
    client_max_body_size 10M;

    # 1. Melayani Flutter Web SPA
    root /var/www/html/absensi;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # 2. Reverse Proxy & Load Balancer ke Backend API
    location /api/ {
        proxy_pass http://backend_cluster;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Teruskan response header dari container (termasuk X-Served-By)
        proxy_pass_header X-Served-By;
    }

    # 3. Akses file foto presensi yang di-upload
    location /uploads/ {
        proxy_pass http://backend_cluster/uploads/;
        proxy_set_header Host $host;
    }
}
```
*Ganti `<IP_PRIVAT_VM_BACKEND>` dan `absensi-karyawan-cc.duckdns.org` dengan data riil Anda.*

### Langkah 8.6: Validasi & Restart Nginx
```bash
sudo nginx -t
sudo systemctl restart nginx
```
Buka browser dan kunjungi: `https://absensi-karyawan-cc.duckdns.org`.  
Pastikan website presensi terbuka dengan icon gembok aman (HTTPS) dan siap digunakan!

---

## FASE 9: PENGUJIAN QA, PENGAMBILAN SCREENSHOT, & VERIFIKASI KRITERIA

Siapkan aplikasi screen capture (**Lightshot**). Semua tangkapan layar wajib disimpan dengan nama file terstruktur sesuai dokumen [03-skenario-pengujian.md](file:///d:/SEMESTER%205/cloud%20computing/Absensi_Karyawan/docs/03-skenario-pengujian.md):

### 1. Uji Fungsional End-to-End (E2E)
- [ ] **SS-E2E-01:** Buka `https://<domain>` di Chrome. Tekan F12 (DevTools tab Network). Screenshot halaman login status `200 OK` dan gembok HTTPS.
- [ ] **SS-E2E-02:** Registrasi Karyawan baru (misal: nama `Budi Pratama`, email `budi@company.com`). Screenshot notifikasi sukses.
- [ ] **SS-E2E-03:** Login menggunakan akun baru. Screenshot masuk ke Dashboard Karyawan dan periksa token JWT di Application Tab/Storage.
- [ ] **SS-E2E-04:** Lakukan **Absensi Masuk** dengan Kamera Selfie. Berikan izin akses kamera (*Allow Camera*). Ambil foto selfie, klik konfirmasi presensi. Screenshot notifikasi presensi berhasil.
- [ ] **SS-E2E-05:** Cek data di MySQL via **DBeaver** (menggunakan SSH Tunnel melalui `vm-backend`). Jalankan query `SELECT * FROM attendances;`. Screenshot baris data presensi yang baru masuk.
- [ ] **SS-E2E-06:** Lakukan **Absensi Pulang**. Screenshot status selesai kerja.
- [ ] **SS-E2E-07:** Ajukan Cuti/Izin melalui menu pengajuan. Screenshot bukti pengajuan berstatus `pending`.
- [ ] **SS-E2E-08:** Logout, lalu Login sebagai Admin (`admin@company.com` / `admin123`). Buka menu Manajemen Pengajuan, klik **Approve**. Screenshot status berubah menjadi `approved`.

### 2. Uji Load Balancing Round-Robin (LB)
- [ ] **SS-LB-01 (Uji 10 Request Beruntun):** Buka Postman / Terminal di laptop, kirim curl 10 kali ke `https://<domain>/api/health`. Screenshot output header `X-Served-By` yang berselang-seling antara `backend_instance_1` dan `backend_instance_2`.
- [ ] **SS-LB-02 (Log Nginx Upstream):** Di terminal `vm-frontend-lb`, jalankan `sudo tail -n 20 /var/log/nginx/access.log`. Screenshot log yang menunjukkan trafik terbagi ke port `5001` dan `5002`.
- [ ] **SS-LB-03 (Log Kontainer Docker Ganda):** Di `vm-backend`, buka 2 terminal: `docker logs -f backend_instance_1` dan `docker logs -f backend_instance_2`. Lakukan klik di web. Screenshot kedua container sama-sama menerima request.

### 3. Uji Redundansi & High Availability / Failover (HA)
- [ ] **SS-HA-01:** Di `vm-backend`, matikan satu instance paksa:
  ```bash
  docker stop backend_instance_1
  docker ps
  ```
  Screenshot bahwa hanya `backend_instance_2` yang aktif.
- [ ] **SS-HA-02:** Buka browser kembali $\rightarrow$ lakukan refresh dan transaksi presensi. Aplikasi **tetap berjalan 100% tanpa error** (*zero downtime*). Screenshot transaksi sukses.
- [ ] **SS-HA-03:** Nyalakan kembali container 1:
  ```bash
  docker start backend_instance_1
  ```
  Screenshot kedua container kembali aktif normal.

### 4. Uji Persistensi Data Database (DB)
- [ ] **SS-DB-01:** Di `vm-database`, matikan dan hapus kontainer database:
  ```bash
  docker compose down
  docker ps -a
  ```
  Screenshot bahwa kontainer sudah tidak ada, namun volume `mysql_persistent_data` masih tersimpan di EBS.
- [ ] **SS-DB-02:** Nyalakan kembali database:
  ```bash
  docker compose up -d
  ```
  Buka kembali website atau DBeaver: verifikasi bahwa data user, riwayat presensi, dan cuti **TIDAK HILANG**. Screenshot data utuh.

### 5. Uji Keamanan Port Jaringan (SEC)
- [ ] **SS-SEC-01 (Port Database Tertutup):** Dari laptop Anda, coba hubungkan DBeaver langsung ke `<IP_PUBLIK_VM_DATABASE>:3306` tanpa SSH Tunnel, atau jalankan di PowerShell: `Test-NetConnection -ComputerName <IP_PUBLIK_VM_DATABASE> -Port 3306`. Screenshot bahwa status **Failed / Timed Out**.
- [ ] **SS-SEC-02 (Port Backend Tertutup):** Akses di browser laptop: `http://<IP_PUBLIK_VM_BACKEND>:5001`. Screenshot bahwa browser menampilkan **This site can't be reached / Connection timed out**. Ini membuktikan aturan Security Group dan UFW bekerja sempurna.

---

## FASE 10: PEMBUATAN DIAGRAM, LAPORAN AKHIR (PDF), & SLIDE PRESENTASI

### Langkah 10.1: Membuat 2 Diagram di Draw.io
Buka [app.diagrams.net](https://app.diagrams.net/):
1. **Diagram Arsitektur Aplikasi:**
   - Gambarkan komponen: User Browser $\rightarrow$ Cloudflare/DNS $\rightarrow$ Nginx (SSL & Static SPA) $\rightarrow$ Reverse Proxy Round-Robin $\rightarrow$ [Backend 1 & Backend 2] $\rightarrow$ MySQL Database.
2. **Diagram Arsitektur Deployment AWS:**
   - Gambarkan VPC AWS Region `ap-southeast-1`.
   - Kotak VM 1 (`vm-frontend-lb`), VM 2 (`vm-backend`), dan VM 3 (`vm-database`).
   - Sertakan label IP Publik, Elastic IP, IP Privat masing-masing VM, Security Group rules, dan panah aliran data internal.
   - Export kedua diagram ke format PNG resolusi tinggi.

### Langkah 10.2: Menyusun Laporan Proyek (PDF)
Gunakan Google Docs dengan menyalin struktur dari [docs/04-kerangka-laporan.md](file:///d:/SEMESTER%205/cloud%20computing/Absensi_Karyawan/docs/04-kerangka-laporan.md):
- **Bab I:** Pendahuluan & Latar Belakang Sistem Presensi Cloud.
- **Bab II:** Analisis Sistem & Kebutuhan (Tabel IP/Port, Matriks Peran).
- **Bab III:** Perancangan Arsitektur (Tempelkan 2 diagram dari Draw.io beserta penjelasan naratifnya).
- **Bab IV:** Implementasi Sistem (Konfigurasi Nginx, Dockerfile, Docker Compose, setup SSL Certbot, UFW).
- **Bab V:** Pengujian & Pembahasan (Tempelkan seluruh screenshot `SS-E2E`, `SS-LB`, `SS-HA`, `SS-DB`, `SS-SEC` beserta tabel keterangannya).
- **Bab VI:** Kesimpulan & Saran.
- Ekspor laporan ke format **PDF**.

### Langkah 10.3: Menyusun Slide Presentasi (Google Slides)
Susun 10–12 slide mengacu pada [docs/09-panduan-presentasi-demo.md](file:///d:/SEMESTER%205/cloud%20computing/Absensi_Karyawan/docs/09-panduan-presentasi-demo.md):
1. Judul & Anggota Tim
2. Latar Belakang & Masalah
3. Solusi Arsitektur 3-Tier di AWS
4. Diagram Arsitektur Aplikasi & Deployment
5. Konfigurasi High Availability & Load Balancing
6. Keamanan Jaringan (Security Groups & UFW)
7. Hasil Uji Beban & Failover
8. Kesimpulan & Penutup

### Langkah 10.4: Skenario Live Demo di Depan Dosen
Siapkan 3 tab browser dan terminal split sebelum maju presentasi:
1. **Tab 1:** Web Presensi `https://<domain>` $\rightarrow$ demokan absen selfie dengan kamera aktif.
2. **Tab 2 (Terminal Split):**
   - Jendela 1: `tail -f /var/log/nginx/access.log` di `vm-frontend-lb`.
   - Jendela 2: `docker stop backend_instance_1` di `vm-backend` untuk mendemonstrasikan sistem tidak down saat container mati.
3. **Tab 3:** DBeaver yang menampilkan data tersimpan langsung di MySQL.

---
*Dokumen ini dibuat otomatis sebagai panduan komprehensif eksekusi mandiri proyek Cloud Computing Absensi Karyawan.*

