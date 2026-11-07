# Urutan Pengerjaan Proyek Cloud Computing (7 Tahap)

Dokumen ini memuat panduan linimasa dan urutan kerja 7 tahap pelaksanaan proyek deployment aplikasi presensi berbasis cloud, yang dirancang secara berurutan dengan kejelasan ketergantungan (dependencies), pelaksana tugas, dan output pada setiap tahap.

---

## Ringkasan Alur 7 Tahap

```
[Tahap 1: Perencanaan & Git]
           │
           ▼
[Tahap 2: Provisioning 3 VM AWS EC2]
           │
           ▼
[Tahap 3: Database Container di vm-database] ─────────┐
           │                                          │ Kredensial DB & IP Privat
           ▼                                          │
[Tahap 4: Dual Backend Container di vm-backend] <─────┘
           │
           │ IP Privat Backend & Port 5001/5002
           ▼
[Tahap 5: Build SPA & Nginx Load Balancer di vm-frontend-lb]
           │
           ▼
[Tahap 6: Pengujian E2E, Load Balancing, HA, & Audit Keamanan]
           │
           ▼
[Tahap 7: Finalisasi Laporan, Slide Presentasi, & Gladi Bersih Demo]
```

---

## Rincian 7 Tahap Pelaksanaan

### TAHAP 1: Analisis Kebutuhan, Pembagian Peran, dan Tata Kelola Repositori
* **Pelaksana:** Seluruh Anggota Kelompok (Dikoordinasi oleh **Peran 4**).
* **Ketergantungan (Prasyarat):** Akses repositori kode sumber aplikasi Flutter presensi.
* **Aktivitas:**
  1. Melakukan briefing kelompok via WhatsApp grup untuk mengonfirmasi pembagian 5 peran.
  2. Menginisialisasi repositori Git dan membuat remote repositori bersama di GitHub.
  3. Memastikan file `.gitignore` sudah mengecualikan private key AWS (`*.pem`) dan environment variable (`*.env*`).
  4. Menyiapkan shared folder Google Drive dan Google Sheets untuk pencatatan IP/Port bersama.
* **Hasil (Deliverable) Tahap 1:**
  - Repositori GitHub siap pakai dengan branching yang disepakati.
  - Dokumen perencanaan di folder `docs/` disetujui seluruh anggota.
  - Link Google Sheets siap menerima entri data network dari Peran 1, 2, dan 3.

---

### TAHAP 2: Provisioning Infrastruktur AWS EC2, Elastic IP, dan Security Groups
* **Pelaksana:** **Peran 1**, **Peran 2**, dan **Peran 3**.
* **Ketergantungan (Prasyarat):** Tahap 1 selesai (Akun AWS aktif dan Region `ap-southeast-1` terpilih).
* **Aktivitas:**
  1. **Peran 1:** Membuat VM `vm-frontend-lb` (Ubuntu 22.04 LTS, t3.micro, 20 GB Disk), membuat Elastic IP dan me-mount ke instance, serta mengatur Security Group `sg-frontend-lb` (Port 22, 80, 443).
  2. **Peran 2:** Membuat VM `vm-backend` (Ubuntu 22.04 LTS, t3.micro, 20 GB Disk) dan Security Group `sg-backend` (Port 22, dan port aplikasi).
  3. **Peran 3:** Membuat VM `vm-database` (Ubuntu 22.04 LTS, t3.micro, 20 GB Disk) dan Security Group `sg-database` (Port 22, dan port 3306).
  4. Seluruh engineer login pertama kali ke VM masing-masing via Termius menggunakan key `.pem`.
* **Hasil (Deliverable) Tahap 2:**
  - 3 instance EC2 berstatus *Running* di region `ap-southeast-1`.
  - Nilai IP Privat dan IP Publik ketiga VM tercatat lengkap di Google Sheets dan file `docs/02-tabel-ip-port.md`.

---

### TAHAP 3: Deployment Basis Data Container dan Inisialisasi Data
* **Pelaksana:** **Peran 3 (Database & Network Administrator)**.
* **Ketergantungan (Prasyarat):** Tahap 2 selesai (IP Privat `vm-backend` sudah diketahui untuk pembatasan firewall).
* **Aktivitas:**
  1. Menginstal Docker Engine dan Docker Compose di `vm-database`.
  2. Mengatur UFW di `vm-database` agar port 3306 **HANYA** menerima koneksi dari IP Privat `vm-backend`.
  3. Mengonfigurasi Security Group `sg-database` untuk mengizinkan port 3306 hanya dari IP Privat `vm-backend`.
  4. Membuat file `docker-compose.yml` MySQL 8.0 dengan persistent volume mount (`db_data:/var/lib/mysql`).
  5. Menjalankan container database dan membuat user non-root (`app_user`).
  6. Mengeksekusi file `schema.sql` (tabel users, attendances, schedules, requests) dan `seed.sql` (akun admin & karyawan default).
  7. Menguji koneksi database internal.
* **Hasil (Deliverable) Tahap 3:**
  - Container MySQL aktif dan stabil dengan data awal yang siap dipakai.
  - Parameter koneksi (IP Privat `vm-database`, Port 3306, nama DB, username, password) diserahkan ke **Peran 2**.

---

### TAHAP 4: Containerization Backend REST API dan Deployment Dual-Instance
* **Pelaksana:** **Peran 2 (Cloud Engineer: Backend & Containerization)**.
* **Ketergantungan (Prasyarat):** Tahap 3 selesai (Database aktif dan kredensial diterima dari Peran 3) serta IP Privat `vm-frontend-lb` diketahui dari Peran 1.
* **Aktivitas:**
  1. Menginstal Docker Engine dan Docker Compose di `vm-backend`.
  2. Mengonfigurasi Security Group `sg-backend` dan UFW agar port 5001 dan 5002 **HANYA** menerima koneksi dari IP Privat `vm-frontend-lb`.
  3. Menyiapkan Dockerfile aplikasi backend REST API.
  4. Menyiapkan file `.env` di server (terhubung ke IP Privat `vm-database`).
  5. Membuat file `docker-compose.yml` yang mendefinisikan 2 service container (`backend_instance_1` pada port host 5001 dan `backend_instance_2` pada port host 5002).
  6. Menjalankan kedua container (`docker compose up -d`).
  7. Menguji endpoint API lokal via `curl` dan Postman dari internal mesin.
* **Hasil (Deliverable) Tahap 4:**
  - 2 instance application server container aktif berjalan pada port 5001 dan 5002.
  - IP Privat `vm-backend` beserta port 5001 dan 5002 diserahkan kepada **Peran 1**.

---

### TAHAP 5: Build Front-End SPA dan Konfigurasi Nginx Load Balancer
* **Pelaksana:** **Peran 1 (Cloud Engineer: Frontend & Load Balancer)**.
* **Ketergantungan (Prasyarat):** Tahap 4 selesai (Backend aktif dan IP Privat `vm-backend:5001` & `:5002` diterima dari Peran 2).
* **Aktivitas:**
  1. Menginstal Nginx di `vm-frontend-lb` dan mengaktifkan UFW (Port 22, 80, 443).
  2. Mengonfigurasi base URL API di front-end agar mengarah ke path relatif `/api/`.
  3. Melakukan build SPA Flutter Web (`flutter build web --release`).
  4. Menempatkan hasil build (`build/web/`) ke folder `/var/www/html/absensi`.
  5. Mengonfigurasi Nginx:
     - Blok `server` port 80 untuk menyajikan SPA statis dengan fallback `index.html`.
     - Blok `upstream backend_servers` berisikan alamat IP privat `vm-backend:5001` dan `vm-backend:5002` (Round-Robin).
     - Blok `location /api/` sebagai reverse proxy yang meneruskan request ke `backend_servers`.
  6. Memvalidasi sintaks Nginx (`nginx -t`) dan reload service (`systemctl reload nginx`).
  7. Membuka browser publik menuju `http://<ELASTIC_IP>` untuk verifikasi akses awal.
* **Hasil (Deliverable) Tahap 5:**
  - Aplikasi presensi dapat diakses publik secara utuh melalui browser via Elastic IP pada port 80.
  - Nginx berhasil meneruskan request API secara seimbang ke kedua instance backend.

---

### TAHAP 6: Pengujian Terpadu, Load Balancing, Failover, dan Pengumpulan Bukti
* **Pelaksana:** **Peran 5 (QA Tester & Presentation Lead)** didampingi seluruh anggota.
* **Ketergantungan (Prasyarat):** Tahap 5 selesai (Sistem terintegrasi penuh dari Front-End hingga Database).
* **Aktivitas:**
  1. Menjalankan seluruh skenario pengujian sesuai dokumen `docs/03-skenario-pengujian.md`:
     - **Uji E2E:** Registrasi akun, Login multi-role, Absensi Kamera Selfie, Absensi Pulang, Pengajuan Cuti, dan Approval Admin.
     - **Verifikasi DB:** Mengecek record data langsung di MySQL menggunakan DBeaver via SSH tunnel.
     - **Uji Load Balancing:** Mengirim 10 request beruntun, memeriksa log Nginx upstream (`access.log`), dan log container Docker.
     - **Uji Redundansi (HA):** Menghentikan `backend_instance_1` (`docker stop`), memastikan aplikasi tetap hidup dilayani instance 2.
     - **Uji Persistensi:** Menghapus container MySQL (`docker compose down`), menyalakan kembali (`up -d`), memverifikasi data tidak hilang.
     - **Uji Port Filtering:** Memastikan port 5001, 5002, dan 3306 tidak bisa diakses langsung dari IP publik internet.
  2. Mengambil tangkapan layar (screenshot) beresolusi tinggi dengan Lightshot untuk setiap skenario uji.
  3. Menamai seluruh file screenshot sesuai standar penamaan dan mengunggahnya ke Google Drive tim.
* **Hasil (Deliverable) Tahap 6:**
  - Bundel lengkap screenshot hasil pengujian bernomor (kategori E2E, LB, HA, DB, SEC).
  - Lembar hasil uji verifikasi yang telah tercentang *PASS* di Google Sheets.

---

### TAHAP 7: Finalisasi Laporan, Slide Presentasi, dan Gladi Bersih Demo Live
* **Pelaksana:** **Peran 4 (Laporan)** dan **Peran 5 (Slide & Demo)** bersama seluruh tim.
* **Ketergantungan (Prasyarat):** Tahap 6 selesai (Seluruh data konfigurasi dan screenshot pengujian telah terkumpul).
* **Aktivitas:**
  1. **Peran 4:**
     - Menggambar Diagram Arsitektur Aplikasi dan Diagram Arsitektur Deployment di Draw.io sesuai deskripsi teks di `docs/04-kerangka-laporan.md`.
     - Mengintegrasikan diagram, narasi implementasi, tabel IP/Port, matriks peran, dan screenshot pengujian ke dalam Google Docs.
     - Melakukan review kepatuhan terhadap rubrik penilaian tugas besar cloud computing.
     - Mengekspor laporan final ke format PDF.
  2. **Peran 5:**
     - Menyusun materi presentasi di Google Slides (Maksimal 12–15 slide terstruktur).
     - Menyiapkan alur skenario demo live (menampilkan browser aplikasi, terminal split log load balancing, dan uji failover container).
     - Mengadakan gladi bersih (dry-run) bersama 5 anggota kelompok untuk memastikan manajemen waktu presentasi optimal.
* **Hasil (Deliverable) Tahap 7:**
  - File Laporan Akhir (PDF) siap dikumpulkan di portal akademik.
  - Slide Presentasi (Google Slides) siap tayang.
  - Tim siap 100% melakukan presentasi dan demo langsung di depan dosen pengampu.

