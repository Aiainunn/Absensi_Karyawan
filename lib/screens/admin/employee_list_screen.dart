import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import '../auth/register_screen.dart';
import 'employee_detail_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all'; // 'all' | 'active' | 'inactive'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Data Karyawan'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
        },
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Tambah Karyawan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          final employees = admin.employees;

          final filteredList = employees.where((emp) {
            final matchesQuery = emp.name
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                emp.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                emp.department
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());

            if (!matchesQuery) return false;

            if (_filter == 'active') return emp.isActive;
            if (_filter == 'inactive') return !emp.isActive;
            return true;
          }).toList();

          return Column(
            children: [
              // Search & Filter
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Cari nama, email, atau divisi...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppTheme.primaryBlue),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? AppTheme.cardDark : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppTheme.dividerColor
                                : Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppTheme.dividerColor
                                : Colors.grey.shade300,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFilterChip('Semua (${employees.length})', 'all', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Aktif (${employees.where((e) => e.isActive).length})',
                          'active',
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Nonaktif (${employees.where((e) => !e.isActive).length})',
                          'inactive',
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Employee List
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline_rounded,
                                size: 56,
                                color:
                                    AppTheme.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada hasil untuk "$_searchQuery"'
                                  : 'Belum ada data karyawan',
                              style: const TextStyle(color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final emp = filteredList[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.dividerColor
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: emp.isActive
                                      ? AppTheme.primaryGradient
                                      : LinearGradient(
                                          colors: [
                                            Colors.grey.shade500,
                                            Colors.grey.shade700
                                          ],
                                        ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    emp.initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                emp.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.textPrimaryLight,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    '${emp.position.isNotEmpty ? emp.position : "Karyawan"} • ${emp.department.isNotEmpty ? emp.department : "Umum"}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    emp.email,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: emp.isActive
                                          ? AppTheme.accentGreen
                                              .withValues(alpha: 0.15)
                                          : AppTheme.accentCoral
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      emp.isActive ? 'Aktif' : 'Nonaktif',
                                      style: TextStyle(
                                        color: emp.isActive
                                            ? AppTheme.accentGreen
                                            : AppTheme.accentCoral,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: AppTheme.textMuted, size: 20),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EmployeeDetailScreen(employee: emp),
                                  ),
                                );
                              },
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

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _filter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
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
