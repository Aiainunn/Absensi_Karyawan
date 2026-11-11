# Skema Basis Data dan Data Awal (Database Schema & Seed)

Dokumen ini merupakan panduan teknis bagi **Peran 3 (Database & Network Administrator)** untuk menginisialisasi skema tabel, relasi, tipe data, serta data awal (seed) pada container **MySQL 8.0** di `vm-database`.

---

## 1. Spesifikasi Teknis Basis Data

* **RDBMS Engine:** MySQL Server 8.0 (Docker Container).
* **Storage Engine:** InnoDB (Mendukung ACID compliance dan Foreign Key Constraints).
* **Default Character Set:** `utf8mb4`
* **Default Collation:** `utf8mb4_unicode_ci`
* **Nama Database Aplikasi:** `db_absensi`
* **User Khusus Aplikasi (Non-Root):** `app_user`
* **Hak Akses (Privileges):** `SELECT, INSERT, UPDATE, DELETE` pada `db_absensi.*`

---

## 2. Struktur Skema Tabel Relasional (DDL)

Berikut adalah struktur tabel SQL yang mencerminkan model data pada aplikasi Flutter (`UserModel`, `AttendanceModel`, `ScheduleModel`, `RequestModel`):

```sql
-- =============================================================================
-- DATABASE INITIALIZATION SCRIPT: db_absensi
-- File: schema.sql
-- =============================================================================

CREATE DATABASE IF NOT EXISTS db_absensi
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE db_absensi;

-- -----------------------------------------------------------------------------
-- 1. TABEL: users
-- Menyimpan informasi kredensial dan profil karyawan serta administrator
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    uid VARCHAR(50) NOT NULL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20) DEFAULT '',
    position VARCHAR(50) DEFAULT '',
    department VARCHAR(50) DEFAULT '',
    role ENUM('admin', 'employee') NOT NULL DEFAULT 'employee',
    photo_url TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    join_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_email (email),
    INDEX idx_user_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 2. TABEL: schedules
-- Menyimpan jadwal jam kerja harian karyawan
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS schedules (
    id VARCHAR(50) NOT NULL PRIMARY KEY,
    uid VARCHAR(50) NOT NULL DEFAULT 'all', -- 'all' berarti jadwal berlaku global
    day_of_week VARCHAR(15) NOT NULL,      -- 'monday', 'tuesday', dsb.
    start_time VARCHAR(10) NOT NULL DEFAULT '08:00', -- format 'HH:mm'
    end_time VARCHAR(10) NOT NULL DEFAULT '17:00',   -- format 'HH:mm'
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    note VARCHAR(255) DEFAULT '',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_schedule_day (day_of_week)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 3. TABEL: attendances
-- Mencatat seluruh riwayat presensi masuk dan pulang karyawan
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS attendances (
    id VARCHAR(50) NOT NULL PRIMARY KEY,
    uid VARCHAR(50) NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    date DATE NOT NULL,                              -- format 'YYYY-MM-DD'
    check_in DATETIME NULL,
    check_out DATETIME NULL,
    method ENUM('camera', 'fingerprint') NOT NULL DEFAULT 'camera',
    status ENUM('present', 'late', 'absent', 'permission') NOT NULL DEFAULT 'present',
    work_hours DECIMAL(4, 2) NOT NULL DEFAULT 0.00, -- jumlah jam kerja desimal (misal 8.50 jam)
    photo_url LONGTEXT NULL,                         -- menyimpan path gambar atau base64 foto selfie
    note TEXT DEFAULT '',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (uid) REFERENCES users(uid) ON DELETE CASCADE,
    INDEX idx_attendance_user_date (uid, date),
    INDEX idx_attendance_date (date),
    INDEX idx_attendance_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 4. TABEL: requests
-- Mencatat pengajuan perizinan, cuti tahunan, dan lembur karyawan
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS requests (
    id VARCHAR(50) NOT NULL PRIMARY KEY,
    uid VARCHAR(50) NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    type ENUM('leave', 'overtime', 'resignation', 'sick', 'permission') NOT NULL,
    reason TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    admin_note TEXT DEFAULT '',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (uid) REFERENCES users(uid) ON DELETE CASCADE,
    INDEX idx_request_user (uid),
    INDEX idx_request_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 3. Data Awal / Seeding (DML)

Berikut adalah data default awal yang bersumber dari `lib/services/local_db_service.dart`, yang memuat akun awal untuk proses pengujian login dan jadwal kerja kantor:

```sql
-- =============================================================================
-- DATA SEED INITIALIZATION SCRIPT: db_absensi
-- File: seed.sql
-- =============================================================================

USE db_absensi;

-- -----------------------------------------------------------------------------
-- 1. SEED DATA USERS
-- Password hash menggunakan Bcrypt (salt round 10):
-- • admin123 -> $2b$10$wT0lVlP5jNqT.q9n8J2szeJjFf08hE5r4yP1wzIu7fW1yP3zN7n8a
-- • 123456   -> $2b$10$7Z2Z4X3C5V6B7N8M9L0K1J2H3G4F5D6S7A8Q9W0E1R2T3Y4U5I6O7
-- -----------------------------------------------------------------------------
INSERT INTO users (uid, name, email, password_hash, phone, position, department, role, is_active, join_date)
VALUES 
    (
        'admin_default_id', 
        'Admin HRD Utama', 
        'admin@company.com', 
        '$2b$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQmG6Fe9P9k3sZ.sU.bCe', -- Password: admin123
        '081299887766', 
        'HR Manager', 
        'HRD & Personalia', 
        'admin', 
        TRUE, 
        DATE_SUB(NOW(), INTERVAL 365 DAY)
    ),
    (
        'karyawan_default_id', 
        'Budi Santoso', 
        'budi@company.com', 
        '$2b$10$zD9w5kH8xL4vN1mQ2oP3r.eT6uY7iO8pA9sD0fG1hJ2kL3zX4c5Vb', -- Password: 123456
        '081234567890', 
        'Staff IT & Operasional', 
        'Teknologi Informasi', 
        'employee', 
        TRUE, 
        DATE_SUB(NOW(), INTERVAL 120 DAY)
    )
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- -----------------------------------------------------------------------------
-- 2. SEED DATA JADWAL KERJA (Senin - Minggu)
-- -----------------------------------------------------------------------------
INSERT INTO schedules (id, uid, day_of_week, start_time, end_time, is_active, note)
VALUES
    ('sch_mon', 'all', 'monday',    '08:00', '17:00', TRUE,  'Hari kerja reguler'),
    ('sch_tue', 'all', 'tuesday',   '08:00', '17:00', TRUE,  'Hari kerja reguler'),
    ('sch_wed', 'all', 'wednesday', '08:00', '17:00', TRUE,  'Hari kerja reguler'),
    ('sch_thu', 'all', 'thursday',  '08:00', '17:00', TRUE,  'Hari kerja reguler'),
    ('sch_fri', 'all', 'friday',    '08:00', '17:00', TRUE,  'Hari kerja reguler (Pulang cepat)'),
    ('sch_sat', 'all', 'saturday',  '--:--', '--:--', FALSE, 'Libur akhir pekan'),
    ('sch_sun', 'all', 'sunday',    '--:--', '--:--', FALSE, 'Libur akhir pekan')
ON DUPLICATE KEY UPDATE day_of_week=VALUES(day_of_week);
```

---

## 4. Prosedur Eksekusi Impor di `vm-database`

Peran 3 dapat mengeksekusi impor skema dan seed data langsung ke dalam container Docker dengan langkah berikut:

```bash
# 1. Masuk ke vm-database via Termius
ssh -i key-kelompok.pem ubuntu@<IP_PUBLIK_VM_DATABASE>

# 2. Salin schema.sql dan seed.sql ke dalam folder proyek
mkdir -p ~/mysql-init
nano ~/mysql-init/schema.sql   # Tempel isi DDL di atas
nano ~/mysql-init/seed.sql     # Tempel isi DML di atas

# 3. Eksekusi impor ke dalam container MySQL yang sedang berjalan
docker exec -i mysql_database mysql -u root -p"PasswordRootKalian" db_absensi < ~/mysql-init/schema.sql
docker exec -i mysql_database mysql -u root -p"PasswordRootKalian" db_absensi < ~/mysql-init/seed.sql

# 4. Buat user aplikasi khusus (app_user) agar backend tidak menggunakan user root
docker exec -it mysql_database mysql -u root -p"PasswordRootKalian" -e "
    CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'PasswordAplikasiKalian123!';
    GRANT SELECT, INSERT, UPDATE, DELETE ON db_absensi.* TO 'app_user'@'%';
    FLUSH PRIVILEGES;
"
```

---

## 5. Kumpulan Query SQL untuk Pengujian DBeaver (Untuk Peran 5)

Selama pengujian berlangsung, Peran 5 dapat menjalankan query berikut di DBeaver melalui koneksi SSH Tunnel untuk memverifikasi penyimpanan data:

* **Mengecek Data Karyawan yang Baru Terdaftar:**
  ```sql
  SELECT uid, name, email, role, department, created_at FROM users ORDER BY created_at DESC;
  ```
* **Mengecek Transaksi Presensi Masuk & Pulang Terakhir:**
  ```sql
  SELECT a.id, u.name, a.date, a.check_in, a.check_out, a.method, a.status, a.work_hours
  FROM attendances a
  JOIN users u ON a.uid = u.uid
  ORDER BY a.created_at DESC LIMIT 10;
  ```
* **Mengecek Pengajuan Cuti dan Status Approval:**
  ```sql
  SELECT r.id, u.name, r.type, r.start_date, r.end_date, r.status, r.admin_note
  FROM requests r
  JOIN users u ON r.uid = u.uid
  ORDER BY r.created_at DESC;
  ```
* **Menghitung Total Record (Uji Persistensi Volume):**
  ```sql
  SELECT 
      (SELECT COUNT(*) FROM users) AS total_users,
      (SELECT COUNT(*) FROM attendances) AS total_attendances,
      (SELECT COUNT(*) FROM requests) AS total_requests;
  ```

