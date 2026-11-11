# Panduan Revisi Dokumen 07 dan 06 --- Sistem Absensi Karyawan

Dokumen ini berisi perubahan yang perlu diterapkan pada:

-   `07-skema-database.md`
-   `06-spesifikasi-api.md`

Tujuan revisi adalah menyelaraskan kontrak REST API dengan struktur
MySQL, memperbaiki beberapa potensi masalah SQL, dan menetapkan aturan
**satu record presensi per karyawan per tanggal**.

> Catatan: Pertahankan teknologi dan rancangan kelompok: Flutter
> Web/Android, Node.js + Express, MySQL 8.0, Docker, Nginx, dan AWS EC2.
> Bagian yang tidak disebutkan di bawah tetap mengikuti dokumen asli.

------------------------------------------------------------------------

# BAGIAN A --- Revisi `07-skema-database.md`

## A.1. Spesifikasi database

Pertahankan spesifikasi berikut:

  -----------------------------------------------------------------------
  Properti                            Nilai
  ----------------------------------- -----------------------------------
  RDBMS                               MySQL 8.0

  Storage engine                      InnoDB

  Character set                       `utf8mb4`

  Collation                           `utf8mb4_unicode_ci`

  Nama database                       `db_absensi`

  User aplikasi                       `app_user`

  Hak akses aplikasi                  `SELECT`, `INSERT`, `UPDATE`,
                                      `DELETE` pada `db_absensi.*`
  -----------------------------------------------------------------------

Untuk pengembangan lokal, database boleh dijalankan melalui MySQL
Laragon. Saat deployment, database dijalankan dalam container MySQL pada
VM database yang terpisah sesuai arsitektur kelompok.

## A.2. Revisi tabel `users`

Pada tabel `users`, kolom `email` sudah memiliki constraint `UNIQUE`.
Karena itu, index tambahan `idx_user_email` tidak diperlukan.

Gunakan bagian akhir definisi tabel seperti berikut:

``` sql
    PRIMARY KEY (uid),
    UNIQUE KEY uq_users_email (email),
    INDEX idx_user_role (role)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
```

Jika definisi tabel masih menggunakan
`email VARCHAR(100) NOT NULL UNIQUE`, jangan menambahkan
`UNIQUE KEY uq_users_email` lagi. Pilih salah satu cara deklarasi unique
constraint saja. Rekomendasi: gunakan `email VARCHAR(100) NOT NULL` dan
`UNIQUE KEY uq_users_email (email)` pada bagian constraint.

## A.3. Revisi tabel `schedules`

Pertahankan `uid` dengan nilai default `'all'` untuk menandakan jadwal
berlaku global. Kolom ini tidak diberi foreign key ke `users`, karena
nilai `'all'` bukan UID pengguna.

Pertahankan `start_time` dan `end_time` sebagai `VARCHAR(10)` selama
kontrak API masih mengirim `'--:--'` untuk hari libur. Dengan demikian,
format database tetap cocok dengan contoh response API.

Pastikan ada komentar yang menjelaskan: - `uid = 'all'`: jadwal global
untuk semua karyawan. - `uid` selain `'all'`: jadwal khusus untuk
karyawan tertentu. - `day_of_week`: menggunakan nama hari bahasa Inggris
huruf kecil, misalnya `monday` sampai `sunday`. - `start_time` dan
`end_time`: format `HH:mm`; jadwal libur menggunakan `'--:--'`.

**Catatan pengembangan:** Jika kelak jadwal per karyawan benar-benar
digunakan, backend perlu memprioritaskan jadwal khusus pengguna dan
menggunakan jadwal global sebagai fallback. Kontrak API saat ini belum
menjelaskan aturan prioritas tersebut, sehingga jangan
mengimplementasikannya diam-diam tanpa kesepakatan tim.

## A.4. Revisi tabel `attendances`

Ini merupakan perubahan utama berdasarkan keputusan kelompok.

**Aturan bisnis: satu karyawan hanya boleh memiliki satu record presensi
untuk satu tanggal.** Check-in membuat record; check-out memperbarui
record yang sama.

Tambahkan constraint unik gabungan:

``` sql
UNIQUE KEY uq_attendance_uid_date (uid, `date`)
```

Contoh definisi tabel yang direkomendasikan:

``` sql
CREATE TABLE IF NOT EXISTS attendances (
    id VARCHAR(50) NOT NULL,
    uid VARCHAR(50) NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    `date` DATE NOT NULL,
    check_in DATETIME NULL,
    check_out DATETIME NULL,
    method ENUM('camera', 'fingerprint') NOT NULL DEFAULT 'camera',
    status ENUM('present', 'late', 'absent', 'permission') NOT NULL DEFAULT 'present',
    work_hours DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    photo_url LONGTEXT NULL,
    note TEXT DEFAULT (''),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    CONSTRAINT fk_attendances_user
        FOREIGN KEY (uid) REFERENCES users(uid)
        ON DELETE CASCADE,

    UNIQUE KEY uq_attendance_uid_date (uid, `date`),
    INDEX idx_attendance_date (`date`),
    INDEX idx_attendance_status (status)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
```

Penjelasan: - `UNIQUE KEY uq_attendance_uid_date (uid, date)` mencegah
dua record presensi untuk pengguna yang sama pada tanggal yang sama. -
`work_hours` diubah menjadi `DECIMAL(5,2)` agar rentang jam lebih
longgar daripada `DECIMAL(4,2)`. - Kolom `date` diberi backtick agar
tidak berbenturan dengan penggunaan kata `DATE` sebagai tipe data/fungsi
SQL. - `note TEXT DEFAULT ('')` menggunakan ekspresi default yang
didukung MySQL 8.0.30.

Backend tetap harus memeriksa kondisi presensi dan memberikan pesan
kesalahan yang mudah dipahami. Constraint unik merupakan lapisan
perlindungan tambahan di database, bukan pengganti validasi backend.

## A.5. Revisi tabel `requests`

Gunakan ekspresi default untuk kolom `TEXT` agar kompatibel dengan MySQL
8.0.30.

``` sql
CREATE TABLE IF NOT EXISTS requests (
    id VARCHAR(50) NOT NULL,
    uid VARCHAR(50) NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    type ENUM('leave', 'overtime', 'resignation', 'sick', 'permission') NOT NULL,
    reason TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    admin_note TEXT DEFAULT (''),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NULL DEFAULT NULL
        ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    CONSTRAINT fk_requests_user
        FOREIGN KEY (uid) REFERENCES users(uid)
        ON DELETE CASCADE,

    INDEX idx_request_user (uid),
    INDEX idx_request_status (status)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
```

## A.6. Revisi data awal / seed

Jangan menggunakan hash bcrypt contoh yang belum diverifikasi. Hash yang
tertulis pada komentar dokumen lama tidak sama dengan hash yang
dimasukkan oleh perintah `INSERT`, dan hash akun karyawan perlu
dipastikan benar-benar cocok dengan password yang didokumentasikan.

Password awal yang disepakati:

  Role       Email                 Password awal
  ---------- --------------------- ---------------
  Admin      `admin@company.com`   `admin123`
  Employee   `budi@company.com`    `123456`

Buat hash menggunakan `bcryptjs` yang sudah menjadi dependency backend.
Dari folder `backend`, jalankan:

``` powershell
node -e "const bcrypt=require('bcryptjs'); console.log('ADMIN:',bcrypt.hashSync('admin123',10)); console.log('EMPLOYEE:',bcrypt.hashSync('123456',10));"
```

Salin hasil hash ke kolom `password_hash` pada `seed.sql`. Jangan
menyimpan password plaintext di database. Setelah itu, verifikasi kedua
hash:

``` powershell
node -e "const bcrypt=require('bcryptjs'); const a='TEMPEL_HASH_ADMIN'; const e='TEMPEL_HASH_EMPLOYEE'; console.log('Admin:',bcrypt.compareSync('admin123',a)); console.log('Employee:',bcrypt.compareSync('123456',e));"
```

Hasil keduanya harus `true`. Ganti `TEMPEL_HASH_ADMIN` dan
`TEMPEL_HASH_EMPLOYEE` dengan hash sebenarnya sebelum menjalankan
perintah verifikasi.

Pada seed, gunakan `ON DUPLICATE KEY UPDATE` secara hati-hati.
Rekomendasi untuk data awal pengguna adalah memperbarui hanya kolom yang
memang ingin disinkronkan, dan jangan menimpa password pengguna yang
sudah diubah. Untuk lingkungan praktikum baru, seed dapat dijalankan
pada database kosong.

Jadwal Senin sampai Minggu tetap mengikuti kontrak awal: - Senin--Kamis:
`08:00`--`17:00`, aktif. - Jumat: `08:00`--`17:00`, aktif. -
Sabtu--Minggu: `'--:--'`--`'--:--'`, tidak aktif.

## A.7. Revisi prosedur impor

Urutan impor lokal melalui Laragon:

1.  Pastikan MySQL Laragon aktif.
2.  Jalankan `schema.sql` untuk membuat database dan tabel.
3.  Jalankan `seed.sql` untuk memasukkan data awal.
4.  Verifikasi tabel dan data.

Contoh perintah PowerShell dari folder utama project:

``` powershell
Get-Content -Raw .\backend\database\schema.sql | mysql -u root -h 127.0.0.1 -P 3306
Get-Content -Raw .\backend\database\seed.sql | mysql -u root -h 127.0.0.1 -P 3306
```

Untuk server cloud, tetap gunakan prosedur Docker pada dokumen kelompok.
Pastikan `schema.sql` membuat database `db_absensi` sebelum perintah
impor memilih database tersebut.

Pembuatan user aplikasi pada MySQL:

``` sql
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'GANTI_DENGAN_PASSWORD_KUAT';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_absensi.* TO 'app_user'@'%';
FLUSH PRIVILEGES;
```

Jangan memakai password contoh tersebut secara langsung pada deployment.
Simpan kredensial dalam environment variable/secret dan batasi akses
jaringan database hanya dari VM backend.

## A.8. Tambahan aturan integritas presensi

Tambahkan subbagian aturan bisnis berikut pada dokumen:

1.  Satu pasangan `uid` dan `date` hanya boleh muncul satu kali pada
    tabel `attendances`.
2.  Check-in hanya boleh dilakukan jika belum ada presensi untuk UID dan
    tanggal tersebut.
3.  Check-out hanya boleh dilakukan jika record presensi hari itu sudah
    memiliki `check_in` dan belum memiliki `check_out`.
4.  Check-out memperbarui record yang dibuat saat check-in; tidak
    membuat record baru.
5.  `check_in`, `check_out`, dan tanggal presensi ditentukan
    backend/database, bukan dipercaya dari input waktu perangkat
    pengguna.
6.  Backend menghitung `work_hours` berdasarkan waktu check-in dan
    check-out yang tersimpan.
7.  Jika dua request check-in datang hampir bersamaan, constraint unik
    database harus mencegah record ganda dan backend mengembalikan
    response konflik yang sesuai.

------------------------------------------------------------------------

# BAGIAN B --- Revisi `06-spesifikasi-api.md`

## B.1. Konvensi umum API

Pertahankan: - Semua request dan response menggunakan JSON. - Endpoint
terproteksi menggunakan `Authorization: Bearer <JWT_TOKEN>`. - API
menggunakan prefix `/api`. - Nama field JSON menggunakan camelCase. -
Nama kolom database menggunakan snake_case. - Backend bertugas memetakan
field database ke field response API.

Tambahkan aturan: - Waktu dan tanggal yang dikirim pada response harus
menggunakan format yang konsisten. - Tetapkan timezone aplikasi,
database, dan server secara eksplisit pada konfigurasi deployment.
Jangan mengandalkan timezone default mesin. - Jangan mengirim
`password_hash` dalam response API. - Jangan menerima `uid` atau `role`
dari request pengguna untuk menentukan identitas dan hak akses.
Identitas pengguna harus berasal dari token JWT yang sudah diverifikasi.

## B.2. Health check dan header load balancing

Pertahankan endpoint:

`GET /api/health`

Setiap response backend harus menyertakan: - `X-Backend-Server` -
`X-Server-Port`

Nilai header harus berasal dari environment variable instance, bukan
ditulis permanen pada kode:

``` env
INSTANCE_NAME=backend_instance_1
PORT=5001
```

Instance kedua menggunakan nilai berbeda:

``` env
INSTANCE_NAME=backend_instance_2
PORT=5002
```

Response health check dapat tetap mengikuti format pada dokumen asli.
Nilai `instance` dan `port` pada body harus sesuai dengan environment
instance yang sedang melayani request.

## B.3. Registrasi karyawan

Pertahankan endpoint:

`POST /api/auth/register`

Perbaikan aturan: - Registrasi publik hanya boleh membuat pengguna
dengan role `employee`. - Jangan menerima `role`, `uid`, `isActive`,
atau `password_hash` dari input publik. - Backend membuat UID, melakukan
validasi email, dan melakukan hashing password menggunakan bcrypt. -
Email yang sudah terdaftar menghasilkan response `409 Conflict`. -
Password tidak boleh disimpan dalam bentuk plaintext.

Contoh request tetap menggunakan `name`, `email`, `password`, `phone`,
`position`, dan `department`.

## B.4. Login dan JWT

Pertahankan endpoint:

`POST /api/auth/login`

Aturan tambahan: - Backend mengambil pengguna berdasarkan email. -
Backend membandingkan password input dengan `password_hash` menggunakan
bcrypt. - Backend hanya menerbitkan JWT setelah kredensial valid dan
akun aktif. - JWT memuat identitas pengguna (`uid`) dan informasi role
yang diperlukan. - Password hash tidak boleh dikirim pada response. -
Token harus diverifikasi pada setiap endpoint terproteksi. - Gunakan
secret JWT dari environment variable, bukan hard-coded di source code.

Contoh environment:

``` env
JWT_SECRET=GANTI_DENGAN_SECRET_ACAK_YANG_PANJANG
JWT_EXPIRES_IN=1d
```

## B.5. Endpoint profil pengguna

Pertahankan:

`GET /api/auth/me`

UID pengguna harus diambil dari hasil verifikasi JWT. Jangan menerima
UID dari query string atau request body untuk menentukan profil yang
akan ditampilkan.

## B.6. Presensi masuk (check-in)

Pertahankan endpoint:

`POST /api/attendance/check-in`

**Ubah request body** menjadi:

``` json
{
  "method": "camera",
  "photoUrl": "data:image/jpeg;base64,..."
}
```

Hapus `scheduleStart` dari request body. Jam mulai jadwal harus
ditentukan backend berdasarkan data tabel `schedules`, bukan dipercaya
dari Flutter.

Aturan proses: 1. Verifikasi JWT dan ambil `uid` pengguna dari token. 2.
Ambil tanggal dan waktu saat ini dari waktu server/database dengan
timezone yang sudah ditetapkan. 3. Cari apakah pengguna sudah mempunyai
record presensi pada tanggal tersebut. 4. Jika sudah ada, tolak check-in
kedua dengan HTTP `409 Conflict`. 5. Jika belum ada, ambil jadwal aktif
yang berlaku untuk pengguna pada hari tersebut. 6. Backend menentukan
status `present` atau `late` berdasarkan jadwal dan waktu check-in. 7.
Buat satu record pada tabel `attendances`. 8. Jika terjadi benturan
request bersamaan, tangani duplicate-key dari constraint
`uq_attendance_uid_date` dan kembalikan `409 Conflict`.

Contoh response sukses `201 Created` tetap menggunakan bentuk data API
awal: `id`, `uid`, `userName`, `date`, `checkIn`, `checkOut`, `method`,
`status`, `workHours`, dan `note`.

Contoh response jika sudah check-in:

``` json
{
  "success": false,
  "message": "Anda sudah melakukan presensi masuk hari ini"
}
```

HTTP status: `409 Conflict`.

## B.7. Presensi pulang (check-out)

Pertahankan endpoint:

`POST /api/attendance/check-out`

Request body boleh tetap menerima `note`:

``` json
{
  "note": "Pekerjaan hari ini selesai"
}
```

Aturan proses: 1. Ambil `uid` dari JWT. 2. Cari record presensi
berdasarkan UID dan tanggal hari ini. 3. Jika record tidak ditemukan
atau `check_in` masih NULL, kembalikan `409 Conflict`. 4. Jika
`check_out` sudah terisi, tolak check-out kedua dengan `409 Conflict`.
5. Jika valid, perbarui record yang sama dengan waktu check-out. 6.
Hitung `workHours` dari selisih waktu check-in dan check-out. 7. Jangan
membuat record presensi baru saat check-out.

Contoh response konflik:

``` json
{
  "success": false,
  "message": "Presensi masuk belum tercatat atau presensi pulang sudah dilakukan"
}
```

## B.8. Status, riwayat, dan statistik presensi

Pertahankan endpoint: - `GET /api/attendance/today` -
`GET /api/attendance/history?limit=30` -
`GET /api/attendance/monthly-stats?month=11&year=2026`

Aturan tambahan: - Semua endpoint hanya mengembalikan data milik UID
yang berasal dari JWT, kecuali endpoint admin yang memang dirancang
untuk melihat data seluruh karyawan. - Validasi `limit`, `month`, dan
`year`. - Statistik dihitung dari data database, bukan dari data lokal
perangkat. - Karena satu pengguna hanya mempunyai satu record per
tanggal, riwayat harian tidak boleh menampilkan duplikasi presensi pada
tanggal yang sama.

## B.9. Jadwal kerja

Pertahankan:

`GET /api/schedules`

Response tetap menggunakan `dayOfWeek`, `dayLabel`, `startTime`,
`endTime`, dan `isActive`.

Backend membaca data dari tabel `schedules`. Untuk jadwal global,
gunakan record dengan `uid = 'all'`. Jika fitur jadwal khusus karyawan
diaktifkan, aturan prioritas jadwal khusus dan jadwal global harus
disepakati dan ditulis secara eksplisit.

## B.10. Pengajuan izin/cuti

Pertahankan endpoint: - `POST /api/requests` - `GET /api/requests/my` -
`PATCH /api/requests/:id/status`

Aturan tambahan: - `uid` dan `userName` pada pengajuan diambil dari
pengguna yang terautentikasi, bukan dipercaya dari request body. -
Karyawan hanya dapat melihat pengajuannya sendiri melalui `/my`. - Hanya
admin yang boleh mengubah status pengajuan. - Status yang diperbolehkan
adalah `pending`, `approved`, dan `rejected`. - Validasi `startDate` dan
`endDate`; `endDate` tidak boleh lebih awal daripada `startDate`. -
Pengguna biasa tidak boleh mengirim atau mengubah `adminNote`. - Backend
perlu memastikan ID pengajuan ditemukan sebelum memperbarui status.

## B.11. Format error tambahan

Pertahankan format error standar yang sudah ada. Tambahkan:

  -----------------------------------------------------------------------------------------------------
  HTTP                         Kondisi                 Pesan contoh
  ---------------------------- ----------------------- ------------------------------------------------
  `409 Conflict`               Check-in kedua pada     `Anda sudah melakukan presensi masuk hari ini`
                               tanggal yang sama
  `409 Conflict`               Check-out tanpa         `Presensi tidak dapat diproses`
                               check-in atau check-out
                               kedua

  `409 Conflict`               Email sudah terdaftar   `Email sudah digunakan`

  `422 Unprocessable Entity`   Validasi field gagal    `Data yang dikirim tidak valid`
  -----------------------------------------------------------------------------------------------------

Jangan mengirim detail query SQL, password, JWT secret, stack trace,
atau informasi internal server kepada client.

------------------------------------------------------------------------

# BAGIAN C --- Daftar pengecekan sebelum implementasi

## Database

-   [ ] Database bernama `db_absensi`.
-   [ ] Tabel `users`, `schedules`, `attendances`, dan `requests`
    berhasil dibuat.
-   [ ] Email pengguna memiliki unique constraint.
-   [ ] Tabel `attendances` memiliki unique constraint gabungan
    `(uid, date)`.
-   [ ] Foreign key `attendances.uid` mengarah ke `users.uid`.
-   [ ] Foreign key `requests.uid` mengarah ke `users.uid`.
-   [ ] Hash bcrypt admin dan employee sudah diverifikasi.
-   [ ] Seed jadwal Senin sampai Minggu berhasil dimasukkan.

## API dan backend

-   [ ] Semua endpoint menggunakan prefix `/api`.
-   [ ] JWT digunakan untuk endpoint terproteksi.
-   [ ] Role admin dan employee diperiksa oleh backend.
-   [ ] Check-in membuat satu record per UID per tanggal.
-   [ ] Check-out memperbarui record check-in yang sama.
-   [ ] Check-in kedua ditolak.
-   [ ] Check-out tanpa check-in ditolak.
-   [ ] Check-out kedua ditolak.
-   [ ] Header `X-Backend-Server` dan `X-Server-Port` tersedia pada
    setiap response backend.
-   [ ] Kedua instance backend memakai database yang sama.

## Catatan yang perlu disepakati kelompok

1.  Apakah admin juga melakukan presensi, atau hanya karyawan? Skema
    role saat ini memungkinkan keduanya, tetapi aturan bisnis perlu
    dipastikan.
2.  Apakah jadwal hanya global (`uid = 'all'`) atau akan ada jadwal
    khusus per karyawan?
3.  Apakah `photoUrl` akan menyimpan Base64 sementara atau URL object
    storage saat deployment? Untuk deployment, URL object storage lebih
    disarankan.
4.  Pastikan Flutter mengirim dan membaca nama field JSON sesuai kontrak
    API. Jika model Flutter saat ini berbeda, lakukan pemetaan pada
    service/model, bukan mengganti nama kolom database secara acak.

**Acuan utama:** dua dokumen kelompok (`06-spesifikasi-api.md` dan
`07-skema-database.md`). Rekomendasi keamanan dan validasi di dokumen
revisi ini merupakan penajaman implementasi agar kontrak tersebut lebih
aman dan konsisten.
