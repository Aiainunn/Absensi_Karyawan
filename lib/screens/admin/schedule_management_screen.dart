import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/schedule_model.dart';
import '../../providers/admin_provider.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  void _showEditScheduleDialog(
      BuildContext context, String docId, ScheduleModel schedule) {
    final startController = TextEditingController(text: schedule.startTime);
    final endController = TextEditingController(text: schedule.endTime);
    bool isActive = schedule.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(ctx).brightness == Brightness.dark
              ? AppTheme.cardDark
              : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Atur Jadwal: ${schedule.dayLabel}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Hari Kerja Aktif'),
                value: isActive,
                activeThumbColor: AppTheme.accentGreen,
                onChanged: (val) => setDialogState(() => isActive = val),
                contentPadding: EdgeInsets.zero,
              ),
              if (isActive) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: startController,
                  decoration: const InputDecoration(
                    labelText: 'Jam Masuk (HH:mm)',
                    hintText: '08:00',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endController,
                  decoration: const InputDecoration(
                    labelText: 'Jam Pulang (HH:mm)',
                    hintText: '17:00',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Pembaruan jadwal belum didukung oleh endpoint REST API backend (saat ini hanya tersedia GET /api/schedules).'),
                    backgroundColor: AppTheme.accentOrange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Jadwal Kerja'),
        centerTitle: true,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          final schedules = admin.schedules;

          final displayList = ScheduleModel.allDays.map((day) {
            final existing =
                schedules.where((s) => s.dayOfWeek.toLowerCase() == day);
            if (existing.isNotEmpty) return existing.first;

            final isWeekend = day == 'saturday' || day == 'sunday';
            return ScheduleModel(
              id: 'temp_$day',
              dayOfWeek: day,
              startTime: isWeekend ? '--:--' : '08:00',
              endTime: isWeekend ? '--:--' : '17:00',
              isActive: !isWeekend,
            );
          }).toList();

          return Column(
            children: [
              // Info Banner: Terhubung ke REST API
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_done_rounded,
                        size: 20, color: AppTheme.primaryBlue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Jadwal sinkron langsung dari backend REST API (GET /api/schedules).',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final item = displayList[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
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
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item.isActive
                                  ? AppTheme.accentGreen.withValues(alpha: 0.15)
                                  : AppTheme.accentCoral.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                item.shortDayLabel,
                                style: TextStyle(
                                  color: item.isActive
                                      ? AppTheme.accentGreen
                                      : AppTheme.accentCoral,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.dayLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.isActive
                                      ? '${item.startTime} - ${item.endTime}'
                                      : 'Libur',
                                  style: TextStyle(
                                    color: item.isActive
                                        ? AppTheme.textMuted
                                        : AppTheme.accentCoral,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showEditScheduleDialog(
                                context, item.id, item),
                            icon: const Icon(Icons.edit_outlined,
                                size: 20, color: AppTheme.primaryBlue),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
