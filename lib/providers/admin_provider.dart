import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/request_model.dart';
import '../models/schedule_model.dart';
import '../services/api/attendance_api_service.dart';
import '../services/local_db_service.dart';

class AdminProvider extends ChangeNotifier {
  final AttendanceApiService _attendanceApi = AttendanceApiService();
  final LocalDbService _localDb = LocalDbService();

  List<UserModel> _employees = [];
  List<AttendanceModel> _attendances = [];
  List<RequestModel> _requests = [];
  List<ScheduleModel> _schedules = [];
  int _totalEmployees = 0;
  Map<String, int> _todayStats = {};
  int _pendingRequests = 0;
  bool _isLoading = false;
  String? _error;

  /// Status apakah endpoint admin khusus telah diimplementasikan di backend Node.js
  bool get isBackendSupported => false;

  List<UserModel> get employees => _employees;
  List<AttendanceModel> get attendances => _attendances;
  List<RequestModel> get requests => _requests;
  List<ScheduleModel> get schedules => _schedules;
  int get totalEmployees => _totalEmployees;
  Map<String, int> get todayStats => _todayStats;
  int get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Inisialisasi data admin.
  /// Jadwal kerja diambil secara nyata dari REST API (GET /api/schedules).
  /// Modul karyawan, rekap presensi seluruh tim, dan approval surat
  /// menggunakan data pratinjau lokal karena backend Node.js belum memiliki endpoint admin khusus.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Ambil data jadwal kerja dari endpoint REST API backend
      try {
        _schedules = await _attendanceApi.getSchedules();
      } catch (_) {
        _schedules = _localDb.getAllSchedules();
      }

      // 2. Data pratinjau lokal untuk fitur admin yang belum ada endpoint backend-nya
      _employees = _localDb.getAllEmployees();
      _attendances = _localDb.getAllAttendances();
      _requests = _localDb.getAllRequests();

      _totalEmployees = _employees.length;
      _calculateTodayStats();
      _pendingRequests = _requests.where((r) => r.status == 'pending').length;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh dashboard stats
  Future<void> refreshStats() async {
    try {
      try {
        _schedules = await _attendanceApi.getSchedules();
      } catch (_) {}

      _employees = _localDb.getAllEmployees();
      _attendances = _localDb.getAllAttendances();
      _requests = _localDb.getAllRequests();
      _totalEmployees = _employees.length;
      _calculateTodayStats();
      _pendingRequests = _requests.where((r) => r.status == 'pending').length;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  // Toggle employee status
  Future<bool> toggleEmployeeStatus(String uid, bool isActive) async {
    try {
      await _localDb.toggleEmployeeStatus(uid, isActive);
      _employees = _localDb.getAllEmployees();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Operasi ini belum didukung oleh endpoint REST API backend.';
      notifyListeners();
      return false;
    }
  }

  // Update employee
  Future<bool> updateEmployee(String uid, Map<String, dynamic> data) async {
    try {
      await _localDb.updateEmployee(uid, data);
      _employees = _localDb.getAllEmployees();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Operasi ini belum didukung oleh endpoint REST API backend.';
      notifyListeners();
      return false;
    }
  }

  // Delete employee
  Future<bool> deleteEmployee(String uid) async {
    try {
      await _localDb.deleteEmployee(uid);
      _employees = _localDb.getAllEmployees();
      _totalEmployees = _employees.length;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Operasi ini belum didukung oleh endpoint REST API backend.';
      notifyListeners();
      return false;
    }
  }

  // Update request status
  Future<bool> updateRequestStatus(
    String docId, {
    required String status,
    String adminNote = '',
  }) async {
    try {
      await _localDb.updateRequestStatus(
        docId,
        status: status,
        adminNote: adminNote,
      );
      _requests = _localDb.getAllRequests();
      _pendingRequests = _requests.where((r) => r.status == 'pending').length;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Operasi ini belum didukung oleh endpoint REST API backend.';
      notifyListeners();
      return false;
    }
  }

  // Get attendances filtered by date
  List<AttendanceModel> getAttendancesByDate(String date) {
    return _attendances.where((a) => a.date == date).toList();
  }

  void _calculateTodayStats() {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final todayAttendances = _attendances.where(
      (attendance) => attendance.date == today,
    );

    _todayStats = {
      'present': todayAttendances
          .where((attendance) => attendance.status == 'present')
          .length,
      'late': todayAttendances
          .where((attendance) => attendance.status == 'late')
          .length,
    };
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
