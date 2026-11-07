import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/schedule_model.dart';
import '../../providers/attendance_provider.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final todayName = dayNames[now.weekday - 1];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kerja'),
        centerTitle: true,
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, attendance, _) {
          final schedules = attendance.schedules;

          // Default week days jika belum ada data Firestore
          final defaultSchedules = ScheduleModel.allDays.map((day) {
            final existing = schedules.where((s) => s.dayOfWeek.toLowerCase() == day);
            if (existing.isNotEmpty) return existing.first;

            final isWeekend = day == 'saturday' || day == 'sunday';
            return ScheduleModel(
              dayOfWeek: day,
              startTime: isWeekend ? '--:--' : '08:00',
              endTime: isWeekend ? '--:--' : '17:00',
              isActive: !isWeekend,
            );
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner Kebijakan Kerja
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.schedule_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jam Kerja Standar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Senin - Jumat (08:00 - 17:00 WIB)\nToleransi telat 15 menit',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Jadwal Mingguan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                // List Jadwal Hari
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: defaultSchedules.length,
                  itemBuilder: (context, index) {
                    final item = defaultSchedules[index];
                    final isToday = item.dayOfWeek.toLowerCase() == todayName;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isToday
                            ? (isDark
                                ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                                : AppTheme.primaryBlue.withValues(alpha: 0.08))
                            : (isDark ? AppTheme.cardDark : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isToday
                              ? AppTheme.primaryBlue
                              : (isDark
                                  ? AppTheme.dividerColor
                                  : Colors.grey.shade200),
                          width: isToday ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Day badge
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppTheme.primaryBlue
                                  : (item.isActive
                                      ? (isDark
                                          ? Colors.white10
                                          : Colors.grey.shade100)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.04)
                                          : Colors.grey.shade100)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                item.shortDayLabel,
                                style: TextStyle(
                                  color: isToday
                                      ? Colors.white
                                      : (item.isActive
                                          ? (isDark
                                              ? Colors.white
                                              : AppTheme.textPrimaryLight)
                                          : AppTheme.textMuted),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Day info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.dayLabel,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white
                                            : AppTheme.textPrimaryLight,
                                      ),
                                    ),
                                    if (isToday) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryBlue,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'HARI INI',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.isActive
                                      ? 'Shift Reguler: 8 Jam Kerja'
                                      : 'Hari Libur / Akhir Pekan',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          // Time display
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                item.isActive
                                    ? '${item.startTime} - ${item.endTime}'
                                    : 'LIBUR',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: item.isActive
                                      ? (isDark
                                          ? Colors.white
                                          : AppTheme.textPrimaryLight)
                                      : AppTheme.accentCoral,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.isActive
                                      ? AppTheme.accentGreen.withValues(alpha: 0.15)
                                      : Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.isActive ? 'Kerja' : 'Off',
                                  style: TextStyle(
                                    color: item.isActive
                                        ? AppTheme.accentGreen
                                        : AppTheme.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
