const express = require('express');
const router = express.Router();

const { getSchedules } = require('../controllers/scheduleController');
const authenticateToken = require('../middleware/authMiddleware');

router.use(authenticateToken);

router.get('/', getSchedules);

module.exports = router;