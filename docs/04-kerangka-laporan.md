# Kerangka Laporan Proyek Akhir Cloud Computing

Dokumen ini merupakan panduan dan cetak biru struktur laporan akhir yang akan disusun oleh **Peran 4 (System Architect & Technical Writer)** di **Google Docs**, lengkap dengan penanggung jawab tiap bagian, serta panduan tekstual detail untuk penggambaran diagram arsitektur di **Draw.io**.

---

## 1. Struktur Bab dan Tanggung Jawab Pengisian Laporan

| Bagian / Bab | Judul Sub-bab | Deskripsi Muatan Isi | Peran Penanggung Jawab |
|:---|:---|:---|:---:|
| **Cover & Identitas** | Halaman Judul & Daftar Anggota | Judul proyek, nama mata kuliah, dosen pengampu, nama lengkap & NIM 5 anggota beserta peran spesifiknya. | Peran 4 |
| **Ringkasan** | Executive Summary | Abstrak singkat (1 halaman) mengenai arsitektur cloud multi-tier, hasil uji load balancing, dan ketersediaan tinggi (HA). | Peran 4 |
| **BAB I** | **Pendahuluan** | | |
| 1.1 | Latar Belakang | Urgensi modernisasi deployment aplikasi presensi karyawan dari monolitik/lokal ke arsitektur cloud terdistribusi. | Peran 4 & Peran 5 |
| 1.2 | Tujuan Proyek | Pemenuhan kriteria cloud: decoupling front-end/back-end, containerization, multi-instance, load balancing, keamanan bertingkat. | Peran 4 |
| 1.3 | Batasan Masalah & Lingkup | Penggunaan AWS EC2 Ubuntu 22.04 LTS, Docker Compose, Nginx, region `ap-southeast-1`. | Peran 4 |
| **BAB II** | **Manajemen Tim & Pembagian Tugas** | | |
| 2.1 | Matriks Tanggung Jawab Anggota | Rincian pengerjaan riil tiap anggota (5 peran), checklist tugas selesai, bobot kontribusi, dan tools yang digunakan. | Seluruh Anggota (Dikurasi Peran 4) |
| 2.2 | Linimasa Pengerjaan Proyek | Jadwal tahapan pengerjaan dari tahap perencanaan, provisioning, containerization, integrasi, hingga pengujian. | Peran 4 |
| **BAB III** | **Arsitektur Aplikasi (Application Architecture)** | | |
| 3.1 | Karakteristik Single Page Application (SPA) | Analisis SPA Flutter Web, routing client-side (`MaterialApp`), dan build bundle statis (`index.html`). | Peran 1 & Peran 4 |
| 3.2 | Desain Backend REST API Stateless | Penerapan autentikasi JWT token untuk mendukung arsitektur multi-instance tanpa session replication. | Peran 2 & Peran 4 |
| 3.3 | Desain Basis Data Relasional | Struktur skema tabel (`users`, `attendances`, `schedules`, `requests`) dan normalisasi data. | Peran 3 & Peran 4 |
| 3.4 | Diagram Arsitektur Aplikasi | Gambar Draw.io dan narasi alur logika data antar-komponen. | Peran 4 |
| **BAB IV** | **Arsitektur Deployment Cloud (Cloud Infrastructure)** | | |
| 4.1 | Topologi AWS EC2 Multi-VM | Spesifikasi 3 VM (`vm-frontend-lb`, `vm-backend`, `vm-database`), Elastic IP, dan alokasi VPC Subnet privat. | Peran 1, 2, 3, 4 |
| 4.2 | Mekanisme Load Balancing Round-Robin | Konfigurasi upstream Nginx, algoritma distribusi beban, dan failover otomatis. | Peran 1 & Peran 4 |
| 4.3 | Containerization & Orchestration | Desain Dockerfile dan Docker Compose untuk isolasi runtime backend dan database. | Peran 2, 3, 4 |
| 4.4 | Strategi Keamanan Jaringan (Defense in Depth) | Kombinasi AWS Security Group (perimeter luar) dan UFW (perimeter dalam OS), isolasi port database & backend. | Peran 1, 2, 3, 4 |
| 4.5 | Diagram Arsitektur Deployment | Gambar Draw.io dan narasi topologi infrastruktur cloud lengkap. | Peran 4 |
| **BAB V** | **Implementasi dan Konfigurasi Sistem** | | |
| 5.1 | Konfigurasi VM Front-End & Nginx | File konfigurasi Nginx (`sites-available/default`), upstream block, static asset serving. | Peran 1 |
| 5.2 | Konfigurasi VM Back-End & Docker | File `Dockerfile`, `docker-compose.yml`, environment variable, multi-port container (`5001` & `5002`). | Peran 2 |
| 5.3 | Konfigurasi VM Database & Persistensi | File `docker-compose.yml` MySQL, Docker Volume (`db_data`), eksekusi `schema.sql` dan `seed.sql`. | Peran 3 |
| 5.4 | Tabel Rekapitulasi Alokasi IP dan Port | Dokumentasi final IP privat, IP publik, dan port dari file `docs/02-tabel-ip-port.md`. | Peran 3 & Peran 4 |
| **BAB VI** | **Pengujian Sistem dan Analisis Hasil** | | |
| 6.1 | Pengujian Fungsional End-to-End (E2E) | Bukti screenshot alur login, presensi kamera, checkout, izin, dan verifikasi tabel MySQL di DBeaver. | Peran 5 |
| 6.2 | Pengujian Kinerja Load Balancing | Analisis distribusi 10 request beruntun, log akses Nginx upstream, dan log container backend. | Peran 5 |
| 6.3 | Pengujian Redundansi (High Availability) | Bukti sistem tetap berjalan normal saat Backend Instance 1 dimatikan paksa (`docker stop`). | Peran 5 |
| 6.4 | Pengujian Persistensi Basis Data | Bukti data tetap utuh setelah container database di-down dan dijalankan ulang via volume mount. | Peran 5 |
| 6.5 | Pengujian Keamanan Jaringan & Port | Hasil audit port scanner (Nmap/Curl) yang membuktikan port 5001, 5002, dan 3306 tertutup dari publik. | Peran 5 |
| **BAB VII** | **Kesimpulan dan Rekomendasi** | | |
| 7.1 | Kesimpulan Keberhasilan Proyek | Evaluasi pemenuhan seluruh kriteria tugas besar cloud computing. | Peran 4 & Seluruh Tim |
| 7.2 | Saran Pengembangan Lanjutan | Peluang implementasi Auto-scaling Group, Managed Database (AWS RDS), dan CI/CD Pipeline. | Peran 4 |
| **Lampiran** | Kumpulan Konfigurasi & Source Code | Cuplikan `nginx.conf`, `docker-compose.yml`, `schema.sql`, dan link repositori GitHub. | Peran 4 |

---

## 2. Panduan Teks Detail Pembuatan Diagram di Draw.io (Untuk Peran 4)

Gunakan panduan berikut untuk menggambar diagram di **Draw.io**. Seluruh komponen, label IP/port, kotak pembatas, dan arah panah harus dibuat persis sesuai deskripsi di bawah.

---

### A. DIAGRAM 1: ARSITEKTUR APLIKASI (APPLICATION ARCHITECTURE)
*Fokus: Menggambarkan bagaimana komponen software berinteraksi secara logika data.*

```
+---------------------------------------------------------------------------------------------------+
|                                  DIAGRAM ARSITEKTUR APLIKASI                                      |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [ Klien / Browser Pengguna ]                                                                     |
|             │                                                                                     |
|             │ 1. Mengunduh Bundle SPA (HTML/JS/Wasm/CSS) via Port 80                              |
|             ▼                                                                                     |
|  +─────────────────────────────────────────────────────────────+                                  |
|  | PRESENTATION TIER: Single Page Application (Flutter Web)    |                                  |
|  |  • AuthGate / Navigator (Client-Side Routing)               |                                  |
|  |  • State Management (Provider: Auth, Attendance, Admin)     |                                  |
|  |  • UI Components (AttendanceCard, Glassmorphism, Camera)     |                                  |
|  +─────────────────────────────────────────────────────────────+                                  |
|             │                                                                                     |
|             │ 2. HTTP REST Request JSON (/api/login, /api/attendance/check-in)                    |
|             ▼                                                                                     |
|  +─────────────────────────────────────────────────────────────+                                  |
|  | GATEWAY TIER: Reverse Proxy & Load Balancer (Nginx)         |                                  |
|  |  • Upstream Module (Round-Robin Algorithm)                  |                                  |
|  |  • Proxy Pass Header Injection (Host, X-Real-IP)            |                                  |
|  +─────────────────────────────────────────────────────────────+                                  |
|             │                                                                                     |
|             ├────────────────────────────────────┐                                                |
|             │ 3a. Request Genap (Port 5001)      │ 3b. Request Ganjil (Port 5002)                 |
|             ▼                                    ▼                                                |
|  +──────────────────────────────+   +──────────────────────────────+                              |
|  | APPLICATION TIER: Instance 1 |   | APPLICATION TIER: Instance 2 |                              |
|  | Container (Node.js/Express)  |   | Container (Node.js/Express)  |                              |
|  |  • Stateless JWT Auth Parser |   |  • Stateless JWT Auth Parser |                              |
|  |  • Business Logic Controller |   |  • Business Logic Controller |                              |
|  |  • ORM / SQL Query Builder   |   |  • ORM / SQL Query Builder   |                              |
|  +──────────────────────────────+   +──────────────────────────────+                              |
|             │                                    │                                                |
|             └─────────────────┬──────────────────┘                                                |
|                               │ 4. SQL Protocol Query (TCP Port 3306)                             |
|                               ▼                                                                   |
|  +─────────────────────────────────────────────────────────────+                                  |
|  | DATA TIER: Relational Database (MySQL Container)            |                                  |
|  |  • Tables: users, attendances, schedules, requests          |                                  |
|  |  • Persistent Storage Engine (InnoDB)                       |                                  |
|  +─────────────────────────────────────────────────────────────+                                  |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

#### Komponen Visual Draw.io (Diagram 1):
1. **Presentation Tier (Warna Biru Muda):**
   * Box: `Flutter Web SPA Client`.
   * Keterangan di dalam box: Mengelola tampilan login, presensi kamera selfie, dashboard admin/karyawan, dan routing lokal.
2. **Gateway Tier (Warna Hijau):**
   * Box: `Nginx Load Balancer`.
   * Keterangan: Menerima request path `/api/*` dan membagi beban ke dua server aplikasi secara seimbang.
3. **Application Tier (Warna Oranye):**
   * Dua Box berdampingan: `Backend Instance 1` dan `Backend Instance 2`.
   * Keterangan: Pemrosesan logika absensi, kalkulasi keterlambatan, verifikasi token JWT.
4. **Data Tier (Warna Ungu):**
   * Cylinder Icon: `MySQL Database`.
   * Keterangan: Menyimpan data kredensial, riwayat presensi masuk/pulang, dan data cuti.

---

### B. DIAGRAM 2: ARSITEKTUR DEPLOYMENT CLOUD (CLOUD DEPLOYMENT ARCHITECTURE)
*Fokus: Menggambarkan topologi infrastruktur fisik/virtual AWS EC2, networking, port, IP, dan firewall.*

```
+---------------------------------------------------------------------------------------------------+
|                        AWS CLOUD INFRASTRUCTURE (Region: ap-southeast-1)                          |
|                                                                                                   |
|  VPC: Default VPC (172.31.0.0/16)                                                                 |
|                                                                                                   |
|  [ Internet / Publik User ]                                                                       |
|         │                                                                                         |
|         │ Port 80 (HTTP)                                                                          |
|         ▼                                                                                         |
|  +─────────────────────────────────────────────────────────────────────────────────────────────+  |
|  | INSTANCE 1: vm-frontend-lb (t3.micro, Ubuntu 22.04 LTS, Disk 20GB)                           |  |
|  | • Public IP: AWS Elastic IP (Contoh: 54.254.x.x)                                            |  |
|  | • Private IP: 172.31.x.x_lb                                                                 |  |
|  | • AWS Security Group: sg-frontend-lb (Inbound: 22 dari Tim, 80 & 443 dari 0.0.0.0/0)       |  |
|  | • Host OS Firewall (UFW): ALLOW 22, 80, 443                                                 |  |
|  |                                                                                             |  |
|  |   [ Nginx Web Server (Host Process) ]                                                       |  |
|  |   ├─ Web Root: /var/www/html/absensi (Static SPA Flutter Web)                               |  |
|  |   └─ Upstream round-robin:                                                                  |  |
|  |        → 172.31.x.x_be:5001                                                                 |  |
|  |        → 172.31.x.x_be:5002                                                                 |  |
|  +─────────────────────────────────────────────────────────────────────────────────────────────+  |
|         │                                                                                         |
|         │ JALUR PRIVAT VPC (Subnet Internal - Aman dari Internet)                                 |
|         │ Request Proxy ke Port 5001 & 5002 (Hanya diizinkan dari IP 172.31.x.x_lb)               |
|         ▼                                                                                         |
|  +─────────────────────────────────────────────────────────────────────────────────────────────+  |
|  | INSTANCE 2: vm-backend (t3.micro, Ubuntu 22.04 LTS, Disk 20GB)                               |  |
|  | • Public IP: Dinamis (Hanya untuk SSH tim)                                                  |  |
|  | • Private IP: 172.31.x.x_be                                                                 |  |
|  | • AWS Security Group: sg-backend (Inbound: 22 dari Tim, 5001-5002 HANYA dari 172.31.x.x_lb)  |  |
|  | • Host OS Firewall (UFW): ALLOW 22, ALLOW 5001-5002 from 172.31.x.x_lb                       |  |
|  |                                                                                             |  |
|  |   Docker Engine + Docker Compose:                                                           |  |
|  |   ┌───────────────────────────────────┐     ┌───────────────────────────────────┐           |  |
|  |   | Container: backend_instance_1     |     | Container: backend_instance_2     |           |  |
|  |   | Image: app-backend:latest         |     | Image: app-backend:latest         |           |  |
|  |   | Port Mapping: Host 5001 -> Cont 5000 |   | Port Mapping: Host 5002 -> Cont 5000 |       |  |
|  |   └───────────────────────────────────┘     └───────────────────────────────────┘           |  |
|  |                     │                                         │                             |  |
|  |                     └────────────────────┬────────────────────┘                             |  |
|  +──────────────────────────────────────────┼──────────────────────────────────────────────────+  |
|                                             │                                                     |
|                                             │ JALUR PRIVAT VPC (Subnet Internal)                  |
|                                             │ Koneksi MySQL Port 3306 (HANYA dari 172.31.x.x_be)  |
|                                             ▼                                                     |
|  +─────────────────────────────────────────────────────────────────────────────────────────────+  |
|  | INSTANCE 3: vm-database (t3.micro, Ubuntu 22.04 LTS, Disk 20GB)                              |  |
|  | • Public IP: Dinamis (Hanya untuk SSH tim)                                                  |  |
|  | • Private IP: 172.31.x.x_db                                                                 |  |
|  | • AWS Security Group: sg-database (Inbound: 22 dari Tim, 3306 HANYA dari 172.31.x.x_be)      |  |
|  | • Host OS Firewall (UFW): ALLOW 22, ALLOW 3306 from 172.31.x.x_be                            |  |
|  |                                                                                             |  |
|  |   Docker Engine + Docker Compose:                                                           |  |
|  |   ┌────────────────────────────────────────────────────────┐                                |  |
|  |   | Container: mysql_database (mysql:8.0)                  |                                |  |
|  |   | Port Mapping: Host 3306 -> Cont 3306                   |                                |  |
|  |   | Environment: DB=db_absensi, USER=app_user               |                                |  |
|  |   | Persistent Volume: db_data -> /var/lib/mysql           |                                |  |
|  |   └────────────────────────────────────────────────────────┘                                |  |
|  |                               │                                                             |  |
|  |                               ▼ (Persistent Storage Mount)                                  |  |
|  |                  [ AWS EBS gp3 Storage (20 GB) ]                                            |  |
|  +─────────────────────────────────────────────────────────────────────────────────────────────+  |
|                                                                                                   |
+---------------------------------------------------------------------------------------------------+
```

#### Aturan Tampilan Draw.io (Diagram 2):
1. **Kotak Pembungkus Terluar:** Beri judul `AWS Cloud (ap-southeast-1)` dengan garis putus-putus abu-abu tebal.
2. **Tiga Kotak Mesin VM:**
   * Kotak 1: `vm-frontend-lb` (Label: Elastic IP publik dan Private IP).
   * Kotak 2: `vm-backend` (Di dalamnya terdapat 2 ikon Docker container kotak biru).
   * Kotak 3: `vm-database` (Di dalamnya terdapat ikon Docker container dan silinder EBS Storage).
3. **Pemberian Warna Firewall:** Berikan simbol gembok kecil di setiap pintu masuk port yang menunjukkan pembatasan CIDR IP privat.
4. **Panah Alur:**
   * Panah hijau tebal: Trafik Publik dari user ke Nginx port 80.
   * Panah biru: Trafik privat internal dari Nginx ke backend container (port 5001 & 5002).
   * Panah oranye: Trafik privat internal dari backend container ke database (port 3306).

