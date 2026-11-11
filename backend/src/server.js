const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const healthRoutes = require('./routes/healthRoutes');
const authRoutes = require('./routes/authRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');
const scheduleRoutes = require('./routes/scheduleRoutes');

const db = require('./config/database');

db.getConnection()
    .then((connection) => {
        console.log('Database MySQL berhasil terhubung!');
        connection.release();
    })
    .catch((error) => {
        console.error('Koneksi database gagal:', error.message);
    });

// Middleware
app.use(cors());
app.use(express.json());
app.use('/api', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/schedules', scheduleRoutes);

// Endpoint untuk mengecek server
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'API Absensi Karyawan berhasil berjalan!'
    });
});

// Menentukan port server
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Server berjalan di http://localhost:${PORT}`);
});
