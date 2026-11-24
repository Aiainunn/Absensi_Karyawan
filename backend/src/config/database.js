const mysql = require('mysql2/promise');
require('dotenv').config();

const db = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 3306,
    database: process.env.DB_DATABASE || process.env.DB_NAME || 'db_absensi',
    user: process.env.DB_USERNAME || process.env.DB_USER || 'app_user',
    password: process.env.DB_PASSWORD || 'UserAppPassword123!',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

module.exports = db;
