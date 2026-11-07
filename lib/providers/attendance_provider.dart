import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/schedule_model.dart';
import '../models/request_model.dart';
import '../services/firestore_service.dart';
import '../services/biometric_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final BiometricService _biometricService = BiometricService();

  AttendanceModel? _todayAttendance;
  List<AttendanceModel> _history = [];
  List<ScheduleModel> _schedules = [];
  List<RequestModel> _requests = [];
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

  // Initialize
  Future<void> initialize(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _isBiometricAvailable = await _biometricService.isBiometricAvailable();
      _todayAttendance = await _firestoreService.getTodayAttendance(uid);
      _monthlyStats = await _firestoreService.getMonthlyStats(uid);

      // Listen to attendance history
      _firestoreService.getAttendanceHistory(uid).listen((data) {
        _history = data;
        notifyListeners();
      });

      // Listen to schedules
      _firestoreService.getSchedules(uid).listen((data) {
        _schedules = data;
        notifyListeners();
      });

      // Listen to requests
      _firestoreService.getUserRequests(uid).listen((data) {
        _requests = data;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Check in with camera
  Future<bool> checkInWithCamera({
    required String uid,
    required String userName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final scheduleStart = _getScheduleStart();
      await _firestoreService.checkIn(
        uid: uid,
        userName: userName,
        method: 'camera',
        scheduleStart: scheduleStart,
      );
      _todayAttendance = await _firestoreService.getTodayAttendance(uid);
      _monthlyStats = await _firestoreService.getMonthlyStats(uid);
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

  // Check in with fingerprint
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
        _error = 'Verifikasi sidik jari gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final scheduleStart = _getScheduleStart();
      await _firestoreService.checkIn(
        uid: uid,
        userName: userName,
        method: 'fingerprint',
        scheduleStart: scheduleStart,
      );
      _todayAttendance = await _firestoreService.getTodayAttendance(uid);
      _monthlyStats = await _firestoreService.getMonthlyStats(uid);
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

  // Check out
  Future<bool> checkOut(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.checkOut(uid);
      _todayAttendance = await _firestoreService.getTodayAttendance(uid);
      _monthlyStats = await _firestoreService.getMonthlyStats(uid);
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

  // Submit request
  Future<bool> submitRequest(RequestModel request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.submitRequest(request);
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

  // Get today's schedule start time
  String _getScheduleStart() {
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
    final today = dayNames[now.weekday - 1];

    for (final schedule in _schedules) {
      if (schedule.dayOfWeek.toLowerCase() == today && schedule.isActive) {
        return schedule.startTime;
      }
    }
    return '08:00';
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
