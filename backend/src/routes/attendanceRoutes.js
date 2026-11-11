const express = require('express');
const router = express.Router();

const authenticateToken = require('../middleware/authMiddleware');

const {
    checkIn,
    checkOut,
    getToday,
    getHistory,
    getMonthlyStats
} = require('../controllers/attendanceController');

// Semua endpoint membutuhkan JWT
router.use(authenticateToken);

// Check-in dan check-out
router.post('/check-in', checkIn);
router.post('/check-out', checkOut);

// Informasi absensi
router.get('/today', getToday);
router.get('/history', getHistory);
router.get('/monthly-stats', getMonthlyStats);

module.exports = router;
