import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isDarkMode = true;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDarkMode => _isDarkMode;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isEmployee => _currentUser?.role == 'employee';

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _isLoading = true;
      notifyListeners();

      try {
        _currentUser = await _authService.getUserData(firebaseUser.uid);
      } catch (e) {
        _error = e.toString();
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tambah data karyawan baru oleh Admin tanpa pernah mengubah sesi login Admin
  Future<bool> registerEmployeeByAdmin({
    required String email,
    required String password,
    required String name,
    String phone = '',
    String position = '',
    String department = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newUser = await _authService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        position: position,
        department: department,
      );

      // Sesi login Admin tetap dipertahankan utuh
      _isLoading = false;
      notifyListeners();
      return newUser != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String phone = '',
    String position = '',
    String department = '',
    bool autoLogin = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newUser = await _authService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        position: position,
        department: department,
      );
      // Hanya autoLogin jika bukan sesi Admin
      if (autoLogin && !isAdmin) {
        _currentUser = newUser;
      }
      _isLoading = false;
      notifyListeners();
      return newUser != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // Update profile
  Future<bool> updateProfile(UserModel updatedUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
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

  // Refresh user data
  Future<void> refreshUser() async {
    if (_currentUser != null) {
      try {
        _currentUser = await _authService.getUserData(_currentUser!.uid);
        notifyListeners();
      } catch (e) {
        _error = e.toString();
      }
    }
  }

  // Toggle dark mode
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Demo / Offline Mode Login for testing without active Firebase project
  void loginAsDemoEmployee() {
    _currentUser = UserModel(
      uid: 'karyawan_default_id',
      name: 'Budi Santoso',
      email: 'budi@company.com',
      phone: '081234567890',
      position: 'Staff IT & Operasional',
      department: 'Teknologi Informasi',
      role: 'employee',
      joinDate: DateTime.now().subtract(const Duration(days: 120)),
    );
    _error = null;
    notifyListeners();
  }

  void loginAsDemoAdmin() {
    _currentUser = UserModel(
      uid: 'admin_default_id',
      name: 'Admin HRD Utama',
      email: 'admin@company.com',
      phone: '089876543210',
      position: 'Human Resource Manager',
      department: 'HRD & Personalia',
      role: 'admin',
      joinDate: DateTime.now().subtract(const Duration(days: 365)),
    );
    _error = null;
    notifyListeners();
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
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
}
