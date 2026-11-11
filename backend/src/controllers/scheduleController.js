const db = require('../config/database');

const getSchedules = async (req, res) => {
    try {
        const [schedules] = await db.execute(`
            SELECT
                id,
                day_of_week AS dayOfWeek,
                start_time AS startTime,
                end_time AS endTime,
                is_active AS isActive,
                note
            FROM schedules
            WHERE uid = 'all'
            ORDER BY FIELD(
                LOWER(day_of_week),
                'monday',
                'tuesday',
                'wednesday',
                'thursday',
                'friday',
                'saturday',
                'sunday'
            )
        `);

        return res.status(200).json({
            success: true,
            message: 'Data jadwal berhasil diambil.',
            data: schedules
        });
    } catch (error) {
        console.error('Get schedules error:', error);

        return res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server.'
        });
    }
};

module.exports = {
    getSchedules
};