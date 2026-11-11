-- =============================================================================
-- INITIAL DATA: db_absensi
-- Password disimpan sebagai bcrypt hash (cost 10).
-- Admin: admin@company.com / admin123
-- Employee: budi@company.com / 123456
-- =============================================================================

USE db_absensi_baru;

INSERT INTO users (
    uid, name, email, password_hash, phone, position, department,
    role, is_active, join_date
) VALUES
(
    'admin_default_id',
    'Admin HRD Utama',
    'admin@company.com',
    '$2b$10$UYW3Mr6YDPg6FktG.doOM.OaHDTo4ehiH81Pv76aSOFMU3wUpHlx.',
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
    '$2b$10$M4B7bmXofP2ntE36/y5fc.D7B5nLoAZhIHB1ra5yt0iA07rg0MU9u',
    '081234567890',
    'Staff IT & Operasional',
    'Teknologi Informasi',
    'employee',
    TRUE,
    DATE_SUB(NOW(), INTERVAL 120 DAY)
)
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    email = VALUES(email);

INSERT INTO schedules (id, uid, day_of_week, start_time, end_time, is_active, note)
VALUES
    ('sch_mon', 'all', 'monday',    '08:00', '17:00', TRUE,  'Hari kerja reguler'),
    ('sch_tue', 'all', 'tuesday',   '08:00', '17:00', TRUE,  'Hari kerja reguler'),
    ('sch_wed', 'all', 'wednesday', '08:00', '17:00', TRUE,  'Hari kerja reguler'),
    ('sch_thu', 'all', 'thursday',  '08:00', '17:00', TRUE,  'Hari kerja reguler'),
    ('sch_fri', 'all', 'friday',    '08:00', '17:00', TRUE,  'Hari kerja reguler (Pulang cepat)'),
    ('sch_sat', 'all', 'saturday',  '--:--', '--:--', FALSE, 'Libur akhir pekan'),
    ('sch_sun', 'all', 'sunday',    '--:--', '--:--', FALSE, 'Libur akhir pekan')
ON DUPLICATE KEY UPDATE
    day_of_week = VALUES(day_of_week),
    start_time = VALUES(start_time),
    end_time = VALUES(end_time),
    is_active = VALUES(is_active),
    note = VALUES(note);
