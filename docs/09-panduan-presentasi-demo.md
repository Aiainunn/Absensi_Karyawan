# Panduan Presentasi Slide dan Skenario Demo Live

Dokumen ini merupakan panduan lengkap bagi **Peran 5 (QA Tester & Presentation Lead)** dan seluruh anggota tim untuk menyusun materi tayang pada **Google Slides** serta memandu jalannya **Demo Live** di hadapan dosen penguji.

---

## 1. Kerangka Slide Presentasi (12 Slide Efektif)

| No. Slide | Judul Slide | Poin-Poin Kunci yang Harus Ditampilkan | Pembicara Utama |
|:---:|:---|:---|:---:|
| **Slide 1** | **Judul & Identitas Tim** | • Judul Lengkap Proyek.<br>• Nama Mata Kuliah: Cloud Computing.<br>• Nama 5 Anggota, NIM, dan peran spesifiknya. | Moderator (Peran 5) |
| **Slide 2** | **Latar Belakang & Masalah** | • Masalah presensi konvensional (Single Point of Failure, downtime saat jam sibuk masuk kantor).<br>• Solusi: Arsitektur Cloud High Availability & Decoupled Tier. | Peran 4 |
| **Slide 3** | **Spesifikasi & Tools yang Digunakan** | • Cloud: AWS EC2 Ubuntu 22.04 LTS (ap-southeast-1).<br>• Tools: Docker Compose, Nginx, Flutter Web SPA, Termius, DBeaver. | Peran 4 |
| **Slide 4** | **Arsitektur Aplikasi (Logical View)** | • Tampilkan **Diagram 1 Draw.io** (Presentation, Gateway, Application, Data Tier).<br>• Penjelasan komunikasi stateless REST API via JWT Token. | Peran 4 & Peran 2 |
| **Slide 5** | **Arsitektur Deployment Cloud (Topology)** | • Tampilkan **Diagram 2 Draw.io** (3 VM, VPC, Subnet, Elastic IP, Docker Containers).<br>• Strategi isolasi port dan komunikasi IP privat antar-VM. | Peran 1 & Peran 3 |
| **Slide 6** | **Implementasi Tier 1: Front-End & Load Balancer** | • Konfigurasi VM `vm-frontend-lb` (Elastic IP & Port 80).<br>• Screenshot blok upstream Nginx (Round-Robin) & serving static SPA. | Peran 1 |
| **Slide 7** | **Implementasi Tier 2: Multi-Container Backend** | • Konfigurasi VM `vm-backend` (Docker Compose 2 Instance).<br>• Penjelasan port container 5001 & 5002 serta pembatasan IP internal. | Peran 2 |
| **Slide 8** | **Implementasi Tier 3: Database & Persistensi** | • Konfigurasi VM `vm-database` (MySQL 8.0 Container).<br>• Bukti persistent storage Docker Volume (`db_data`) & user non-root. | Peran 3 |
| **Slide 9** | **Hasil Pengujian 1: Transaksi End-to-End** | • Screenshot alur presensi kamera selfie, approval admin, dan verifikasi baris tabel di DBeaver. | Peran 5 |
| **Slide 10** | **Hasil Pengujian 2: Load Balancing (Round-Robin)** | • Bukti pembagian trafik 50:50 (Header `X-Backend-Server` & Log Nginx Upstream). | Peran 5 |
| **Slide 11** | **Hasil Pengujian 3: Redundansi (High Availability)** | • Bukti aplikasi tetap normal saat 1 instance dimatikan (`docker stop`). Zero Downtime! | Peran 5 |
| **Slide 12** | **Kesimpulan & Penutup** | • Ringkasan keberhasilan proyek memenuhi seluruh kriteria cloud computing.<br>• Sesi Tanya Jawab (Q&A). | Seluruh Tim |

---

## 2. Alur Pelaksanaan Demo Live (Durasi: 7–10 Menit)

Saat sesi presentasi, pembicara dapat membagi layar (split-screen) laptop menjadi 2 jendela:
* **Jendela Kiri:** Web Browser (Aplikasi Presensi HadirKu di `http://<ELASTIC_IP>`).
* **Jendela Kanan:** Aplikasi Termius dengan 2 split-tab terminal:
  * Tab 1: Terminal `vm-frontend-lb` menjalankan `tail -f /var/log/nginx/access.log`.
  * Tab 2: Terminal `vm-backend` menjalankan `docker logs -f backend_instance_1` dan `docker logs -f backend_instance_2`.

---

### Langkah Demi Langkah Demonstrasi:

```
[Langkah 1: Demo Fungsional E2E]
  → Tunjukkan Login Karyawan
  → Lakukan Presensi Masuk (Camera Selfie Check-in)
  → Tunjukkan data langsung masuk di DBeaver (MySQL)
           │
           ▼
[Langkah 2: Demo Pembagian Beban (Load Balancing)]
  → Buka tab Network di browser
  → Refresh halaman / lakukan 4x request
  → Sorot terminal Nginx & Docker log:
    Tunjukkan bahwa Request 1 masuk ke Instance 1 (Port 5001)
    Tunjukkan bahwa Request 2 masuk ke Instance 2 (Port 5002)
           │
           ▼
[Langkah 3: Demo Redundansi & Failover (Paling Menentukan Nilai!)]
  → Di terminal vm-backend, ketik: "docker stop backend_instance_1"
  → Tunjukkan ke penguji bahwa Container 1 sudah padam (docker ps)
  → Kembali ke browser, lakukan presensi checkout / refresh data
  → Tunjukkan bahwa web aplikasi SAMA SEKALI TIDAK ERROR / TIDAK DOWN
  → Sorot terminal log bahwa seluruh request otomatis dialihkan ke Container 2
           │
           ▼
[Langkah 4: Demo Pemulihan (Recovery)]
  → Di terminal vm-backend, ketik: "docker start backend_instance_1"
  → Kirim request lagi, tunjukkan pembagian beban kembali normal 50:50
           │
           ▼
[Langkah 5: Demo Keamanan Port (Defense in Depth)]
  → Buka tab browser baru, coba akses langsung: "http://<IP_PUBLIK_VM_BACKEND>:5001"
  → Tunjukkan bahwa browser mengalami TIMEOUT (koneksi ditolak)
  → Buktikan bahwa port backend dan database tertutup rapat dari publik!
```

---

## 3. Lembar Contekan Tanya Jawab Dosen (Q&A Cheat Sheet)

Berikut adalah pertanyaan yang paling sering diajukan oleh dosen penguji Cloud Computing beserta jawaban taktis yang tepat:

### Q1: "Mengapa backend dan database tidak disatukan saja dalam satu VM?"
* **Jawaban:** *"Untuk menerapkan prinsip Decoupled Architecture dan pemisahan beban (Separation of Concerns). Jika database dan backend berada di satu mesin, lonjakan query database akan memakan CPU/RAM yang mengganggu server aplikasi. Selain itu, pemisahan ini meningkatkan keamanan: VM database sama sekali tidak memiliki IP publik terbuka dan hanya bisa diajak bicara oleh IP privat VM backend."*

### Q2: "Bagaimana cara memastikan session login karyawan tidak hilang saat request dialihkan ke container lain oleh Nginx?"
* **Jawaban:** *"Kami menerapkan arsitektur **Stateless JWT (JSON Web Token)**. Seluruh identitas pengguna dienkripsi dalam token digital yang disimpan di client (browser). Baik Container 1 maupun Container 2 memiliki secret key verifikasi yang sama, sehingga container mana pun yang menerima request dapat memvalidasi token tanpa perlu sinkronisasi memori sesi antar-container."*

### Q3: "Mengapa memilih algoritma Round-Robin pada Load Balancer Nginx?"
* **Jawaban:** *"Karena kedua instance backend memiliki spesifikasi container dan resource komputasi yang setara (homogen). Round-Robin memastikan setiap transaksi presensi terdistribusi merata 50:50, mencegah kelebihan beban (overload) pada salah satu instance."*

### Q4: "Apa yang terjadi pada data presensi jika container database rusak atau di-restart?"
* **Jawaban:** *"Data presensi dijamin aman (Zero Data Loss) karena kami menggunakan **Docker Persistent Volume Mount** (`db_data:/var/lib/mysql`). File data database tersimpan di storage volume EBS fisik VM, bukan di layer read-write sementara container. Ketika container dihapus dan dibuat ulang, container baru langsung membaca kembali volume tersebut."*

### Q5: "Bagaimana jika ada hacker yang mencoba melakukan brute force langsung ke port MySQL?"
* **Jawaban:** *"Akses langsung ke port 3306 dari internet publik mustahil dilakukan karena kami menerapkan proteksi **Defense in Depth**: AWS Security Group hanya mengizinkan inbound 3306 dari IP privat `vm-backend`, ditambah firewall lokal OS (UFW) yang memblokir semua koneksi luar kecuali IP privat internal."*

