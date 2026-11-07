import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/request_model.dart';
import '../services/firestore_service.dart';

class AdminProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<UserModel> _employees = [];
  List<AttendanceModel> _attendances = [];
  List<RequestModel> _requests = [];
  int _totalEmployees = 0;
  Map<String, int> _todayStats = {};
  int _pendingRequests = 0;
  bool _isLoading = false;
  String? _error;

  List<UserModel> get employees => _employees;
  List<AttendanceModel> get attendances => _attendances;
  List<RequestModel> get requests => _requests;
  int get totalEmployees => _totalEmployees;
  Map<String, int> get todayStats => _todayStats;
  int get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize admin data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _totalEmployees = await _firestoreService.getEmployeeCount();
      _todayStats = await _firestoreService.getTodayAttendanceStats();
      _pendingRequests = await _firestoreService.getPendingRequestCount();

      // Initialize default schedules
      await _firestoreService.setDefaultSchedules();

      // Listen to employees
      _firestoreService.getAllEmployees().listen((data) {
        _employees = data;
        _totalEmployees = data.length;
        notifyListeners();
      });

      // Listen to all attendances
      _firestoreService.getAllAttendances().listen((data) {
        _attendances = data;
        notifyListeners();
      });

      // Listen to all requests
      _firestoreService.getAllRequests().listen((data) {
        _requests = data;
        _pendingRequests =
            data.where((r) => r.status == 'pending').length;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Refresh dashboard stats
  Future<void> refreshStats() async {
    try {
      _totalEmployees = await _firestoreService.getEmployeeCount();
      _todayStats = await _firestoreService.getTodayAttendanceStats();
      _pendingRequests = await _firestoreService.getPendingRequestCount();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  // Toggle employee status
  Future<bool> toggleEmployeeStatus(String uid, bool isActive) async {
    try {
      await _firestoreService.toggleEmployeeStatus(uid, isActive);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update employee
  Future<bool> updateEmployee(
      String uid, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updateEmployee(uid, data);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete employee
  Future<bool> deleteEmployee(String uid) async {
    try {
      await _firestoreService.deleteEmployee(uid);
      return true;
    } catch (e) {
      _error = e.toString();
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
      await _firestoreService.updateRequestStatus(
        docId,
        status: status,
        adminNote: adminNote,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get attendances filtered by date
  List<AttendanceModel> getAttendancesByDate(String date) {
    return _attendances.where((a) => a.date == date).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
