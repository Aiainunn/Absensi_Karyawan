const db = require('../config/database');
const { randomUUID } = require('crypto');

// ==========================================
// CHECK-IN
// ==========================================
const checkIn = async (req, res) => {
    try {
        const uid = req.user.uid;
        const { method, photoUrl } = req.body;

        // Validasi metode
        if (!['camera', 'fingerprint'].includes(method)) {
            return res.status(400).json({
                success: false,
                message: 'Metode absensi tidak valid.'
            });
        }

        // Validasi foto
        if (method === 'camera' && !photoUrl) {
            return res.status(400).json({
                success: false,
                message: 'Foto absensi wajib diunggah.'
            });
        }

        // Memastikan akun aktif
        const [users] = await db.execute(
            `SELECT uid, name, is_active
             FROM users
             WHERE uid = ?
             LIMIT 1`,
            [uid]
        );

        if (users.length === 0 || !users[0].is_active) {
            return res.status(403).json({
                success: false,
                message: 'Akun karyawan tidak ditemukan atau tidak aktif.'
            });
        }

        const user = users[0];

        // Memeriksa check-in hari ini
        const [existing] = await db.execute(
            `SELECT id
             FROM attendances
             WHERE uid = ? AND date = CURDATE()
             LIMIT 1`,
            [uid]
        );

        if (existing.length > 0) {
            return res.status(409).json({
                success: false,
                message: 'Anda sudah melakukan check-in hari ini.'
            });
        }

        // Mengambil jadwal kerja hari ini
        const [schedules] = await db.execute(
            `SELECT start_time, end_time, is_active, note
             FROM schedules
             WHERE uid = 'all'
             AND LOWER(day_of_week) = LOWER(DAYNAME(CURDATE()))
             LIMIT 1`
        );

        if (schedules.length === 0 || !schedules[0].is_active) {
            return res.status(400).json({
                success: false,
                message: 'Tidak ada jadwal kerja aktif hari ini.'
            });
        }

        const schedule = schedules[0];

        // Menghitung status kehadiran
        const [timeResult] = await db.execute(
            `SELECT
                CURDATE() AS today,
                NOW() AS server_datetime,
                TIME(NOW()) AS current_clock`
        );

        const current = timeResult[0];

        const status = current.current_clock > schedule.start_time
            ? 'late'
            : 'present';

        // Membuat ID absensi
        const attendanceId = randomUUID();

        // Menyimpan data check-in
        await db.execute(
            `INSERT INTO attendances
                (id, uid, user_name, date, check_in, method, status, photo_url)
             VALUES (?, ?, ?, CURDATE(), NOW(), ?, ?, ?)`,
            [
                attendanceId,
                uid,
                user.name,
                method,
                status,
                method === 'camera' ? photoUrl : null
            ]
        );

        // Mengambil data yang baru disimpan
        const [attendance] = await db.execute(
            `SELECT
                id,
                uid,
                user_name AS userName,
                DATE_FORMAT(date, '%Y-%m-%d') AS date,
                DATE_FORMAT(check_in, '%H:%i:%s') AS checkIn,
                DATE_FORMAT(check_out, '%H:%i:%s') AS checkOut,
                method,
                status,
                work_hours AS workHours,
                note
             FROM attendances
             WHERE id = ?`,
            [attendanceId]
        );

        return res.status(201).json({
            success: true,
            message: 'Check-in berhasil.',
            data: attendance[0]
        });

    } catch (error) {
        console.error('Check-in error:', error.message);

        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({
                success: false,
                message: 'Anda sudah melakukan check-in hari ini.'
            });
        }

        return res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server.'
        });
    }
};


// ==========================================
// CHECK-OUT
// ==========================================
const checkOut = async (req, res) => {
    try {
        const uid = req.user.uid;
        const { note } = req.body || {};

        // Memeriksa data check-in hari ini
        const [records] = await db.execute(
            `SELECT id, check_in, check_out
             FROM attendances
             WHERE uid = ? AND date = CURDATE()
             LIMIT 1`,
            [uid]
        );

        if (records.length === 0 || !records[0].check_in) {
            return res.status(409).json({
                success: false,
                message: 'Anda belum melakukan check-in hari ini.'
            });
        }

        const attendance = records[0];

        // Memeriksa apakah sudah check-out
        if (attendance.check_out !== null) {
            return res.status(409).json({
                success: false,
                message: 'Anda sudah melakukan check-out hari ini.'
            });
        }

        // Memperbarui record yang sama dan menghitung jam kerja
        const [result] = await db.execute(
            `UPDATE attendances
             SET
                check_out = NOW(),
                work_hours = ROUND(
                    TIMESTAMPDIFF(SECOND, check_in, NOW()) / 3600,
                    2
                ),
                note = COALESCE(NULLIF(?, ''), note)
             WHERE id = ?
             AND check_out IS NULL`,
            [
                typeof note === 'string' ? note.trim() : null,
                attendance.id
            ]
        );

        if (result.affectedRows === 0) {
            return res.status(409).json({
                success: false,
                message: 'Check-out sudah dilakukan.'
            });
        }

        // Mengambil data terbaru
        const [updated] = await db.execute(
            `SELECT
                id,
                uid,
                user_name AS userName,
                DATE_FORMAT(date, '%Y-%m-%d') AS date,
                DATE_FORMAT(check_in, '%H:%i:%s') AS checkIn,
                DATE_FORMAT(check_out, '%H:%i:%s') AS checkOut,
                method,
                status,
                work_hours AS workHours,
                note
             FROM attendances
             WHERE id = ?`,
            [attendance.id]
        );

        return res.status(200).json({
            success: true,
            message: 'Check-out berhasil.',
            data: updated[0]
        });

    } catch (error) {
        console.error('Check-out error:', error.message);

        return res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server.'
        });
    }
};


// ==========================================
// ABSENSI HARI INI
// ==========================================
const getToday = async (req, res) => {
    try {
        const uid = req.user.uid;

        const [records] = await db.execute(
            `SELECT
                id,
                uid,
                user_name AS userName,
                DATE_FORMAT(date, '%Y-%m-%d') AS date,
                DATE_FORMAT(check_in, '%H:%i:%s') AS checkIn,
                DATE_FORMAT(check_out, '%H:%i:%s') AS checkOut,
                method,
                status,
                work_hours AS workHours,
                note
             FROM attendances
             WHERE uid = ? AND date = CURDATE()
             LIMIT 1`,
            [uid]
        );

        return res.status(200).json({
            success: true,
            message: 'Data absensi hari ini berhasil diambil.',
            data: records.length > 0 ? records[0] : null
        });

    } catch (error) {
        console.error('Get today error:', error.message);

        return res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server.'
        });
    }
};


// ==========================================
// RIWAYAT ABSENSI
// ==========================================
const getHistory = async (req, res) => {
    try {
        const uid = req.user.uid;

        let limit = Number.parseInt(req.query.limit, 10);

        if (!Number.isInteger(limit) || limit < 1) {
            limit = 30;
        }

        // Maksimal 100 data
        limit = Math.min(limit, 100);

        const [records] = await db.execute(
            `SELECT
                id,
                uid,
                user_name AS userName,
                DATE_FORMAT(date, '%Y-%m-%d') AS date,
                DATE_FORMAT(check_in, '%H:%i:%s') AS checkIn,
                DATE_FORMAT(check_out, '%H:%i:%s') AS checkOut,
                method,
                status,
                work_hours AS workHours,
                note
             FROM attendances
             WHERE uid = ?
             ORDER BY date DESC
             LIMIT ${limit}`,
            [uid]
        );

        return res.status(200).json({
            success: true,
            message: 'Riwayat absensi berhasil diambil.',
            total: records.length,
            data: records
        });

    } catch (error) {
        console.error('Get history error:', error.message);

        return res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server.'
        });
    }
};


// ==========================================
// STATISTIK ABSENSI BULANAN
// ==========================================
const getMonthlyStats = async (req, res) => {
    try {
        const uid = req.user.uid;

        const currentDate = new Date();
        const month = req.query.month === undefined
            ? currentDate.getMonth() + 1
            : Number(req.query.month);

        const year = req.query.year === undefined
            ? currentDate.getFullYear()
            : Number(req.query.year);

        if (
            !Number.isInteger(month) ||
            month < 1 ||
            month > 12 ||
            !Number.isInteger(year) ||
            year < 2000 ||
            year > 2100
        ) {
            return res.status(400).json({
                success: false,
                message: 'Bulan atau tahun tidak valid.'
            });
        }

        const startDate = `${year}-${String(month).padStart(2, '0')}-01`;

        const nextMonthDate = new Date(Date.UTC(year, month, 1));
        const endDate = [
            nextMonthDate.getUTCFullYear(),
            String(nextMonthDate.getUTCMonth() + 1).padStart(2, '0'),
            '01'
        ].join('-');

        const [stats] = await db.execute(
            `SELECT
                COUNT(*) AS totalAttendance,
                SUM(status = 'present') AS presentDays,
                SUM(status = 'late') AS lateDays,
                SUM(status = 'absent') AS absentDays,
                SUM(status = 'permission') AS permissionDays,
                COALESCE(SUM(work_hours), 0) AS totalWorkHours
             FROM attendances
             WHERE uid = ?
             AND date >= ?
             AND date < ?`,
            [uid, startDate, endDate]
        );

        return res.status(200).json({
            success: true,
            message: 'Statistik absensi bulanan berhasil diambil.',
            data: {
                month,
                year,
                ...stats[0]
            }
        });

    } catch (error) {
        console.error('Monthly stats error:', error.message);

        return res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server.'
        });
    }
};


module.exports = {
    checkIn,
    checkOut,
    getToday,
    getHistory,
    getMonthlyStats
};
