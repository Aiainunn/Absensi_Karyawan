# Analisis Aplikasi dan Kesiapan Deployment Cloud

Dokumen ini berisi hasil analisis menyeluruh (read-only) terhadap repositori proyek presensi (`absensi`) untuk persiapan Final Project mata kuliah Cloud Computing dengan arsitektur multi-VM pada AWS EC2.

---

## 1. Struktur Folder dan Pemisahan Front-End & Back-End

### Temuan Struktur Folder:
```
absensi/
├── .dart_tool/
├── .idea/
├── android/
├── build/
├── ios/
├── lib/
│   ├── app.dart
│   ├── main.dart
│   ├── config/
│   │   └── theme.dart
│   ├── models/
│   │   ├── attendance_model.dart
│   │   ├── request_model.dart
│   │   ├── schedule_model.dart
│   │   └── user_model.dart
│   ├── providers/
│   │   ├── admin_provider.dart
│   │   ├── attendance_provider.dart
│   │   └── auth_provider.dart
│   ├── screens/
│   │   ├── admin/
│   │   ├── auth/
│   │   └── employee/
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── biometric_service.dart
│   │   ├── firestore_service.dart
│   │   └── local_db_service.dart
│   └── widgets/
├── linux/
├── macos/
├── test/
│   └── widget_test.dart
├── web/
│   ├── favicon.png
│   ├── icons/
│   ├── index.html
│   └── manifest.json
├── windows/
├── .gitignore
├── analysis_options.yaml
├── pubspec.lock
├── pubspec.yaml
└── README.md
```

### Status Pemisahan Front-End dan Back-End:
* **Status:** **TIDAK TERPISAH**.
* **Keterangan:** Repositori saat ini adalah proyek client-side tunggal berbasis Flutter multi-platform. Folder khusus untuk source code Back-End Server mandiri (seperti Node.js/Express, Python/FastAPI, Go, atau PHP/Laravel) **TIDAK DITEMUKAN** di dalam repositori.
* **Mekanisme Saat Ini:** Seluruh logika bisnis diakses langsung dari client Flutter menuju Google Cloud Firestore (`firestore_service.dart`) atau disimpan secara lokal di perangkat via SharedPreferences (`local_db_service.dart`).

---

## 2. Framework dan Versi Front-End, Serta Bukti SPA

* **Framework Front-End:** Flutter Web (Dart SDK `^3.13.3`).
* **Dependensi UI:** `google_fonts: ^6.2.1`, `provider: ^6.1.2`, `flutter_staggered_animations: ^1.1.1`, `cupertino_icons: ^1.0.8`.
* **Bukti Bahwa Ini Adalah Single Page Application (SPA):**
  1. **Entry Point Web Tunggal:** Terdapat file `web/index.html` yang memuat tag `<base href="$FLUTTER_BASE_HREF">` dan script `flutter_bootstrap.js`. Tidak ada file HTML sekunder (multi-page).
  2. **Client-Side Routing:** Navigasi antar halaman (Login, Register, Dashboard Karyawan, Dashboard Admin) ditangani sepenuhnya di sisi client pada `lib/app.dart` menggunakan `MaterialApp`, state `AuthProvider`, dan `Navigator` tanpa memicu refresh halaman browser.
  3. **Build Target Web:** Flutter mengompilasi kode Dart menjadi bundle file statis JavaScript/Wasm (`main.dart.js` atau WebAssembly) yang berjalan di atas satu file `index.html`.

---

## 3. Bahasa/Framework dan Versi Back-End

* **Bahasa / Framework Back-End:** **TIDAK DITEMUKAN**.
* **Port Back-End:** **TIDAK DITEMUKAN**.
* **Entry Point Back-End:** **TIDAK DITEMUKAN**.
* **Perintah Start Back-End:** **TIDAK DITEMUKAN**.
* **Catatan Arsitektur:** Karena tugas mensyaratkan minimal 2 instance container application server pada `vm-backend`, kelompok wajib menyediakan service Back-End REST API terpisah (misalnya menggunakan Node.js/Express atau Python) yang mengimplementasikan antarmuka model data yang ada pada `lib/models/`.

---

## 4. Jenis Database, Versi, Library Koneksi, dan Skema

* **Jenis Database Saat Ini:**
  * **Cloud BaaS:** Cloud Firestore (library: `cloud_firestore: ^6.10.0` pada `pubspec.yaml`).
  * **Local Client Storage:** SharedPreferences (library: `shared_preferences: ^2.5.5` pada `pubspec.yaml`).
* **Database Server Mandiri (MySQL / PostgreSQL / MongoDB):** **TIDAK DITEMUKAN**.
* **Library Koneksi Database Server:** **TIDAK DITEMUKAN**.
* **File Schema / Migration:** **TIDAK DITEMUKAN**.
* **Lokasi Data Seed / Inisialisasi:** Terdapat di dalam kode program lokal pada file `lib/services/local_db_service.dart` baris 52–127 (`_seedInitialDataIfEmpty`), yang berisi akun awal:
  * Admin: `admin@company.com` / `admin123`
  * Employee: `budi@company.com` / `123456`
  * Default jadwal kerja: Senin–Jumat (08:00–17:00).

---

## 5. Variabel Environment

* **File `.env` atau `.env.example`:** **TIDAK DITEMUKAN**.
* **Library Pembaca Environment (misal: `flutter_dotenv`):** **TIDAK DITEMUKAN**.
* **Variabel Environment Front-End:** **TIDAK DITEMUKAN**.
* **Variabel Environment Back-End:** **TIDAK DITEMUKAN**.
* **Kebutuhan yang Harus Dirancang:**
  * Front-End: `API_BASE_URL` (URL endpoint reverse proxy/load balancer).
  * Back-End Container: `PORT`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `JWT_SECRET`.
  * Database Container: `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`.

---

## 6. Lokasi Konfigurasi URL API di Front-End

* **Konfigurasi URL API HTTP/REST Saat Ini:** **TIDAK DITEMUKAN**.
* **File yang Berinteraksi dengan Data Saat Ini:**
  * `lib/services/auth_service.dart` (baris 44–75, 87–120): Menggunakan `FirebaseAuth.instance` dan `LocalDbService`.
  * `lib/services/firestore_service.dart` (baris 17–470): Menggunakan `FirebaseFirestore.instance` dan `LocalDbService`.
  * `lib/providers/attendance_provider.dart` (baris 78–135): Memanggil fungsi-fungsi `_firestoreService`.
* **Titik Modifikasi Wajib:** Untuk menghubungkan SPA ke Load Balancer Nginx, perlu ditambahkan file service baru (misalnya `lib/services/api_service.dart`) atau merefaktor `lib/services/firestore_service.dart` agar mengonsumsi REST API dengan Base URL yang mengarah ke IP publik `vm-frontend-lb` (port 80).

---

## 7. Status File Konfigurasi Deployment

* **`Dockerfile`:** **TIDAK DITEMUKAN**.
* **`docker-compose.yml`:** **TIDAK DITEMUKAN**.
* **`nginx.conf`:** **TIDAK DITEMUKAN**.
* **`.gitignore`:** **ADA**.
  * Isi mencakup: file cache IntelliJ (`.idea/`, `*.iml`), Flutter/Dart (`.dart_tool/`, `.flutter-plugins-dependencies`, `/build/`), sistem operasi (`.DS_Store`), dan artefak rilis Android Studio.
  * Catatan: Aturan untuk file rahasia `.env` dan private key `.pem` **BELUM ADA** di `.gitignore` saat ini dan harus segera ditambahkan agar tidak bocor ke GitHub.

---

## 8. Perintah Build Front-End dan Folder Output

* **Prasyarat Build:** Flutter SDK (versi 3.13.x ke atas) terpasang di environment build.
* **Perintah Build Front-End:**
  ```bash
  flutter build web --release
  ```
* **Folder Output Hasil Build:**
  ```
  build/web/
  ```
  Folder ini berisi file statis `index.html`, `main.dart.js`, `flutter_bootstrap.js`, aset gambar, dan font yang siap disajikan oleh Nginx di `vm-frontend-lb`.

---

## 9. Fitur Aplikasi Utama dan Alur Pengujian End-to-End

Meskipun endpoint REST API HTTP belum dibuat di repositori, struktur model data dan antarmuka aplikasi sudah mendefinisikan fitur-fitur transaksi utama yang menyimpan data ke database:

1. **Autentikasi Pengguna:**
   * Registrasi Karyawan Baru (`lib/screens/auth/register_screen.dart` $\rightarrow$ `UserModel`).
   * Login Multi-Role Admin & Employee (`lib/screens/auth/login_screen.dart`).
2. **Transaksi Presensi (Attendance) - Uji Kunci E2E:**
   * Presensi Masuk dengan Foto/Kamera (`checkInWithCamera` pada `lib/screens/employee/attendance_screen.dart`).
   * Presensi Masuk dengan Sidik Jari (`checkInWithFingerprint` pada `lib/screens/employee/attendance_screen.dart`).
   * Presensi Pulang (`checkOut` pada `lib/screens/employee/attendance_screen.dart`).
3. **Pengelolaan Izin & Cuti (Requests):**
   * Pengajuan Cuti/Sakit oleh Karyawan (`lib/screens/employee/request_screen.dart` $\rightarrow$ `RequestModel`).
   * Persetujuan / Penolakan Pengajuan oleh Admin (`lib/screens/admin/request_management_screen.dart`).
4. **Manajemen Jadwal Kerja (Schedules):**
   * Pengaturan jam masuk & pulang oleh Admin (`lib/screens/admin/schedule_management_screen.dart`).

---

## 10. Daftar Potensi Masalah Deployment dan Analisis Risiko

Berikut adalah inventarisasi risiko teknis deployment beserta tingkat keparahannya:

| No | Potensi Masalah | Lokasi / Komponen | Tingkat Risiko | Penjelasan & Rencana Mitigasi |
|:--:|:---|:---|:---:|:---|
| 1 | **Komponen Back-End Server Belum Ada** | Repositori keseluruhan | **KRITIS (High)** | Repositori hanya berupa client Flutter. Syarat tugas adalah menjalankan 2 container application server di `vm-backend`. **Mitigasi:** Siapkan spesifikasi API kontrak yang presisi dan bangun container image backend REST API sederhana (Node.js/Express atau Python) yang cocok dengan model `UserModel`, `AttendanceModel`, `ScheduleModel`, dan `RequestModel`. |
| 2 | **Data Tersimpan di Local Storage Browser** | `lib/services/local_db_service.dart` | **TINGGI (High)** | `LocalDbService` menggunakan `SharedPreferences` yang menyimpan data di browser masing-masing pengguna. Data tidak akan tersinkronisasi ke database terpusat di `vm-database` jika fitur ini tetap dipakai. **Mitigasi:** Ganti pemanggilan data di Flutter agar murni melalui HTTP REST API. |
| 3 | **Keterbatasan Biometrik Hardware di Browser Web** | `lib/services/biometric_service.dart` (`local_auth`) | **TINGGI (High)** | Plugin `local_auth` mengandalkan sensor sidik jari perangkat native. Pada browser desktop/laptop via Nginx, API biometrik sering kali tidak tersedia atau gagal. **Mitigasi:** Gunakan fitur absensi kamera selfie (`checkInWithCamera`) atau sediakan fallback simulasi biometrik pada UI agar pengujian live demo tidak gagal. |
| 4 | **Isu CORS (Cross-Origin Resource Sharing)** | Nginx di `vm-frontend-lb` & Back-End | **TINGGI (High)** | Karena SPA dimuat dari port 80 dan memanggil API back-end, pemanggilan langsung ke port berbeda akan diblokir oleh browser. **Mitigasi:** Konfigurasikan Nginx sebagai Reverse Proxy terpadu; routing `/api/` langsung diteruskan ke upstream back-end secara internal sehingga browser menganggapnya dalam origin yang sama (same-origin). |
| 5 | **Stateful Session pada 2 Instance Back-End** | Back-End container di `vm-backend` | **TINGGI (High)** | Jika autentikasi menggunakan in-memory session di container, pengguna yang login di Instance 1 akan ter-logout saat load balancer meneruskan request berikutnya ke Instance 2. **Mitigasi:** Wajib menggunakan arsitektur **Stateless JWT (JSON Web Token)** sehingga kedua instance container dapat memvalidasi token tanpa bergantung pada session storage lokal. |
| 6 | **Penyimpanan Upload Foto Selfie pada Disk Lokal Container** | Presensi Kamera (`AttendanceModel.photoUrl`) | **SEDANG (Medium)** | Jika container backend menyimpan file upload di direktori internal container, foto yang diupload ke Instance 1 tidak dapat diakses saat request download ditangani Instance 2. **Mitigasi:** Gunakan Docker Shared Volume antara kedua container back-end atau simpan data foto dalam format base64/URL object. |
| 7 | **Potensi Kebocoran Kredensial (.env dan .pem)** | Root direktori & Git | **KRITIS (High)** | File private key AWS (`.pem`) dan konfigurasi environment (`.env`) dilarang masuk GitHub sesuai ketentuan tugas. Saat ini `.gitignore` belum mengecualikan file `.pem`. **Mitigasi:** Tambahkan aturan `*.pem` dan `*.env*` ke `.gitignore` sebelum push pertama. |

