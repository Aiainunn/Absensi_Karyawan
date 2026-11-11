const jwt = require('jsonwebtoken');

const authenticateToken = (req, res, next) => {
    try {
        // Ambil token dari header Authorization
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                message: 'Token autentikasi tidak ditemukan.'
            });
        }

        // Pisahkan Bearer dengan token
        const token = authHeader.split(' ')[1];

        // Verifikasi token JWT
        const decoded = jwt.verify(
            token,
            process.env.JWT_SECRET
        );

        // Simpan identitas pengguna ke request
        req.user = decoded;

        // Lanjutkan ke endpoint berikutnya
        next();

    } catch (error) {
        return res.status(401).json({
            success: false,
            message: 'Token tidak valid atau sudah kedaluwarsa.'
        });
    }
};

module.exports = authenticateToken;
