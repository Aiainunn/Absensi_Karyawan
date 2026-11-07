import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/attendance_card.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/stat_card.dart';
import 'attendance_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'request_screen.dart';
import 'schedule_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<AttendanceProvider>().initialize(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeDashboard(context),
      const AttendanceScreen(),
      const ScheduleScreen(),
      const RequestScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          CustomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Beranda',
          ),
          CustomNavItem(
            icon: Icons.fingerprint_rounded,
            activeIcon: Icons.fingerprint_rounded,
            label: 'Presensi',
          ),
          CustomNavItem(
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_month_rounded,
            label: 'Jadwal',
          ),
          CustomNavItem(
            icon: Icons.description_outlined,
            activeIcon: Icons.description_rounded,
            label: 'Surat',
          ),
          CustomNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeDashboard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final todayFormatted =
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);

    return SafeArea(
      child: Consumer2<AuthProvider, AttendanceProvider>(
        builder: (context, auth, attendance, _) {
          final user = auth.currentUser;
          final today = attendance.todayAttendance;
          final stats = attendance.monthlyStats;
          final history = attendance.history;

          return RefreshIndicator(
            onRefresh: () async {
              if (user != null) {
                await attendance.initialize(user.uid);
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                user?.initials ?? 'K',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${user?.name ?? "Karyawan"} 👋',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : AppTheme.textPrimaryLight,
                                    ),
                              ),
                              Text(
                                user?.position.isNotEmpty == true
                                    ? user!.position
                                    : 'Karyawan',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => auth.toggleDarkMode(),
                        icon: Icon(
                          auth.isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Notification Banner (Pengingat Kerja)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pengingat Presensi Kerja',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                today?.checkIn != null
                                    ? 'Anda sudah absen masuk jam ${today!.checkInFormatted}. Jangan lupa absen pulang saat selesai shift.'
                                    : 'Jam kerja dimulai pukul 08:00 WIB. Segera lakukan presensi kehadiran Anda.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white70
                                      : AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Status Presensi Hari Ini (Featured Card)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppTheme.cardGradient
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Colors.grey.shade50],
                            ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.dividerColor
                            : Colors.grey.shade200,
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Presensi Hari Ini',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  todayFormatted,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (today?.checkIn != null
                                        ? AppTheme.accentGreen
                                        : AppTheme.accentCoral)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                today?.checkIn != null
                                    ? (today?.status == 'late'
                                        ? 'Terlambat'
                                        : 'Sudah Hadir')
                                    : 'Belum Masuk',
                                style: TextStyle(
                                  color: today?.checkIn != null
                                      ? (today?.status == 'late'
                                          ? AppTheme.accentOrange
                                          : AppTheme.accentGreen)
                                      : AppTheme.accentCoral,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Check in / Check out counters
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPresenceTimeInfo(
                              context,
                              'Jam Masuk',
                              today?.checkInFormatted ?? '--:--',
                              Icons.login_rounded,
                              today?.checkIn != null
                                  ? AppTheme.accentGreen
                                  : AppTheme.textMuted,
                            ),
                            Container(
                              height: 48,
                              width: 1,
                              color: isDark
                                  ? AppTheme.dividerColor
                                  : Colors.grey.shade200,
                            ),
                            _buildPresenceTimeInfo(
                              context,
                              'Jam Pulang',
                              today?.checkOutFormatted ?? '--:--',
                              Icons.logout_rounded,
                              today?.checkOut != null
                                  ? AppTheme.accentCoral
                                  : AppTheme.textMuted,
                            ),
                            Container(
                              height: 48,
                              width: 1,
                              color: isDark
                                  ? AppTheme.dividerColor
                                  : Colors.grey.shade200,
                            ),
                            _buildPresenceTimeInfo(
                              context,
                              'Total Jam',
                              today?.workHoursFormatted ?? '0j 0m',
                              Icons.timelapse_rounded,
                              AppTheme.primaryBlue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Tombol Aksi Langsung
                        GradientButton(
                          text: today?.checkIn == null
                              ? 'Lakukan Presensi Masuk'
                              : (today?.checkOut == null
                                  ? 'Lakukan Presensi Pulang'
                                  : 'Presensi Selesai Hari Ini'),
                          icon: today?.checkIn == null
                              ? Icons.camera_alt_rounded
                              : Icons.check_circle_outline_rounded,
                          gradient: today?.checkIn == null
                              ? AppTheme.greenGradient
                              : (today?.checkOut == null
                                  ? AppTheme.coralGradient
                                  : null),
                          onPressed: () {
                            setState(() => _currentIndex = 1);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu Akses Cepat
                  Text(
                    'Menu Cepat',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          'Jadwal',
                          Icons.calendar_month_rounded,
                          AppTheme.primaryBlue,
                          () => setState(() => _currentIndex = 2),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          'Ajukan Surat',
                          Icons.assignment_rounded,
                          AppTheme.accentOrange,
                          () => setState(() => _currentIndex = 3),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          'Riwayat',
                          Icons.history_rounded,
                          AppTheme.accentGreen,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            );
                          },
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Statistik Bulan Ini
                  Text(
                    'Statistik Kehadiran Bulan Ini',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Hadir',
                          value: '${stats['present'] ?? 0}',
                          icon: Icons.check_circle_rounded,
                          gradient: AppTheme.greenGradient,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          title: 'Terlambat',
                          value: '${stats['late'] ?? 0}',
                          icon: Icons.warning_amber_rounded,
                          gradient: AppTheme.coralGradient,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          title: 'Total Hari',
                          value: '${stats['total'] ?? history.length}',
                          icon: Icons.date_range_rounded,
                          gradient: AppTheme.purpleGradient,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Aktivitas Terakhir
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Aktivitas Presensi Terakhir',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (history.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.event_busy_rounded,
                              size: 48,
                              color: AppTheme.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          const Text(
                            'Belum ada riwayat absensi',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...history.take(3).map((item) => AttendanceCard(attendance: item)),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPresenceTimeInfo(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.dividerColor : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
