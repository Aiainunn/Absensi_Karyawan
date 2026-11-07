import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'local_db_service.dart';

class AuthService {
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

  Stream<User?> get authStateChanges {
    if (isFirebaseAvailable) {
      try {
        return FirebaseAuth.instance.authStateChanges();
      } catch (_) {
        return const Stream.empty();
      }
    }
    return const Stream.empty();
  }

  // Register new employee
  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    String phone = '',
    String position = '',
    String department = '',
  }) async {
    // 1. Coba via Firebase jika tersedia
    if (isFirebaseAvailable) {
      try {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (credential.user != null) {
          final userModel = UserModel(
            uid: credential.user!.uid,
            name: name,
            email: email,
            phone: phone,
            position: position,
            department: department,
            role: 'employee',
          );

          await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .set(userModel.toFirestore());

          // Sinkronkan juga ke database lokal HP
          await _localDb.saveUser(userModel, password: password);
          return userModel;
        }
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      } catch (_) {
        // Fallback ke local DB jika ada error konfigurasi Firebase
      }
    }

    // 2. Mode Mandiri (Local Database HP) - tanpa butuh server Laragon / MySQL
    if (_localDb.isEmailRegistered(email)) {
      throw Exception('Email sudah terdaftar di aplikasi');
    }

    final localUid = 'emp_${DateTime.now().millisecondsSinceEpoch}';
    final userModel = UserModel(
      uid: localUid,
      name: name,
      email: email,
      phone: phone,
      position: position,
      department: department,
      role: 'employee',
    );

    await _localDb.saveUser(userModel, password: password);
    return userModel;
  }

  // Login
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    // 1. Coba via Firebase jika tersedia
    if (isFirebaseAvailable) {
      try {
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (credential.user != null) {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .get();

          if (doc.exists) {
            final user = UserModel.fromFirestore(doc);
            await _localDb.saveUser(user, password: password);
            return user;
          }
        }
      } on FirebaseAuthException catch (e) {
        // Jika akun tidak ditemukan di Firebase, coba cek database lokal
        if (e.code != 'user-not-found' && e.code != 'invalid-credential') {
          throw _handleAuthException(e);
        }
      } catch (_) {
        // Lanjut ke pemeriksaan local DB
      }
    }

    // 2. Mode Mandiri (Local Database HP)
    final localUser = _localDb.login(email, password);
    if (localUser != null) {
      if (!localUser.isActive) {
        throw Exception('Akun telah dinonaktifkan oleh Administrator');
      }
      return localUser;
    }

    throw Exception('Email atau password salah');
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    if (isFirebaseAvailable) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists) {
          return UserModel.fromFirestore(doc);
        }
      } catch (_) {}
    }

    return _localDb.getUser(uid);
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    if (isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(user.toFirestore());
      } catch (_) {}
    }

    await _localDb.updateEmployee(user.uid, user.toFirestore());
  }

  // Logout
  Future<void> logout() async {
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
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      } catch (_) {}
    }

    if (!_localDb.isEmailRegistered(email)) {
      throw Exception('Email tidak terdaftar');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'weak-password':
        return 'Password terlalu lemah (min. 6 karakter)';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti';
      case 'invalid-credential':
        return 'Email atau password salah';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }
}
