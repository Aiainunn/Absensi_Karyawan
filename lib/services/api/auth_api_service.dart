import '../../config/api_constants.dart';
import '../../models/user_model.dart';
import '../token_storage_service.dart';
import 'api_client.dart';

/// Service untuk menangani seluruh endpoint autentikasi dan profil pengguna.
///
/// Endpoint backend:
/// - POST /api/auth/register
/// - POST /api/auth/login
/// - GET  /api/auth/me
/// - PUT  /api/auth/me
class AuthApiService {
  static final AuthApiService _instance = AuthApiService._internal();
  factory AuthApiService() => _instance;
  AuthApiService._internal();

  final ApiClient _api = ApiClient();
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// Registrasi karyawan baru ke MySQL via backend REST API.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String position = '',
    String department = '',
  }) async {
    final body = {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      if (phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (position.trim().isNotEmpty) 'position': position.trim(),
      if (department.trim().isNotEmpty) 'department': department.trim(),
    };

    final response = await _api.post(
      ApiConstants.endpointRegister,
      body: body,
      requiresAuth: false,
    );

    final data = response['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  /// Login pengguna (Multi-role: Karyawan & Admin).
  /// Menyimpan token JWT ke [TokenStorageService] secara otomatis.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final body = {
      'email': email.trim().toLowerCase(),
      'password': password,
    };

    final response = await _api.post(
      ApiConstants.endpointLogin,
      body: body,
      requiresAuth: false,
    );

    final data = response['data'] as Map<String, dynamic>;
    final token = data['token']?.toString() ?? '';
    final userMap = data['user'] as Map<String, dynamic>;

    if (token.isNotEmpty) {
      await _tokenStorage.saveToken(token);
    }
    await _tokenStorage.saveUserCache(userMap);

    return UserModel.fromJson(userMap);
  }

  /// Mengambil profil pengguna terautentikasi (berdasarkan JWT token).
  Future<UserModel> getMe() async {
    final response = await _api.get(
      ApiConstants.endpointMe,
      requiresAuth: true,
    );

    final data = response['data'] as Map<String, dynamic>;
    await _tokenStorage.saveUserCache(data);
    return UserModel.fromJson(data);
  }

  /// Memperbarui informasi profil pengguna (name, phone, position, department).
  Future<UserModel> updateMe({
    required String name,
    String phone = '',
    String position = '',
    String department = '',
  }) async {
    final body = {
      'name': name.trim(),
      'phone': phone.trim(),
      'position': position.trim(),
      'department': department.trim(),
    };

    await _api.put(
      ApiConstants.endpointMe,
      body: body,
      requiresAuth: true,
    );

    // Ambil data profil terbaru setelah berhasil diupdate
    return await getMe();
  }

  /// Logout pengguna dan menghapus sesi token JWT.
  Future<void> logout() async {
    await _tokenStorage.clearAll();
  }
}

