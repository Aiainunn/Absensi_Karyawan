import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_constants.dart';
import '../token_storage_service.dart';

/// Exception khusus untuk kesalahan komunikasi API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

/// HTTP Client terpusat untuk aplikasi Absensi Karyawan.
///
/// Bertanggung jawab atas:
/// 1. Mengarahkan request ke [ApiConstants.baseUrl].
/// 2. Menyisipkan JWT Bearer token secara otomatis via [TokenStorageService].
/// 3. Menangani JSON parsing & error status code (400, 401, 403, 409, 500).
/// 4. Menerapkan timeout request [ApiConstants.timeoutDuration].
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _httpClient = http.Client();
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// Membangun header request.
  Future<Map<String, String>> _buildHeaders({bool requiresAuth = true}) async {
    final headers = Map<String, String>.from(ApiConstants.defaultHeaders);

    if (requiresAuth) {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Membangun URI lengkap dengan query parameter.
  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final base = ApiConstants.baseUrl;
    final normalizedEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '$base$normalizedEndpoint';

    var uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      uri = uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  /// Memproses respons dari server.
  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        } else {
          body = {'data': decoded};
        }
      } catch (_) {
        body = {'raw': response.body};
      }
    }

    final statusCode = response.statusCode;
    if (statusCode >= 200 && statusCode < 300) {
      return body;
    }

    final message = body['message']?.toString() ??
        'Permintaan gagal dengan status $statusCode';

    throw ApiException(
      message,
      statusCode: statusCode,
      data: body,
    );
  }

  /// Eksekusi HTTP GET
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(ApiConstants.timeoutDuration);

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'Koneksi timeout ke server. Pastikan server backend sedang aktif.',
        statusCode: 408,
      );
    } catch (e) {
      throw ApiException(
        'Gagal terhubung ke server backend (${ApiConstants.baseUrl}). Detail: $e',
        statusCode: 503,
      );
    }
  }

  /// Eksekusi HTTP POST
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final payload = body != null ? jsonEncode(body) : null;

      final response = await _httpClient
          .post(uri, headers: headers, body: payload)
          .timeout(ApiConstants.timeoutDuration);

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'Koneksi timeout ke server. Pastikan server backend sedang aktif.',
        statusCode: 408,
      );
    } catch (e) {
      throw ApiException(
        'Gagal terhubung ke server backend (${ApiConstants.baseUrl}). Detail: $e',
        statusCode: 503,
      );
    }
  }

  /// Eksekusi HTTP PUT
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final payload = body != null ? jsonEncode(body) : null;

      final response = await _httpClient
          .put(uri, headers: headers, body: payload)
          .timeout(ApiConstants.timeoutDuration);

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'Koneksi timeout ke server. Pastikan server backend sedang aktif.',
        statusCode: 408,
      );
    } catch (e) {
      throw ApiException(
        'Gagal terhubung ke server backend (${ApiConstants.baseUrl}). Detail: $e',
        statusCode: 503,
      );
    }
  }

  /// Eksekusi HTTP DELETE
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _httpClient
          .delete(uri, headers: headers)
          .timeout(ApiConstants.timeoutDuration);

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'Koneksi timeout ke server. Pastikan server backend sedang aktif.',
        statusCode: 408,
      );
    } catch (e) {
      throw ApiException(
        'Gagal terhubung ke server backend (${ApiConstants.baseUrl}). Detail: $e',
        statusCode: 503,
      );
    }
  }
}

