import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola persistensi JWT (JSON Web Token) dan sesi pengguna.
///
/// ============================================================================
/// EVALUASI & ALASAN PEMILIHAN PENYIMPANAN TOKEN:
/// ============================================================================
/// 1. Pilihan Mekanisme: `shared_preferences` (Current Choice)
///    - Kelebihan:
///      * Kompatibel secara native dan stabil di semua platform target (Android,
///        iOS, Flutter Web, dan Desktop Windows).
///      * Paket sudah terinstal di project (`shared_preferences: ^2.5.5`).
///      * Sangat cepat dan tidak rentan terhadap kegagalan hardware keystore
///        (yang sering terjadi pada Android Emulator atau saat update OS).
///      * Pada Android, file tersimpan di direktori privat aplikasi
///        (`/data/data/<package_name>/shared_prefs/`) yang diisolasi oleh sandbox OS.
///    - Konsekuensi & Batasan:
///      * Data tersimpan dalam bentuk plaintext. Jika perangkat Android di-root
///        atau di-jailbreak, file dapat diakses oleh user dengan hak superuser.
///      * Pada browser Web, data tersimpan di localStorage (rentan jika ada celah XSS).
///
/// 2. Alternatif: `flutter_secure_storage`
///    - Menggunakan Android Keystore / EncryptedSharedPreferences dan iOS Keychain.
///    - Konsekuensi jika diterapkan sekarang:
///      * Memerlukan penambahan library baru di `pubspec.yaml`.
///      * Memerlukan penyesuaian `minSdkVersion` Android ke 18 atau 23.
///      * Sering memicu `KeyStoreException` atau corrupt key pada emulator Android 12+.
///      * Pada Flutter Web, tidak menyediakan hardware security module bawaan.
///
/// 3. Strategi Desain:
///    - `TokenStorageService` bertindak sebagai lapisan abstraksi (facade).
///    - Jika di masa mendatang dibutuhkan enkripsi hardware (misalnya untuk kepatuhan
///      keamanan perbankan), kita cukup mengganti implementasi internal di dalam file
///      ini tanpa perlu mengubah `AuthProvider`, `ApiClient`, atau halaman UI sama sekali.
/// ============================================================================
class TokenStorageService {
  static final TokenStorageService _instance = TokenStorageService._internal();
  factory TokenStorageService() => _instance;
  TokenStorageService._internal();

  // Storage Keys
  static const String _kAuthToken = 'auth_jwt_token';
  static const String _kUserCache = 'auth_user_cache';

  SharedPreferences? _prefs;

  /// Memastikan instance SharedPreferences telah terinisialisasi.
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ===========================================================================
  // TOKEN JWT MANAGEMENT
  // ===========================================================================

  /// Menyimpan JWT token yang didapat setelah login atau registrasi.
  Future<bool> saveToken(String token) async {
    final prefs = await _getPrefs();
    return await prefs.setString(_kAuthToken, token.trim());
  }

  /// Mengambil JWT token yang tersimpan. Mengembalikan `null` jika belum login.
  Future<String?> getToken() async {
    final prefs = await _getPrefs();
    final token = prefs.getString(_kAuthToken);
    if (token == null || token.trim().isEmpty) {
      return null;
    }
    return token.trim();
  }

  /// Memeriksa apakah token JWT tersedia di penyimpanan lokal.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Menghapus token JWT saat pengguna melakukan logout.
  Future<bool> clearToken() async {
    final prefs = await _getPrefs();
    return await prefs.remove(_kAuthToken);
  }

  // ===========================================================================
  // USER PROFILE CACHE MANAGEMENT
  // (Menyimpan ringkasan profil lokal agar UI tidak flicker saat startup)
  // ===========================================================================

  /// Menyimpan data profil pengguna ke cache lokal.
  Future<bool> saveUserCache(Map<String, dynamic> userMap) async {
    final prefs = await _getPrefs();
    final jsonString = jsonEncode(userMap);
    return await prefs.setString(_kUserCache, jsonString);
  }

  /// Mengambil data profil pengguna dari cache lokal.
  Future<Map<String, dynamic>?> getUserCache() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(_kUserCache);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Menghapus seluruh data sesi login (token dan user cache).
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(_kAuthToken);
    await prefs.remove(_kUserCache);
  }
}

