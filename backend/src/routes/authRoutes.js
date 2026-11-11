const express = require('express');
const router = express.Router();

const {
    register,
    login,
    getMe,
    updateMe
} = require('../controllers/authController');

const authenticateToken = require('../middleware/authMiddleware');

// Register dan Login (publik)
router.post('/register', register);
router.post('/login', login);

// Mendapatkan profil pengguna (wajib login)
router.get('/me', authenticateToken, getMe);
router.put('/me', authenticateToken, updateMe);

module.exports = router;
