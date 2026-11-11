const express = require('express');
const router = express.Router();

router.get('/health', (req, res) => {
    res.json({
        success: true,
        status: 'healthy',
        timestamp: new Date().toISOString(),
        server: process.env.INSTANCE_NAME || 'local',
        port: process.env.PORT || 3000,
        uptime: process.uptime()
    });
});

module.exports = router;
