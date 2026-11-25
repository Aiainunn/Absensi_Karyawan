import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api/api_client.dart';
import '../services/api/auth_api_service.dart';
import '../services/token_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiService _authApi = AuthApiService();
  final TokenStorageService _tokenStorage = TokenStorageService();

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

  /// Inisialisasi status sesi saat aplikasi pertama kali dibuka.
  /// Memeriksa apakah token JWT tersedia dan memvalidasi ke endpoint GET /api/auth/me.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasToken = await _tokenStorage.hasToken();
      if (hasToken) {
        // Ambil cache lokal terlebih dahulu agar UI segera tampil tanpa flicker
        final cachedUser = await _tokenStorage.getUserCache();
        if (cachedUser != null) {
          _currentUser = UserModel.fromJson(cachedUser);
          notifyListeners();
        }

        // Verifikasi dan sinkronkan data profil terbaru dari server
        _currentUser = await _authApi.getMe();
      }
    } catch (e) {
      // Jika token sudah kedaluwarsa atau server menolak (401), bersihkan sesi
      if (e is ApiException && e.statusCode == 401) {
        await _tokenStorage.clearAll();
        _currentUser = null;
      }
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registrasi karyawan baru via POST /api/auth/register.
  /// Setelah berhasil, otomatis melakukan login agar pengguna langsung masuk ke aplikasi.
  Future<bool> register({
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
      await _authApi.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        position: position,
        department: department,
      );

      // Auto-login setelah registrasi berhasil
      _currentUser = await _authApi.login(
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

  /// Login via POST /api/auth/login.
  /// Menerima role karyawan ('employee') maupun 'admin'.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authApi.login(
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

  /// Logout via TokenStorageService.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authApi.logout();
    _currentUser = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Memperbarui data profil pengguna via PUT /api/auth/me.
  Future<bool> updateProfile(UserModel updatedUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authApi.updateMe(
        name: updatedUser.name,
        phone: updatedUser.phone,
        position: updatedUser.position,
        department: updatedUser.department,
      );
      _currentUser = user;
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

  /// Refresh data profil pengguna dari backend.
  Future<void> refreshUser() async {
    if (await _tokenStorage.hasToken()) {
      try {
        _currentUser = await _authApi.getMe();
        notifyListeners();
      } catch (e) {
        _error = e.toString();
      }
    }
  }

  /// Toggle dark mode
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Demo / Offline Mode Login (Fallback jika backend belum dinyalakan)
  void loginAsDemoEmployee() {
    _currentUser = UserModel(
      uid: 'demo-employee-1',
      name: 'Budi Santoso',
      email: 'budi.santoso@company.com',
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
      uid: 'demo-admin-1',
      name: 'Admin HRD Utama',
      email: 'admin.hrd@company.com',
      phone: '089876543210',
      position: 'Human Resource Manager',
      department: 'HRD & Personalia',
      role: 'admin',
      joinDate: DateTime.now().subtract(const Duration(days: 365)),
    );
    _error = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    // Reset password saat ini belum didukung endpoint REST API khusus
    _error = 'Fitur reset password belum didukung oleh REST API backend.';
    notifyListeners();
    return false;
  }
}
