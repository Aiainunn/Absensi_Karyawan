-- =============================================================================
-- DATABASE INITIALIZATION: db_absensi
-- MySQL 8.0+ | InnoDB | utf8mb4
-- Revisi berdasarkan dokumen 06-spesifikasi-api.md dan 07-skema-database.md
-- =============================================================================

CREATE DATABASE IF NOT EXISTS db_absensi_baru
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE db_absensi_baru;

-- 1. USERS: akun admin dan karyawan
CREATE TABLE IF NOT EXISTS users (
    uid VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL DEFAULT '',
    position VARCHAR(50) NOT NULL DEFAULT '',
    department VARCHAR(50) NOT NULL DEFAULT '',
    role ENUM('admin', 'employee') NOT NULL DEFAULT 'employee',
    photo_url TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    join_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (uid),
    UNIQUE KEY uq_users_email (email),
    INDEX idx_users_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. SCHEDULES: jadwal kerja global atau khusus pengguna.
-- uid='all' digunakan untuk jadwal global, sehingga tidak memakai FK ke users.
-- VARCHAR dipertahankan agar nilai '--:--' pada hari libur sesuai kontrak API.
CREATE TABLE IF NOT EXISTS schedules (
    id VARCHAR(50) NOT NULL,
    uid VARCHAR(50) NOT NULL DEFAULT 'all',
    day_of_week VARCHAR(15) NOT NULL,
    start_time VARCHAR(10) NOT NULL DEFAULT '08:00',
    end_time VARCHAR(10) NOT NULL DEFAULT '17:00',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    note VARCHAR(255) NOT NULL DEFAULT '',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_schedules_day (day_of_week),
    INDEX idx_schedules_uid_day (uid, day_of_week)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. ATTENDANCES: satu record per pengguna per tanggal.
-- Check-in membuat record; check-out memperbarui record yang sama.
CREATE TABLE IF NOT EXISTS attendances (
    id VARCHAR(50) NOT NULL,
    uid VARCHAR(50) NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    check_in DATETIME NULL,
    check_out DATETIME NULL,
    method ENUM('camera', 'fingerprint') NOT NULL DEFAULT 'camera',
    status ENUM('present', 'late', 'absent', 'permission') NOT NULL DEFAULT 'present',
    work_hours DECIMAL(4, 2) NOT NULL DEFAULT 0.00,
    photo_url LONGTEXT NULL,
    note TEXT DEFAULT (''),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_attendances_user
        FOREIGN KEY (uid) REFERENCES users(uid) ON DELETE CASCADE,
    CONSTRAINT uq_attendances_user_date UNIQUE (uid, date),
    INDEX idx_attendances_date (date),
    INDEX idx_attendances_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. REQUESTS: pengajuan izin, cuti, sakit, lembur, dan pengunduran diri.
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
    updated_at DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_requests_user
        FOREIGN KEY (uid) REFERENCES users(uid) ON DELETE CASCADE,
    INDEX idx_requests_user (uid),
    INDEX idx_requests_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
