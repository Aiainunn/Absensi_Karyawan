const express = require('express');
const os = require('os');
const router = express.Router();

router.get('/health', (req, res) => {
    res.json({
        success: true,
        status: 'healthy',
        timestamp: new Date().toISOString(),
        server: process.env.INSTANCE_ID || process.env.INSTANCE_NAME || os.hostname(),
        port: process.env.PORT || 5000,
        uptime: process.uptime()
    });
});

module.exports = router;
