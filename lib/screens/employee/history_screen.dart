import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/attendance_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'all'; // 'all' | 'present' | 'late'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Presensi'),
        centerTitle: true,
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, attendance, _) {
          final history = attendance.history;
          final stats = attendance.monthlyStats;

          final filteredList = history.where((item) {
            if (_selectedFilter == 'all') return true;
            return item.status == _selectedFilter;
          }).toList();

          return Column(
            children: [
              // Summary Banner
              Container(
                margin: const EdgeInsets.all(20),
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
                    _buildStatItem('Hadir', '${stats['present'] ?? 0} Hari',
                        AppTheme.accentGreen),
                    Container(
                      height: 36,
                      width: 1,
                      color: isDark ? AppTheme.dividerColor : Colors.grey.shade200,
                    ),
                    _buildStatItem('Terlambat', '${stats['late'] ?? 0} Hari',
                        AppTheme.accentOrange),
                    Container(
                      height: 36,
                      width: 1,
                      color: isDark ? AppTheme.dividerColor : Colors.grey.shade200,
                    ),
                    _buildStatItem('Total Absen', '${stats['total'] ?? history.length}',
                        AppTheme.primaryBlue),
                  ],
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildFilterChip('Semua', 'all', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Tepat Waktu', 'present', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Terlambat', 'late', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // List of Attendances
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded,
                                size: 56,
                                color: AppTheme.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada data presensi',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          return AttendanceCard(attendance: filteredList[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      backgroundColor: isDark ? AppTheme.cardDark : Colors.grey.shade100,
      selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected
            ? AppTheme.primaryBlue
            : (isDark ? AppTheme.dividerColor : Colors.grey.shade300),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
