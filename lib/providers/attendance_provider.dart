import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../models/schedule_model.dart';
import '../models/request_model.dart';
import '../services/api/attendance_api_service.dart';
import '../services/biometric_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceApiService _attendanceApi = AttendanceApiService();
  final BiometricService _biometricService = BiometricService();

  AttendanceModel? _todayAttendance;
  List<AttendanceModel> _history = [];
  List<ScheduleModel> _schedules = [];
  final List<RequestModel> _requests = [];
  Map<String, int> _monthlyStats = {};
  bool _isLoading = false;
  String? _error;
  bool _isBiometricAvailable = false;

  AttendanceModel? get todayAttendance => _todayAttendance;
  List<AttendanceModel> get history => _history;
  List<ScheduleModel> get schedules => _schedules;
  List<RequestModel> get requests => _requests;
  Map<String, int> get monthlyStats => _monthlyStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isBiometricAvailable => _isBiometricAvailable;

  bool get hasCheckedIn => _todayAttendance?.checkIn != null;
  bool get hasCheckedOut => _todayAttendance?.checkOut != null;

  /// Inisialisasi data presensi, statistik bulanan, riwayat, dan jadwal kerja.
  Future<void> initialize(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _isBiometricAvailable = await _biometricService.isBiometricAvailable();

      // Panggil endpoint secara paralel untuk performa optimal
      await Future.wait([
        _fetchTodayAttendance(),
        _fetchMonthlyStats(),
        _fetchHistory(),
        _fetchSchedules(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mengambil data absensi hari ini (GET /api/attendance/today)
  Future<void> _fetchTodayAttendance() async {
    try {
      _todayAttendance = await _attendanceApi.getTodayAttendance();
    } catch (e) {
      debugPrint('Error fetch today attendance: $e');
    }
  }

  /// Mengambil statistik absensi bulanan (GET /api/attendance/monthly-stats)
  Future<void> _fetchMonthlyStats() async {
    try {
      final now = DateTime.now();
      final data = await _attendanceApi.getMonthlyStats(
        month: now.month,
        year: now.year,
      );

      int parseInt(dynamic val) => int.tryParse(val?.toString() ?? '0') ?? 0;

      // Petakan kunci agar kompatibel dengan UI lama maupun kontrak API baru
      _monthlyStats = {
        'total': parseInt(data['totalAttendance']),
        'totalAttendance': parseInt(data['totalAttendance']),
        'present': parseInt(data['presentDays']),
        'presentDays': parseInt(data['presentDays']),
        'late': parseInt(data['lateDays']),
        'lateDays': parseInt(data['lateDays']),
        'absent': parseInt(data['absentDays']),
        'absentDays': parseInt(data['absentDays']),
        'permission': parseInt(data['permissionDays']),
        'permissionDays': parseInt(data['permissionDays']),
        'workHours':
            (double.tryParse(data['totalWorkHours']?.toString() ?? '0') ?? 0)
                .round(),
      };
    } catch (e) {
      debugPrint('Error fetch monthly stats: $e');
    }
  }

  /// Mengambil riwayat absensi (GET /api/attendance/history)
  Future<void> _fetchHistory() async {
    try {
      _history = await _attendanceApi.getHistory(limit: 30);
    } catch (e) {
      debugPrint('Error fetch history: $e');
    }
  }

  /// Mengambil jadwal kerja dari database MySQL (GET /api/schedules)
  Future<void> _fetchSchedules() async {
    try {
      _schedules = await _attendanceApi.getSchedules();
    } catch (e) {
      debugPrint('Error fetch schedules: $e');
    }
  }

  /// Refresh seluruh data (digunakan untuk Pull-to-Refresh)
  Future<void> refreshAll() async {
    try {
      await Future.wait([
        _fetchTodayAttendance(),
        _fetchMonthlyStats(),
        _fetchHistory(),
        _fetchSchedules(),
      ]);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Check-in dengan kamera selfie (POST /api/attendance/check-in)
  /// [photoUrl] berupa Base64 data URL string yang diambil dari kamera.
  Future<bool> checkInWithCamera({
    required String uid,
    required String userName,
    String? photoUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (photoUrl == null || photoUrl.isEmpty) {
        throw Exception('Foto selfie absensi wajib disertakan.');
      }

      _todayAttendance = await _attendanceApi.checkIn(
        method: 'camera',
        photoUrl: photoUrl,
      );

      // Refresh data statistik dan riwayat terbaru setelah check-in berhasil
      await Future.wait([_fetchMonthlyStats(), _fetchHistory()]);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check-in dengan sidik jari / biometrik (POST /api/attendance/check-in)
  Future<bool> checkInWithFingerprint({
    required String uid,
    required String userName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) {
        _error = 'Verifikasi sidik jari dibatalkan atau gagal.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _todayAttendance = await _attendanceApi.checkIn(method: 'fingerprint');

      // Refresh data statistik dan riwayat terbaru
      await Future.wait([_fetchMonthlyStats(), _fetchHistory()]);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check-out presensi pulang (POST /api/attendance/check-out)
  Future<bool> checkOut(String uid, {String? note}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todayAttendance = await _attendanceApi.checkOut(note: note);

      // Refresh data statistik dan riwayat terbaru
      await Future.wait([_fetchMonthlyStats(), _fetchHistory()]);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Pengajuan surat izin / cuti
  /// (Tandai: modul /api/requests belum di-mount di backend server.js)
  Future<bool> submitRequest(RequestModel request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Endpoint /api/requests belum tersedia di backend Node.js
      throw Exception(
        'Fitur pengajuan surat belum didukung oleh backend REST API.',
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
