import 'dart:async';
import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/schedule_model.dart';
import '../models/request_model.dart';
import '../services/firestore_service.dart';
import '../services/biometric_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final BiometricService _biometricService = BiometricService();

  String? _currentUid;
  AttendanceModel? _todayAttendance;
  List<AttendanceModel> _history = [];
  List<ScheduleModel> _schedules = [];
  List<RequestModel> _requests = [];
  Map<String, int> _monthlyStats = {};
  bool _isLoading = false;
  String? _error;
  bool _isBiometricAvailable = false;

  StreamSubscription? _historySubscription;
  StreamSubscription? _scheduleSubscription;
  StreamSubscription? _requestSubscription;

  bool _matchesUser(String? attUid, String? targetUid) {
    if (attUid == null || targetUid == null) return false;
    if (attUid == targetUid) return true;
    if ((targetUid == 'karyawan_default_id' && attUid == 'demo-employee-1') ||
        (targetUid == 'demo-employee-1' && attUid == 'karyawan_default_id') ||
        (targetUid == 'admin_default_id' && attUid == 'demo-admin-1') ||
        (targetUid == 'demo-admin-1' && attUid == 'admin_default_id')) {
      return true;
    }
    return false;
  }

  String? get currentUid => _currentUid;
  AttendanceModel? get todayAttendance =>
      (_currentUid != null && _matchesUser(_todayAttendance?.uid, _currentUid))
          ? _todayAttendance
          : null;
  List<AttendanceModel> get history => _history;
  List<ScheduleModel> get schedules => _schedules;
  List<RequestModel> get requests => _requests;
  Map<String, int> get monthlyStats => _monthlyStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isBiometricAvailable => _isBiometricAvailable;
  bool get hasCheckedIn => todayAttendance?.checkIn != null;
  bool get hasCheckedOut => todayAttendance?.checkOut != null;

  // Reset provider state when user logs out or switches
  void reset() {
    _currentUid = null;
    _todayAttendance = null;
    _history = [];
    _schedules = [];
    _requests = [];
    _monthlyStats = {};
    _isLoading = false;
    _error = null;
    _historySubscription?.cancel();
    _historySubscription = null;
    _scheduleSubscription?.cancel();
    _scheduleSubscription = null;
    _requestSubscription?.cancel();
    _requestSubscription = null;
    notifyListeners();
  }

  // Initialize
  Future<void> initialize(String uid) async {
    _currentUid = uid;

    // Cancel old subscriptions
    await _historySubscription?.cancel();
    await _scheduleSubscription?.cancel();
    await _requestSubscription?.cancel();

    // 1. Ambil data lokal seketika (0ms) agar UI langsung sinkron tanpa jeda network
    final localToday = _firestoreService.getLocalTodayAttendance(uid);
    final localHistory = _firestoreService.getLocalAttendanceHistory(uid);
    final localStats = _firestoreService.getLocalMonthlyStats(uid);

    _todayAttendance = localToday;
    _history = localHistory;
    _monthlyStats = localStats;
    _error = null;
    _isLoading = false;
    notifyListeners();

    // 2. Setup listener stream & sinkronisasi
    try {
      _isBiometricAvailable = await _biometricService.isBiometricAvailable();

      // Listen to attendance history
      _historySubscription =
          _firestoreService.getAttendanceHistory(uid).listen((data) {
        if (_currentUid == uid) {
          _history = data;
          notifyListeners();
        }
      });

      // Listen to schedules
      _scheduleSubscription =
          _firestoreService.getSchedules(uid).listen((data) {
        if (_currentUid == uid) {
          _schedules = data;
          notifyListeners();
        }
      });

      // Listen to requests
      _requestSubscription =
          _firestoreService.getUserRequests(uid).listen((data) {
        if (_currentUid == uid) {
          _requests = data;
          notifyListeners();
        }
      });
    } catch (e) {
      if (_currentUid == uid) {
        _error = e.toString();
      }
    }
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
      _currentUid = uid;
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
      _currentUid = uid;
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
      _currentUid = uid;
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

  @override
  void dispose() {
    _historySubscription?.cancel();
    _scheduleSubscription?.cancel();
    _requestSubscription?.cancel();
    super.dispose();
  }
}
