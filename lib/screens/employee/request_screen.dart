import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/request_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  String _selectedType = 'leave'; // 'leave' | 'overtime' | 'resignation'
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _endDate = DateTime.now().add(const Duration(days: 1));
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final attendance = context.read<AttendanceProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final newRequest = RequestModel(
      uid: user.uid,
      userName: user.name,
      type: _selectedType,
      reason: _reasonController.text.trim(),
      startDate: _startDate,
      endDate: _selectedType == 'leave' ? _endDate : null,
      status: 'pending',
    );

    final success = await attendance.submitRequest(newRequest);
    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        _reasonController.clear();
        _tabController.animateTo(1); // Pindah ke tab Riwayat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Surat pengajuan berhasil dikirim ke Admin'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attendance.error ?? 'Gagal mengirim pengajuan'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Surat'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Buat Pengajuan'),
            Tab(text: 'Riwayat Surat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormTab(context, isDark),
          _buildHistoryTab(context, isDark),
        ],
      ),
    );
  }

  Widget _buildFormTab(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Jenis Pengajuan',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Opsi Tipe Surat
            Row(
              children: [
                Expanded(
                  child: _buildTypeOption(
                    title: 'Cuti / Izin',
                    icon: Icons.beach_access_rounded,
                    type: 'leave',
                    color: AppTheme.primaryBlue,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTypeOption(
                    title: 'Lembur',
                    icon: Icons.more_time_rounded,
                    type: 'overtime',
                    color: AppTheme.accentOrange,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTypeOption(
                    title: 'Resign',
                    icon: Icons.exit_to_app_rounded,
                    type: 'resignation',
                    color: AppTheme.accentCoral,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tanggal
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedType == 'overtime'
                            ? 'Tanggal Lembur'
                            : 'Tanggal Mulai',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickStartDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.dividerColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded,
                                  size: 18, color: AppTheme.primaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat('dd MMM yyyy').format(_startDate),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedType == 'leave') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal Selesai',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickEndDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.dividerColor
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded,
                                    size: 18, color: AppTheme.accentCyan),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _endDate != null
                                        ? DateFormat('dd MMM yyyy')
                                            .format(_endDate!)
                                        : '--',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Alasan Pengajuan
            Text(
              'Alasan Pengajuan',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _selectedType == 'leave'
                    ? 'Jelaskan keperluan izin atau cuti Anda...'
                    : (_selectedType == 'overtime'
                        ? 'Jelaskan pekerjaan/tugas lembur yang akan dikerjakan...'
                        : 'Jelaskan alasan pengunduran diri Anda...'),
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                filled: true,
                fillColor: isDark ? AppTheme.cardDark : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.dividerColor : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.dividerColor : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Harap isi alasan pengajuan';
                }
                if (val.trim().length < 5) {
                  return 'Alasan terlalu pendek';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Tombol Kirim
            GradientButton(
              text: 'Kirim Pengajuan ke Admin',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String title,
    required IconData icon,
    required String type,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (isDark ? AppTheme.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppTheme.dividerColor : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppTheme.textMuted, size: 26),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? color
                    : (isDark ? Colors.white70 : AppTheme.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, bool isDark) {
    return Consumer<AttendanceProvider>(
      builder: (context, attendance, _) {
        final requests = attendance.requests;

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text(
                  'Belum ada riwayat pengajuan surat',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final statusColor = req.status == 'approved'
                ? AppTheme.accentGreen
                : (req.status == 'rejected'
                    ? AppTheme.accentCoral
                    : AppTheme.accentOrange);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.dividerColor : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(req.typeIcon, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            req.typeLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          req.statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    req.reason,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppTheme.textPrimaryLight,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        req.endDate != null
                            ? '${DateFormat('dd/MM/yyyy').format(req.startDate)} - ${DateFormat('dd/MM/yyyy').format(req.endDate!)}'
                            : DateFormat('dd/MM/yyyy').format(req.startDate),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (req.adminNote.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.comment_rounded,
                              size: 14, color: AppTheme.primaryBlue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Catatan Admin: ${req.adminNote}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
