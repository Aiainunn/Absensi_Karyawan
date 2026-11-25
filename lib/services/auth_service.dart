import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'api/auth_api_service.dart';
import 'local_db_service.dart';

/// Service adapter untuk autentikasi pengguna.
/// Menggunakan [AuthApiService] (Node.js REST API) sebagai backend utama,
/// dengan fallback ke Firebase/LocalDb jika diperlukan.
class AuthService {
  final AuthApiService _apiAuth = AuthApiService();
  final LocalDbService _localDb = LocalDbService();

  bool get isFirebaseAvailable => Firebase.apps.isNotEmpty;

  User? get currentUser {
    if (isFirebaseAvailable) {
      try {
        return FirebaseAuth.instance.currentUser;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Register new employee via REST API
  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    String phone = '',
    String position = '',
    String department = '',
  }) async {
    return await _apiAuth.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      position: position,
      department: department,
    );
  }

  // Login via REST API
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    return await _apiAuth.login(
      email: email,
      password: password,
    );
  }

  // Get user data via REST API
  Future<UserModel?> getUserData([String? uid]) async {
    try {
      return await _apiAuth.getMe();
    } catch (_) {
      if (uid != null) {
        return _localDb.getUser(uid);
      }
      return null;
    }
  }

  // Update user profile via REST API
  Future<void> updateUserProfile(UserModel user) async {
    await _apiAuth.updateMe(
      name: user.name,
      phone: user.phone,
      position: user.position,
      department: user.department,
    );
  }

  // Logout
  Future<void> logout() async {
    await _apiAuth.logout();
    if (isFirebaseAvailable) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    if (isFirebaseAvailable) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        return;
      } catch (_) {}
    }

    if (!_localDb.isEmailRegistered(email)) {
      throw Exception('Email tidak terdaftar');
    }
  }
}
