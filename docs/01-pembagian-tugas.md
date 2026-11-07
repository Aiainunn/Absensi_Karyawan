# Pembagian Tugas dan Tanggung Jawab Kelompok (5 Peran)

Dokumen ini memuat rincian pembagian tugas untuk 5 anggota kelompok, lengkap dengan tools yang ditetapkan, checklist pekerjaan berurutan, input yang dibutuhkan, serta output yang diserahkan.

---

## Ringkasan Matriks Peran

| No | Peran | Nama VM / Lingkup | Fokus Utama |
|:--:|:---|:---|:---|
| 1 | **Cloud Engineer: Frontend & Load Balancer** | `vm-frontend-lb` | Penyediaan VM, Nginx Web Server, Build SPA Flutter, Reverse Proxy & Load Balancer Round-Robin. |
| 2 | **Cloud Engineer: Backend & Containerization** | `vm-backend` | Containerization REST API (2 Instance), Docker Compose, Networking Internal, Stateless Auth (JWT). |
| 3 | **Database & Network Administrator** | `vm-database` | Container Database (MySQL), Persistent Volume, Schema & Seed Import, User Privilege, Keamanan Port Internal. |
| 4 | **System Architect & Technical Writer** | Lintas VM / Google Docs & Draw.io | Desain Diagram Arsitektur Aplikasi & Deployment, Kurasi Konfigurasi, Penyusunan Laporan Proyek Komprehensif. |
| 5 | **QA Tester & Presentation Lead** | Client / Postman / Google Slides | Uji Lokal, Uji E2E Transaksional, Uji Load Balancing & Redundansi, Uji Port Scanning, Slide Presentasi, Demo Live. |

---

## 1. Peran 1: Cloud Engineer (Frontend & Load Balancer)

* **Fokus VM:** `vm-frontend-lb` (AWS EC2, Ubuntu 22.04 LTS, t3.micro, 20 GB Disk).
* **Tools yang Ditetapkan:** AWS Console (EC2, Elastic IP, Security Group), Termius (SSH), Nginx, Git, Flutter SDK / Node.js, UFW.

### Input yang Dibutuhkan:
* IP Privat `vm-backend` dan alokasi port 2 instance backend dari **Peran 2** (contoh: port `5001` dan `5002`).
* Spesifikasi endpoint API dan status kesiapan build dari **Peran 2**.
* Daftar IP publik dan key pair AWS (`.pem`) dari koordinator tim.

### Output yang Diserahkan:
* Alamat IP Publik / Elastic IP `vm-frontend-lb` yang siap diakses browser publik pada port `80`.
* File konfigurasi Nginx (`/etc/nginx/sites-available/default` atau `nginx.conf`) yang berisi routing file statis SPA dan blok `upstream` load balancer round-robin ke 2 instance backend.
* Bukti log akses Nginx (`/var/log/nginx/access.log`) yang menunjukkan pendistribusian request ke backend.

### Checklist Tugas Berurutan:
- [ ] 1. Melakukan provision AWS EC2 Instance `vm-frontend-lb` (Ubuntu 22.04, t3.micro, 20 GB gp3).
- [ ] 2. Mengalokasikan AWS Elastic IP dan melakukan asosiasi (attach) ke instance `vm-frontend-lb`.
- [ ] 3. Mengonfigurasi AWS Security Group untuk `vm-frontend-lb`:
  - Inbound SSH (Port `22`) dari IP publik anggota kelompok.
  - Inbound HTTP (Port `80`) dari `0.0.0.0/0` (Anywhere IPv4).
  - Inbound HTTPS (Port `443`) dari `0.0.0.0/0`.
- [ ] 4. Mengakses instance via Termius menggunakan private key `.pem`.
- [ ] 5. Mengaktifkan dan mengatur firewall UFW di dalam VM:
  - `ufw allow 22/tcp`
  - `ufw allow 80/tcp`
  - `ufw allow 443/tcp`
  - `ufw enable`
- [ ] 6. Menginstal Nginx Web Server (`apt update && apt install -y nginx`).
- [ ] 7. Menyiapkan environment build Flutter SDK atau menyalin hasil artefak `flutter build web --release` ke direktori web root Nginx (`/var/www/html/absensi`).
- [ ] 8. Memastikan base URL API di front-end mengarah ke path relatif `/api` (melewati reverse proxy Nginx).
- [ ] 9. Mengonfigurasi blok server Nginx:
  - Menyajikan SPA Flutter (`root /var/www/html/absensi; try_files $uri $uri/ /index.html;`).
  - Mendefinisikan blok `upstream backend_servers` dengan metode default Round-Robin yang mengarah ke `http://<IP-PRIVAT-VM-BACKEND>:5001` dan `http://<IP-PRIVAT-VM-BACKEND>:5002`.
  - Mengarahkan blok `location /api/` ke `proxy_pass http://backend_servers;`.
- [ ] 10. Melakukan validasi konfigurasi (`nginx -t`) dan restart service (`systemctl restart nginx`).
- [ ] 11. Menyerahkan IP publik dan file konfigurasi Nginx kepada **Peran 4** dan **Peran 5**.

---

## 2. Peran 2: Cloud Engineer (Backend & Containerization)

* **Fokus VM:** `vm-backend` (AWS EC2, Ubuntu 22.04 LTS, t3.micro, 20 GB Disk).
* **Tools yang Ditetapkan:** AWS Console (EC2, Security Group), Termius (SSH), Docker Engine, Docker Compose, Git, UFW, Postman.

### Input yang Dibutuhkan:
* IP Privat `vm-database` dan kredensial database non-root dari **Peran 3**.
* Struktur skema tabel database dan data seed dari **Peran 3**.
* IP Privat `vm-frontend-lb` dari **Peran 1** untuk whitelist firewall.

### Output yang Diserahkan:
* IP Privat `vm-backend` serta nomor port publik host container 1 dan 2 (misal: `5001` dan `5002`) kepada **Peran 1**.
* File `Dockerfile` backend dan `docker-compose.yml` untuk multi-container backend kepada **Peran 4**.
* Hasil pengujian fungsional endpoint API via Postman (JSON response yang menyertakan header/identitas container pemroses) kepada **Peran 5**.

### Checklist Tugas Berurutan:
- [ ] 1. Melakukan provision AWS EC2 Instance `vm-backend` (Ubuntu 22.04, t3.micro, 20 GB gp3).
- [ ] 2. Mengonfigurasi AWS Security Group untuk `vm-backend`:
  - Inbound SSH (Port `22`) dari IP publik anggota kelompok.
  - Inbound Application Port (Port `5001` dan `5002`) **HANYA** dari IP Privat `vm-frontend-lb` (Subnet/CIDR spesifik).
  - Blokir semua akses luar lainnya.
- [ ] 3. Mengakses instance via Termius dan mengonfigurasi UFW:
  - `ufw allow 22/tcp`
  - `ufw allow from <IP_PRIVAT_VM_FRONTEND_LB> to any port 5001 proto tcp`
  - `ufw allow from <IP_PRIVAT_VM_FRONTEND_LB> to any port 5002 proto tcp`
  - `ufw enable`
- [ ] 4. Menginstal Docker Engine dan Docker Compose Plugin di `vm-backend`.
- [ ] 5. Menyiapkan source code Application Server REST API yang menangani model `UserModel`, `AttendanceModel`, `ScheduleModel`, dan `RequestModel`.
- [ ] 6. Membuat `Dockerfile` yang mengoptimasi ukuran image backend dan menyertakan indikator hostname container di response header (untuk pembuktian load balancing).
- [ ] 7. Membuat file konfigurasi environment `.env` di `vm-backend` (berisi koneksi ke IP privat `vm-database`). Memastikan file `.env` tidak ter-commit ke Git.
- [ ] 8. Menyusun file `docker-compose.yml` yang mendefinisikan:
  - `backend_instance_1`: mapping port host `5001:5000`, env koneksi database, restart policy.
  - `backend_instance_2`: mapping port host `5002:5000`, env koneksi database, restart policy.
  - Shared volume untuk penyimpanan foto absensi karyawan (jika disimpan lokal di filesystem container).
- [ ] 9. Menjalankan container dengan `docker compose up -d` dan memverifikasi status container (`docker ps`).
- [ ] 10. Menguji koneksi database dari dalam container backend ke `vm-database`.
- [ ] 11. Melakukan pengujian lokal endpoint API menggunakan `curl` atau Postman dari internal VM.
- [ ] 12. Menyerahkan detail konfigurasi dan port ke **Peran 1**, **Peran 4**, dan **Peran 5**.

---

## 3. Peran 3: Database & Network Administrator

* **Fokus VM:** `vm-database` (AWS EC2, Ubuntu 22.04 LTS, t3.micro, 20 GB Disk).
* **Tools yang Ditetapkan:** AWS Console (EC2, Security Group), Termius (SSH), Docker Engine, Docker Compose, MySQL Server Container, UFW, DBeaver, Google Sheets.

### Input yang Dibutuhkan:
* IP Privat `vm-backend` dari **Peran 2** untuk whitelist akses database.
* Struktur relasi dan atribut data dari model Flutter (`lib/models/` dan `lib/services/local_db_service.dart`).
* IP publik anggota kelompok untuk pengisian tabel network bersama di Google Sheets.

### Output yang Diserahkan:
* IP Privat `vm-database`, port database (`3306`), nama database, username aplikasi khusus (non-root), dan password kepada **Peran 2**.
* File skema SQL (`schema.sql`) dan data seed awal (`seed.sql`) kepada **Peran 4**.
* Dokumen `docs/02-tabel-ip-port.md` yang telah diisi lengkap dan tersinkronisasi di Google Sheets.
* Bukti persistensi data (data tetap ada setelah container database dihapus dan dijalankan ulang) kepada **Peran 5**.

### Checklist Tugas Berurutan:
- [ ] 1. Melakukan provision AWS EC2 Instance `vm-database` (Ubuntu 22.04, t3.micro, 20 GB gp3).
- [ ] 2. Mengonfigurasi AWS Security Group untuk `vm-database`:
  - Inbound SSH (Port `22`) dari IP publik anggota kelompok.
  - Inbound MySQL (Port `3306`) **HANYA** dari IP Privat `vm-backend`.
  - Blokir semua akses dari IP `0.0.0.0/0` untuk port database.
- [ ] 3. Mengakses instance via Termius dan mengonfigurasi UFW:
  - `ufw allow 22/tcp`
  - `ufw allow from <IP_PRIVAT_VM_BACKEND> to any port 3306 proto tcp`
  - `ufw enable`
- [ ] 4. Menginstal Docker Engine dan Docker Compose di `vm-database`.
- [ ] 5. Membuat `docker-compose.yml` untuk container database:
  - Menggunakan image resmi MySQL (misal `mysql:8.0`).
  - Menentukan volume mount persistent (`volumes: - db_data:/var/lib/mysql`).
  - Menentukan environment variable `MYSQL_DATABASE=db_absensi`, `MYSQL_USER=app_user`, `MYSQL_PASSWORD`, dan `MYSQL_ROOT_PASSWORD`.
- [ ] 6. Menjalankan container database (`docker compose up -d`).
- [ ] 7. Membuat file `schema.sql` berdasarkan model entitas aplikasi:
  - Tabel `users`
  - Tabel `attendances`
  - Tabel `schedules`
  - Tabel `requests`
- [ ] 8. Membuat file `seed.sql` berdasarkan data default yang ada pada `local_db_service.dart`:
  - Akun Admin: `admin@company.com` (password hash)
  - Akun Karyawan: `budi@company.com` (password hash)
  - Jadwal default hari kerja Senin–Jumat.
- [ ] 9. Mengimpor file `schema.sql` dan `seed.sql` ke dalam container MySQL.
- [ ] 10. Memastikan user aplikasi (`app_user`) hanya memiliki privilege `SELECT, INSERT, UPDATE, DELETE` pada database `db_absensi`.
- [ ] 11. Menguji koneksi database dari luar secara terkontrol dan memastikan persistensi volume bekerja saat container di-restart.
- [ ] 12. Mengisi seluruh data IP privat, IP publik, dan port pada `docs/02-tabel-ip-port.md` serta Google Sheets tim.

---

## 4. Peran 4: System Architect & Technical Writer

* **Fokus Kerja:** Lintas VM, Dokumentasi Arsitektur, Penulisan Laporan Akhir.
* **Tools yang Ditetapkan:** Draw.io, Google Docs, Visual Studio Code, Git, Google Drive.

### Input yang Dibutuhkan:
* Konfigurasi Security Group, Elastic IP, dan konfigurasi Nginx dari **Peran 1**.
* Dockerfile, Docker Compose, arsitektur port backend dari **Peran 2**.
* Skema database, privilege user, dan data tabel IP/Port dari **Peran 3**.
* Hasil screenshot pengujian dan verifikasi fungsional dari **Peran 5**.
* Catatan kontribusi masing-masing anggota kelompok.

### Output yang Diserahkan:
* File gambar dan source file Draw.io:
  - Diagram Arsitektur Aplikasi (Logika Komponen & Data Flow).
  - Diagram Arsitektur Deployment (Topologi AWS EC2, Subnet, IP Privat, Security Group, Port).
* Draft dan Dokumen Final Laporan Proyek di Google Docs sesuai format evaluasi kampus.
* Deskripsi teknis arsitektur lengkap di folder `docs/`.

### Checklist Tugas Berurutan:
- [ ] 1. Membuat file template laporan di Google Docs berdasarkan kerangka evaluasi tugas besar.
- [ ] 2. Merancang **Diagram Arsitektur Aplikasi** di Draw.io yang menggambarkan relasi SPA Flutter, Load Balancer, 2 Application Server Container, dan Database Container.
- [ ] 3. Merancang **Diagram Arsitektur Deployment** di Draw.io yang memuat:
  - VPC dan Region AWS `ap-southeast-1`.
  - 3 Node VM EC2 (`vm-frontend-lb`, `vm-backend`, `vm-database`).
  - Detail IP Publik, IP Privat, port internal/eksternal, dan arah panah aliran trafik.
  - Blok Security Group dan UFW firewall pada masing-masing VM.
- [ ] 4. Mengekspor diagram ke format PNG resolusi tinggi dan menyimpannya di folder aset laporan.
- [ ] 5. Menuliskan deskripsi teks detail untuk kedua diagram pada `docs/04-kerangka-laporan.md`.
- [ ] 6. Mengumpulkan bukti konfigurasi aktual (cuplikan `nginx.conf`, `docker-compose.yml`, firewall rules) dari Peran 1, 2, dan 3.
- [ ] 7. Menyusun bagian pembagian tugas anggota kelompok dengan jelas dan adil di dalam laporan.
- [ ] 8. Mengintegrasikan narasi analisis sistem, langkah instalasi, konfigurasi, dan bab pembahasan.
- [ ] 9. Memasukkan seluruh screenshot pengujian yang telah dikurasi oleh **Peran 5** ke dalam dokumen laporan.
- [ ] 10. Melakukan review akhir (proofreading), format tata letak, dan konversi laporan ke format PDF untuk pengumpulan.

---

## 5. Peran 5: QA Tester & Presentation Lead

* **Fokus Kerja:** Pengujian End-to-End, Verifikasi Kriteria Cloud, Slide Presentasi & Demo.
* **Tools yang Ditetapkan:** Chrome DevTools, Postman, DBeaver, Lightshot, Google Slides, Google Drive.

### Input yang Dibutuhkan:
* URL publik front-end dari **Peran 1** (`http://<ELASTIC_IP>`).
* URL endpoint backend dan format request/response dari **Peran 2**.
* Kredensial akun uji (Admin dan Karyawan) dari **Peran 3**.
* Diagram arsitektur dan draft laporan dari **Peran 4**.

### Output yang Diserahkan:
* Bundel screenshot pengujian bernomor dan beranotasi rapi di Google Drive sesuai skenario di `docs/03-skenario-pengujian.md`.
* Hasil uji beban / distribusi Round-Robin (bukti kedua instance backend bergantian memproses request).
* Hasil uji failover / redundansi (bukti sistem tetap berjalan saat satu container backend di-stop).
* File slide presentasi final di Google Slides.
* Skenario panduan dan eksekusi demo live saat presentasi di depan dosen/evaluator.

### Checklist Tugas Berurutan:
- [ ] 1. Menjalankan dan menguji aplikasi di lokal pada tahap awal untuk memahami seluruh alur fitur presensi.
- [ ] 2. Menyusun detail checklist skenario pengujian di Google Sheets berdasarkan `docs/03-skenario-pengujian.md`.
- [ ] 3. Menyiapkan tool Lightshot / screen capture dengan resolusi konsisten.
- [ ] 4. Menguji Aksesibilitas Front-End melalui browser (Chrome DevTools Console & Network Tab).
- [ ] 5. Melakukan pengujian Fungsional End-to-End (E2E):
  - Registrasi user baru dan Login Admin/Karyawan.
  - Transaksi Absensi Masuk (Camera/Selfie Check-in) dan Absensi Pulang.
  - Pengajuan Cuti/Izin dan verifikasi status approval di halaman Admin.
  - Memverifikasi data yang diinput benar-benar tersimpan di database MySQL (dicek via DBeaver).
- [ ] 6. Melakukan Pengujian Load Balancing (Round-Robin):
  - Mengirim minimal 10 request berturut-turut via browser/Postman.
  - Memastikan dan mengambil screenshot log Nginx / header response yang menunjukkan trafik terdistribusi 50:50 antara Container 1 dan Container 2.
- [ ] 7. Melakukan Pengujian Redundansi / High Availability:
  - Mematikan salah satu container backend (`docker stop backend_instance_1`).
  - Mengakses kembali aplikasi dan melakukan absensi.
  - Memverifikasi bahwa aplikasi tetap berfungsi normal ditangani oleh Container 2.
- [ ] 8. Melakukan Pengujian Persistensi Database:
  - Mematikan dan menghapus container database (`docker compose down`).
  - Menyalakan kembali container database (`docker compose up -d`).
  - Memverifikasi data absensi yang sudah dibuat sebelumnya tidak hilang.
- [ ] 9. Melakukan Pengujian Keamanan Port (Port Scanning):
  - Mencoba mengakses port backend (`5001`/`5002`) dan port database (`3306`) langsung dari internet publik menggunakan IP publik VM.
  - Memverifikasi bahwa koneksi ditolak/timeout (membuktikan Security Group dan UFW bekerja).
- [ ] 10. Menyusun slide presentasi di Google Slides (latar belakang, arsitektur, konfigurasi, hasil uji, kesimpulan).
- [ ] 11. Memimpin gladi bersih (dry-run) demo presentasi kelompok dan memandu demo live pada hari evaluasi.

