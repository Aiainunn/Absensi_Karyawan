import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/attendance_card.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/stat_card.dart';
import 'attendance_report_screen.dart';
import 'employee_list_screen.dart';
import 'request_management_screen.dart';
import 'schedule_management_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().initialize();
    });
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? AppTheme.cardDark
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCoral,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardOverview(context),
      const EmployeeListScreen(),
      const AttendanceReportScreen(),
      const RequestManagementScreen(),
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
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          CustomNavItem(
            icon: Icons.people_outline_rounded,
            activeIcon: Icons.people_rounded,
            label: 'Karyawan',
          ),
          CustomNavItem(
            icon: Icons.assessment_outlined,
            activeIcon: Icons.assessment_rounded,
            label: 'Laporan',
          ),
          CustomNavItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment_rounded,
            label: 'Surat',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardOverview(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final todayString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final dateFormatted =
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);

    return SafeArea(
      child: Consumer2<AuthProvider, AdminProvider>(
        builder: (context, auth, admin, _) {
          final user = auth.currentUser;
          final todayStats = admin.todayStats;
          final todayAttendances = admin.getAttendancesByDate(todayString);

          return RefreshIndicator(
            onRefresh: () async {
              await admin.refreshStats();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppTheme.purpleGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(Icons.admin_panel_settings_rounded,
                                  color: Colors.white, size: 26),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${user?.name ?? "Admin"} 👑',
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
                              const Text(
                                'Panel Manajemen Absensi',
                                style: TextStyle(
                                  color: AppTheme.accentCyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => auth.toggleDarkMode(),
                            icon: Icon(
                              auth.isDarkMode
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _confirmLogout(context),
                            icon: const Icon(Icons.logout_rounded,
                                color: AppTheme.accentCoral),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Today Date Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.dividerColor
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: AppTheme.primaryBlue),
                        const SizedBox(width: 10),
                        Text(
                          dateFormatted,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4 Stat Cards Grid
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total Karyawan',
                          value: '${admin.totalEmployees}',
                          icon: Icons.people_alt_rounded,
                          gradient: AppTheme.primaryGradient,
                          onTap: () => setState(() => _currentIndex = 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Hadir Hari Ini',
                          value: '${todayStats['present'] ?? todayAttendances.where((a) => a.status == "present").length}',
                          icon: Icons.check_circle_rounded,
                          gradient: AppTheme.greenGradient,
                          onTap: () => setState(() => _currentIndex = 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Terlambat Hari Ini',
                          value: '${todayStats['late'] ?? todayAttendances.where((a) => a.status == "late").length}',
                          icon: Icons.warning_rounded,
                          gradient: AppTheme.coralGradient,
                          onTap: () => setState(() => _currentIndex = 2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Surat Menunggu',
                          value: '${admin.pendingRequests}',
                          icon: Icons.pending_actions_rounded,
                          gradient: AppTheme.purpleGradient,
                          onTap: () => setState(() => _currentIndex = 3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Menu Pintasan Admin
                  Text(
                    'Pintasan Manajemen',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAdminShortcut(
                          context,
                          'Kelola Jadwal',
                          Icons.schedule_rounded,
                          AppTheme.accentCyan,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ScheduleManagementScreen(),
                              ),
                            );
                          },
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAdminShortcut(
                          context,
                          'Kelola Surat',
                          Icons.assignment_turned_in_rounded,
                          AppTheme.accentOrange,
                          () => setState(() => _currentIndex = 3),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Live Feed Presensi Hari Ini
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Presensi Masuk Hari Ini',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _currentIndex = 2),
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

                  if (todayAttendances.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.today_rounded,
                              size: 48,
                              color: AppTheme.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          const Text(
                            'Belum ada karyawan yang absen hari ini',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...todayAttendances
                        .take(5)
                        .map((item) => AttendanceCard(attendance: item)),
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

  Widget _buildAdminShortcut(
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.dividerColor : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
