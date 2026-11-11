const db = require('../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { randomUUID } = require('crypto');

// REGISTER
const register = async (req, res) => {
    try {
        const {
            name,
            email,
            password,
            phone,
            position,
            department
        } = req.body;

        // Validasi input wajib
        if (!name || !email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Nama, email, dan password wajib diisi.'
            });
        }

        // Periksa apakah email sudah terdaftar
        const [existingUser] = await db.execute(
            'SELECT uid FROM users WHERE email = ?',
            [email]
        );

        if (existingUser.length > 0) {
            return res.status(409).json({
                success: false,
                message: 'Email sudah terdaftar.'
            });
        }

        // Enkripsi password
        const passwordHash = await bcrypt.hash(password, 10);

        // Buat UID pengguna
        const uid = randomUUID();

        // Simpan pengguna baru
        await db.execute(
            `INSERT INTO users
            (uid, name, email, password_hash, phone, position, department, role, is_active)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'employee', 1)`,
            [
                uid,
                name,
                email,
                passwordHash,
                phone || null,
                position || null,
                department || null
            ]
        );

        return res.status(201).json({
            success: true,
            message: 'Registrasi berhasil.',
            data: {
                uid,
                name,
                email,
                role: 'employee'
            }
        });

    } catch (error) {
        console.error('Register error:', error.message);

        return res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server.'
        });
    }
};

// LOGIN
const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Email dan password wajib diisi.'
            });
        }

        // Cari pengguna berdasarkan email
        const [users] = await db.execute(
            'SELECT * FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Email atau password salah.'
            });
        }

        const user = users[0];

        // Periksa status akun
        if (!user.is_active) {
            return res.status(403).json({
                success: false,
                message: 'Akun tidak aktif.'
            });
        }

        // Cocokkan password
        const passwordMatch = await bcrypt.compare(
            password,
            user.password_hash
        );

        if (!passwordMatch) {
            return res.status(401).json({
                success: false,
                message: 'Email atau password salah.'
            });
        }

        // Buat JWT
        const token = jwt.sign(
            {
                uid: user.uid,
                role: user.role
            },
            process.env.JWT_SECRET,
            {
                expiresIn: process.env.JWT_EXPIRES_IN || '1d'
            }
        );

        return res.status(200).json({
            success: true,
            message: 'Login berhasil.',
            data: {
                token,
                user: {
                    uid: user.uid,
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    photoUrl: user.photo_url
                }
            }
        });

    } catch (error) {
        console.error('Login error:', error.message);

        return res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server.'
        });
    }
};

// GETME
const getMe = async (req, res) => {
    try {
        const [users] = await db.execute(
            `SELECT uid, name, email, phone, position,
                    department, role, photo_url
             FROM users
             WHERE uid = ?`,
            [req.user.uid]
        );

        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Pengguna tidak ditemukan.'
            });
        }

        const user = users[0];

        return res.status(200).json({
            success: true,
            data: {
                uid: user.uid,
                name: user.name,
                email: user.email,
                phone: user.phone,
                position: user.position,
                department: user.department,
                role: user.role,
                photoUrl: user.photo_url
            }
        });

    } catch (error) {
        console.error('Get profile error:', error.message);

        return res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server.'
        });
    }
};

// UPDATE PROFIL

// updateMe
const updateMe = async (req, res) => {
    try {
        const { name, phone, position, department } = req.body;

        if (!name || !name.trim()) {
            return res.status(400).json({
                success: false,
                message: 'Nama wajib diisi.'
            });
        }

        await db.execute(
            `UPDATE users
             SET name = ?, phone = ?, position = ?, department = ?
             WHERE uid = ?`,
            [
                name.trim(),
                phone || null,
                position || null,
                department || null,
                req.user.uid
            ]
        );

        return res.status(200).json({
            success: true,
            message: 'Profil berhasil diperbarui.'
        });

    } catch (error) {
        console.error('Update profile error:', error.message);

        return res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server.'
        });
    }
};


module.exports = {
    register,
    login,
    getMe,
    updateMe
};
