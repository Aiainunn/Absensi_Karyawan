import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/request_model.dart';
import '../../providers/admin_provider.dart';

class RequestManagementScreen extends StatefulWidget {
  const RequestManagementScreen({super.key});

  @override
  State<RequestManagementScreen> createState() =>
      _RequestManagementScreenState();
}

class _RequestManagementScreenState extends State<RequestManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showActionDialog(
    BuildContext context,
    RequestModel request,
    String targetStatus, // 'approved' | 'rejected'
  ) {
    final noteController = TextEditingController();
    final isApprove = targetStatus == 'approved';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? AppTheme.cardDark
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isApprove ? 'Setujui Pengajuan' : 'Tolak Pengajuan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengajuan ${request.typeLabel} oleh ${request.userName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Catatan Admin (opsional)',
                hintText: isApprove
                    ? 'Contoh: Disetujui, selamat berlibur.'
                    : 'Contoh: Pekerjaan belum selesai.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final admin = context.read<AdminProvider>();
              final success = await admin.updateRequestStatus(
                request.id,
                status: targetStatus,
                adminNote: noteController.text.trim(),
              );

              if (ctx.mounted) Navigator.pop(ctx);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? (isApprove
                            ? 'Pengajuan telah disetujui'
                            : 'Pengajuan telah ditolak')
                        : 'Gagal memperbarui status pengajuan'),
                    backgroundColor:
                        isApprove ? AppTheme.accentGreen : AppTheme.accentCoral,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isApprove ? AppTheme.accentGreen : AppTheme.accentCoral,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isApprove ? 'Setujui' : 'Tolak',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Surat Karyawan'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Menunggu'),
            Tab(text: 'Disetujui'),
            Tab(text: 'Ditolak'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList('pending'),
          _buildRequestList('approved'),
          _buildRequestList('rejected'),
        ],
      ),
    );
  }

  Widget _buildRequestList(String statusFilter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final requests =
            admin.requests.where((r) => r.status == statusFilter).toList();

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_read_rounded,
                    size: 56,
                    color: AppTheme.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  statusFilter == 'pending'
                      ? 'Tidak ada pengajuan surat yang menunggu persetujuan'
                      : (statusFilter == 'approved'
                          ? 'Belum ada pengajuan yang disetujui'
                          : 'Tidak ada pengajuan yang ditolak'),
                  style: const TextStyle(color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];

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
                  // User info & Request Type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.person_rounded,
                                  size: 20, color: AppTheme.primaryBlue),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm')
                                    .format(req.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(req.typeIcon,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              req.typeLabel,
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dates
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        req.endDate != null
                            ? 'Rentang: ${DateFormat('dd MMM yyyy').format(req.startDate)} - ${DateFormat('dd MMM yyyy').format(req.endDate!)}'
                            : 'Tanggal: ${DateFormat('dd MMM yyyy').format(req.startDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Reason
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Alasan: "${req.reason}"',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white70
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),

                  // Admin note if present
                  if (req.adminNote.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Catatan Admin: ${req.adminNote}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                  ],

                  // Action buttons if pending
                  if (statusFilter == 'pending') ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _showActionDialog(context, req, 'rejected'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppTheme.accentCoral, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Tolak',
                                style: TextStyle(
                                    color: AppTheme.accentCoral,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                _showActionDialog(context, req, 'approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Setujui',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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
