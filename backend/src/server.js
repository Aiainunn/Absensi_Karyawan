const express = require('express');
const cors = require('cors');
const path = require('path');
const os = require('os');
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

// Middleware untuk menyematkan identitas container/host pada setiap response (Bukti Load Balancing)
app.use((req, res, next) => {
    res.setHeader('X-Served-By', process.env.INSTANCE_ID || os.hostname());
    next();
});

// Menyajikan folder uploads untuk foto presensi secara statis
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Routes
app.use('/api', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/schedules', scheduleRoutes);

// Endpoint untuk mengecek server dasar
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'API Absensi Karyawan berhasil berjalan!',
        instance: process.env.INSTANCE_ID || os.hostname()
    });
});

// Menentukan port server
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(`Server [${process.env.INSTANCE_ID || os.hostname()}] berjalan di http://localhost:${PORT}`);
});
