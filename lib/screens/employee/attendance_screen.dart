import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  int _selectedMethod = 0; // 0 = Kamera, 1 = Sidik Jari
  File? _capturedFaceImage;
  bool _isProcessing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Ambil foto selfie menggunakan kamera depan
  Future<void> _takeSelfie() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _capturedFaceImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera tidak tersedia: $e'),
            backgroundColor: AppTheme.accentCoral,
          ),
        );
      }
    }
  }

  // Handle Absen Masuk
  Future<void> _handleCheckIn() async {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    if (_selectedMethod == 0 && _capturedFaceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan ambil foto selfie wajah terlebih dahulu'),
          backgroundColor: AppTheme.accentOrange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    bool success = false;

    if (_selectedMethod == 0) {
      // Absensi via Kamera
      success = await attendance.checkInWithCamera(
        uid: user.uid,
        userName: user.name,
      );
    } else {
      // Absensi via Sidik Jari
      success = await attendance.checkInWithFingerprint(
        uid: user.uid,
        userName: user.name,
      );
    }

    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        _showSuccessDialog('Absen Masuk Berhasil!', 'Waktu masuk telah dicatat.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attendance.error ?? 'Gagal melakukan absensi'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Handle Absen Pulang
  Future<void> _handleCheckOut() async {
    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);
    final success = await attendance.checkOut(user.uid);
    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        _showSuccessDialog('Absen Pulang Berhasil!', 'Terima kasih atas kerja keras hari ini.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attendance.error ?? 'Gagal melakukan check out'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? AppTheme.cardDark
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.accentGreen, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Selesai',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final timeFormatted = DateFormat('HH:mm').format(now);
    final dateFormatted = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);

    return Consumer<AttendanceProvider>(
      builder: (context, attendance, _) {
        final today = attendance.todayAttendance;
        final hasCheckedIn = today?.checkIn != null;
        final hasCheckedOut = today?.checkOut != null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Presensi Kerja'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Jam & Tanggal Sekarang
                Text(
                  timeFormatted,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                        letterSpacing: 2,
                      ),
                ),
                Text(
                  dateFormatted,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                ),
                const SizedBox(height: 20),

                // Status Kartu Hari Ini
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppTheme.dividerColor : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusItem(
                        context,
                        'Masuk',
                        today?.checkInFormatted ?? '--:--',
                        hasCheckedIn ? AppTheme.accentGreen : AppTheme.textMuted,
                        Icons.login_rounded,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: isDark ? AppTheme.dividerColor : Colors.grey.shade300,
                      ),
                      _buildStatusItem(
                        context,
                        'Pulang',
                        today?.checkOutFormatted ?? '--:--',
                        hasCheckedOut ? AppTheme.accentCoral : AppTheme.textMuted,
                        Icons.logout_rounded,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: isDark ? AppTheme.dividerColor : Colors.grey.shade300,
                      ),
                      _buildStatusItem(
                        context,
                        'Status',
                        today?.statusLabel ?? 'Belum',
                        hasCheckedIn
                            ? (today?.status == 'late'
                                ? AppTheme.accentOrange
                                : AppTheme.accentGreen)
                            : AppTheme.textMuted,
                        Icons.verified_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Metode Selector (Kamera vs Sidik Jari)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardDark : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMethodTab(
                          icon: Icons.face_rounded,
                          label: 'Kamera Muka',
                          isSelected: _selectedMethod == 0,
                          onTap: () => setState(() => _selectedMethod = 0),
                        ),
                      ),
                      Expanded(
                        child: _buildMethodTab(
                          icon: Icons.fingerprint_rounded,
                          label: 'Sidik Jari',
                          isSelected: _selectedMethod == 1,
                          onTap: () => setState(() => _selectedMethod = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Area Verifikasi (Kamera atau Sidik Jari)
                if (_selectedMethod == 0)
                  _buildCameraView(context, isDark)
                else
                  _buildFingerprintView(context, isDark),

                const SizedBox(height: 28),

                // Tombol Aksi (Absen Masuk / Absen Pulang)
                if (!hasCheckedIn) ...[
                  GradientButton(
                    text: 'Absen Masuk',
                    icon: Icons.login_rounded,
                    isLoading: _isProcessing || attendance.isLoading,
                    gradient: AppTheme.greenGradient,
                    onPressed: _handleCheckIn,
                  ),
                ] else if (!hasCheckedOut) ...[
                  GradientButton(
                    text: 'Absen Pulang',
                    icon: Icons.logout_rounded,
                    isLoading: _isProcessing || attendance.isLoading,
                    gradient: AppTheme.coralGradient,
                    onPressed: _handleCheckOut,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Anda sudah absen masuk pada ${today?.checkInFormatted}',
                    style: const TextStyle(
                      color: AppTheme.accentGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppTheme.accentGreen, size: 36),
                        SizedBox(height: 8),
                        Text(
                          'Presensi Hari Ini Lengkap!',
                          style: TextStyle(
                            color: AppTheme.accentGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sampai jumpa di hari kerja berikutnya.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildMethodTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView(BuildContext context, bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: _takeSelfie,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDarkAlt : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                color: _capturedFaceImage != null
                    ? AppTheme.accentGreen
                    : AppTheme.primaryBlue,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_capturedFaceImage != null
                          ? AppTheme.accentGreen
                          : AppTheme.primaryBlue)
                      .withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: _capturedFaceImage != null
                  ? Image.file(_capturedFaceImage!, fit: BoxFit.cover)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          size: 52,
                          color: AppTheme.primaryBlue.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ketuk untuk Ambil Foto',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _takeSelfie,
              icon: Icon(
                _capturedFaceImage != null
                    ? Icons.replay_rounded
                    : Icons.add_a_photo_rounded,
                size: 18,
                color: AppTheme.primaryBlue,
              ),
              label: Text(
                _capturedFaceImage != null ? 'Ambil Ulang Selfie' : 'Buka Kamera Depan',
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Posisikan wajah Anda tegak dan pencahayaan cukup',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildFingerprintView(BuildContext context, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 16),
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.3),
                  AppTheme.primaryBlue.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.fingerprint_rounded,
                size: 84,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Tempelkan Jari Anda ke Sensor',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Verifikasi biometrik langsung dengan sensor smartphone Anda',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
