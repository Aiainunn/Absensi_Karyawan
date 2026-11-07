# Skenario Pengujian Sistem dan Verifikasi Cloud (QA Plan)

Dokumen ini memuat skenario pengujian komprehensif yang menjadi tanggung jawab **Peran 5 (QA Tester & Presentation Lead)** untuk memverifikasi fungsionalitas aplikasi, kriteria arsitektur cloud, keamanan jaringan, serta mengumpulkan bukti tangkapan layar (screenshot) untuk laporan dan presentasi.

---

## Standar Penamaan File Screenshot

Semua screenshot diambil menggunakan **Lightshot** atau tool screen capture bawaan, disimpan dengan format PNG beresolusi tinggi, dan diberi nama sesuai konvensi:
```
docs/screenshots/SS-[KATEGORI]-[NO_URUT]-[DESKRIPSI_RINGKAS].png
```
Contoh: `SS-E2E-01-load-spa-frontend.png`

---

## 1. Pengujian Fungsional End-to-End (E2E) dan Transaksi Database

Tujuan: Memastikan seluruh alur bisnis aplikasi presensi berjalan lancar dari browser pengguna melewati Nginx Load Balancer, diproses oleh Application Server Container, dan tersimpan permanen di MySQL Database.

| ID Uji | Nama Skenario | Langkah-Langkah Pengujian | Data Input / Parameter | Hasil yang Diharapkan | Nama File Screenshot |
|:---:|:---|:---|:---|:---|:---|
| **E2E-01** | Akses SPA Front-End via Elastic IP | 1. Buka Google Chrome.<br>2. Masukkan URL: `http://<ELASTIC_IP>`.<br>3. Buka Chrome DevTools (F12) tab *Network* dan *Console*. | URL: `http://<ELASTIC_IP>:80` | Halaman login presensi berhasil dimuat dengan status `200 OK`, aset Flutter ter-load sempurna tanpa error merah di konsol. | `SS-E2E-01-load-spa-frontend.png` |
| **E2E-02** | Registrasi Akun Karyawan Baru | 1. Klik tautan *Daftar Karyawan Baru* pada halaman login.<br>2. Isi form pendaftaran lengkap.<br>3. Klik tombol *Daftar Sekarang*. | Nama: `Ahmad Dahlan`<br>Email: `ahmad@company.com`<br>Pass: `karyawan123`<br>Jabatan: `Staff Operasional` | Notifikasi pendaftaran sukses muncul, dialihkan ke halaman login. Record baru bertambah di tabel `users` MySQL. | `SS-E2E-02-register-karyawan-sukses.png` |
| **E2E-03** | Verifikasi Login Karyawan & Autentikasi | 1. Masukkan email dan password karyawan yang baru didaftarkan.<br>2. Klik tombol *Masuk*. | Email: `ahmad@company.com`<br>Pass: `karyawan123` | Login berhasil, token JWT tersimpan di browser, masuk ke Dashboard Karyawan (`EmployeeHomeScreen`). | `SS-E2E-03-login-karyawan-berhasil.png` |
| **E2E-04** | Transaksi Absensi Masuk (Camera Selfie Check-in) | 1. Pada menu presensi, pilih metode *Kamera / Foto*.<br>2. Ambil foto selfie presensi.<br>3. Klik tombol *Konfirmasi Presensi Masuk*. | Tanggal: Hari ini<br>Metode: `camera`<br>Status: `present` | Sistem menampilkan status *Presensi Masuk Berhasil*. Waktu check-in tercatat. Record tersimpan di tabel `attendances` MySQL. | `SS-E2E-04-transaksi-checkin-kamera.png` |
| **E2E-05** | Verifikasi Data Transaksi di MySQL (DBeaver) | 1. Buka DBeaver via SSH tunnel internal.<br>2. Jalankan query: `SELECT * FROM attendances WHERE user_id = '...';`. | Query tabel `attendances` | Baris baru ditemukan dengan kolom `check_in_time`, `method = 'camera'`, dan status kehadiran sesuai. | `SS-E2E-05-dbeaver-record-attendance.png` |
| **E2E-06** | Transaksi Absensi Pulang (Check-out) | 1. Buka kembali aplikasi sebagai karyawan.<br>2. Klik tombol *Presensi Pulang*.<br>3. Konfirmasi check-out. | Status: Selesai kerja | Status presensi hari ini berubah menjadi selesai kerja. Kolom `check_out_time` di database terisi. | `SS-E2E-06-transaksi-checkout-sukses.png` |
| **E2E-07** | Pengajuan Izin/Cuti oleh Karyawan | 1. Buka tab *Pengajuan Izin*.<br>2. Pilih tipe: `Cuti Tahunan`.<br>3. Masukkan tanggal dan alasan cuti.<br>4. Klik *Kirim Pengajuan*. | Tipe: `leave`<br>Alasan: `Urusan Keluarga`<br>Status: `pending` | Pengajuan berhasil dikirim. Record baru bertambah pada tabel `requests` dengan status awal `pending`. | `SS-E2E-07-pengajuan-cuti-karyawan.png` |
| **E2E-08** | Login Admin & Approval Pengajuan Cuti | 1. Logout dari akun karyawan.<br>2. Login menggunakan akun Admin (`admin@company.com` / `admin123`).<br>3. Buka menu *Manajemen Pengajuan*.<br>4. Klik tombol *Setujui (Approve)* pada pengajuan Ahmad. | Aksi: Setujui permohonan | Status berubah menjadi `approved` di UI Admin dan nilai kolom `status` di tabel `requests` ter-update menjadi `approved`. | `SS-E2E-08-admin-approval-request.png` |

---

## 2. Pengujian Load Balancing (Round-Robin Distribution)

Tujuan: Membuktikan bahwa Nginx di `vm-frontend-lb` secara adil mendistribusikan beban trafik HTTP secara bergantian (Round-Robin) ke Backend Instance 1 (port `5001`) dan Backend Instance 2 (port `5002`) di `vm-backend`.

| ID Uji | Nama Skenario | Langkah-Langkah Pengujian | Indikator Pembuktian | Hasil yang Diharapkan | Nama File Screenshot |
|:---:|:---|:---|:---|:---|:---|
| **LB-01** | Uji Distribusi Trafik 10 Request Beruntun | 1. Buka Postman / script curl.<br>2. Jalankan perintah curl pengujian endpoint health/API sebanyak 10 kali ke `http://<ELASTIC_IP>/api/health`.<br>3. Amati response header `X-Backend-Server` atau payload ID container. | Target: `http://<ELASTIC_IP>/api/health`<br>Jumlah: 10 request berturut-turut | Request bernomor ganjil (1, 3, 5, 7, 9) dijawab oleh `backend_instance_1`, request bernomor genap (2, 4, 6, 8, 10) dijawab oleh `backend_instance_2`. | `SS-LB-01-postman-roundrobin-responses.png` |
| **LB-02** | Verifikasi Log Nginx Upstream (`access.log`) | 1. Buka terminal Termius ke `vm-frontend-lb`.<br>2. Jalankan: `tail -f /var/log/nginx/access.log`.<br>3. Refresh aplikasi di browser beberapa kali. | Log format Nginx dengan variabel `$upstream_addr` | Baris log secara berselang-seling mencatat upstream IP: `10.0.x.x:5001` lalu `10.0.x.x:5002`. | `SS-LB-02-nginx-access-log-roundrobin.png` |
| **LB-03** | Verifikasi Log Container Docker di `vm-backend` | 1. Buka terminal Termius ke `vm-backend`.<br>2. Buka dua split-terminal: `docker logs -f backend_instance_1` dan `docker logs -f backend_instance_2`.<br>3. Lakukan interaksi klik pada aplikasi. | Real-time container log | Kedua jendela log container sama-sama aktif mencetak HTTP request log secara bergantian. | `SS-LB-03-docker-logs-dual-backend.png` |

---

## 3. Pengujian Redundansi dan High Availability (Failover)

Tujuan: Membuktikan arsitektur sistem tahan terhadap kegagalan (fault-tolerant) jika salah satu instance backend mengalami crash atau sengaja dimatikan.

| ID Uji | Nama Skenario | Langkah-Langkah Pengujian | Kondisi Sistem | Hasil yang Diharapkan | Nama File Screenshot |
|:---:|:---|:---|:---|:---|:---|
| **HA-01** | Penghentian Paksa Backend Instance 1 | 1. Di `vm-backend`, jalankan: `docker stop backend_instance_1`.<br>2. Periksa status container dengan `docker ps`. | Satu container mati (`Exited`), satu container tetap hidup (`Up`). | `docker ps` menunjukkan hanya `backend_instance_2` yang aktif berjalan pada port `5002`. | `SS-HA-01-docker-stop-instance1.png` |
| **HA-02** | Uji Transaksi Saat Kondisi Failover | 1. Buka kembali browser pengguna.<br>2. Lakukan transaksi presensi masuk atau refresh data riwayat absensi.<br>3. Amati apakah terjadi downtime/error. | Kondisi: 50% kapasitas backend padam | Aplikasi **TIDAK MENGALAMI DOWN**. Nginx mendeteksi instance 1 tidak merespon dan otomatis mengarahkan seluruh request ke instance 2 tanpa disadari user (zero downtime). | `SS-HA-02-transaksi-sukses-saat-failover.png` |
| **HA-03** | Pemulihan (Recovery) Backend Instance 1 | 1. Di `vm-backend`, jalankan: `docker start backend_instance_1`.<br>2. Kirim kembali request beruntun via Postman. | Kedua container kembali aktif (`Up`). | Nginx otomatis mendeteksi instance 1 telah pulih dan pola pembagian beban Round-Robin kembali normal 50:50. | `SS-HA-03-recovery-instance1-normal.png` |

---

## 4. Pengujian Persistensi Data Database (Data Persistence)

Tujuan: Membuktikan bahwa data transaksi tidak disimpan di memori sementara container, melainkan tersimpan di Docker Persistent Volume pada storage EBS `vm-database`.

| ID Uji | Nama Skenario | Langkah-Langkah Pengujian | Tindakan Pengrusakan | Hasil yang Diharapkan | Nama File Screenshot |
|:---:|:---|:---|:---|:---|:---|
| **DB-01** | Pencatatan Baseline Data Awal | 1. Buka DBeaver.<br>2. Hitung jumlah record pada tabel `users` dan `attendances`: `SELECT COUNT(*) FROM attendances;`. | Catat jumlah awal baris data | Ditemukan jumlah data transaksi aktif sebelum container database dimatikan. | `SS-DB-01-baseline-count-sebelum-down.png` |
| **DB-02** | Penghapusan Container Database (`docker compose down`) | 1. Di `vm-database`, jalankan perintah: `docker compose down`.<br>2. Verifikasi dengan `docker ps -a`. | Container MySQL dihapus total dari proses Docker | Container berstatus hilang/terhapus, namun Docker Volume (`db_data`) tetap dipertahankan oleh Docker Engine. | `SS-DB-02-docker-compose-down-mysql.png` |
| **DB-03** | Rekreasi Container & Verifikasi Keutuhan Data | 1. Di `vm-database`, jalankan: `docker compose up -d`.<br>2. Tunggu container MySQL siap menerima koneksi.<br>3. Buka DBeaver dan jalankan query: `SELECT COUNT(*) FROM attendances;`. | Container baru dibuat dari image awal | Jumlah baris data persis sama seperti baseline awal. Tidak ada data yang hilang atau rusak (Zero Data Loss). | `SS-DB-03-data-utuh-setelah-restart.png` |

---

## 5. Pengujian Keamanan Jaringan dan Port Filtering (Security Test)

Tujuan: Membuktikan penerapan prinsip *Least Privilege* dan *Defense in Depth* bahwa port-port sensitif internal (backend dan database) terlindungi secara ketat oleh AWS Security Group dan UFW dari akses publik.

| ID Uji | Nama Skenario | Langkah-Langkah Pengujian | Target Uji & Port | Hasil yang Diharapkan | Nama File Screenshot |
|:---:|:---|:---|:---|:---|:---|
| **SEC-01** | Uji Akses Publik ke Port Backend (`5001`/`5002`) | 1. Dari laptop pribadi (koneksi publik), buka browser atau jalankan: `curl -I http://<IP_PUBLIK_VM_BACKEND>:5001`. | Port `5001` & `5002` via IP Publik `vm-backend` | **KONEKSI GAGAL / TIMEOUT** (Security Group dan UFW memblokir akses langsung dari internet). | `SS-SEC-01-blokir-port-backend-publik.png` |
| **SEC-02** | Uji Akses Publik ke Port Database (`3306`) | 1. Buka tool DBeaver di laptop.<br>2. Buat koneksi langsung ke `<IP_PUBLIK_VM_DATABASE>:3306`.<br>3. Klik *Test Connection*. | Port `3306` via IP Publik `vm-database` | **KONEKSI GAGAL / CONNECTION REFUSED / TIMEOUT** (Port database tertutup total dari dunia luar). | `SS-SEC-02-blokir-port-database-publik.png` |
| **SEC-03** | Verifikasi Akses Legal Port 80 di `vm-frontend-lb` | 1. Dari laptop pribadi, jalankan: `nmap -p 22,80,443,5001,3306 <ELASTIC_IP>`. | Port scanning terhadap Elastic IP Front-End | Hanya Port `80` (dan `22` jika dari IP tim) yang berstatus `open`, sedangkan port lainnya berstatus `filtered` atau `closed`. | `SS-SEC-03-nmap-audit-frontend-lb.png` |

