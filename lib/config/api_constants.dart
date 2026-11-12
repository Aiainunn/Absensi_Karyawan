import 'package:flutter/foundation.dart';

/// Pilihan environment koneksi backend API.
enum ApiEnvironment {
  /// Android Emulator (mengakses host localhost via 10.0.2.2)
  emulator,

  /// Browser Web atau Desktop Windows (localhost:3000)
  localhost,

  /// Perangkat Android fisik melalui jaringan Wi-Fi LAN
  lan,

  /// Server Production (AWS EC2 / Nginx Reverse Proxy)
  production,
}

/// Konfigurasi terpusat untuk komunikasi dengan backend REST API Node.js + Express.
///
/// Port backend: 3000
/// Prefix route: /api
class ApiConstants {
  ApiConstants._();

  // ===========================================================================
  // 1. PENGATURAN ENVIRONMENT & BASE URL
  // ===========================================================================

  /// Ganti IP ini sesuai alamat IPv4 Wi-Fi laptop/komputer Anda
  /// ketika menguji aplikasi pada HP Android fisik yang terhubung satu Wi-Fi.
  /// (Dapat dilihat via `ipconfig` di Command Prompt / PowerShell Windows).
  static String lanIp = '192.168.1.10';

  /// Port backend Node.js
  static const int port = 3000;

  /// URL untuk deployment server production (AWS EC2 / Nginx Load Balancer).
  /// Contoh: 'http://54.255.xxx.xxx/api' atau 'https://api-absensi.company.com/api'
  static String productionBaseUrl = '';

  /// Mode environment aktif.
  /// Secara default, sistem mendeteksi platform secara otomatis (Web, Android, Desktop).
  static ApiEnvironment activeEnvironment = _detectDefaultEnvironment();

  /// URL kustom jika pengembang ingin meng-override secara langsung saat runtime.
  static String? _customBaseUrl;

  /// Mendeteksi environment default yang paling cocok berdasarkan platform yang sedang berjalan.
  static ApiEnvironment _detectDefaultEnvironment() {
    if (kIsWeb) {
      return ApiEnvironment.localhost;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Default untuk development Android Emulator
        return ApiEnvironment.emulator;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return ApiEnvironment.localhost;
      case TargetPlatform.iOS:
        return ApiEnvironment.localhost;
      default:
        return ApiEnvironment.localhost;
    }
  }

  /// Mengatur environment secara manual (misal saat beralih ke HP fisik atau AWS).
  static void setEnvironment(ApiEnvironment env) {
    activeEnvironment = env;
    _customBaseUrl = null;
  }

  /// Mengatur base URL kustom secara langsung (berguna untuk testing atau input dinamis).
  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Mendapatkan Base URL aktif lengkap dengan prefix `/api`.
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    switch (activeEnvironment) {
      case ApiEnvironment.emulator:
        return 'http://10.0.2.2:$port/api';
      case ApiEnvironment.localhost:
        return 'http://localhost:$port/api';
      case ApiEnvironment.lan:
        return 'http://$lanIp:$port/api';
      case ApiEnvironment.production:
        return productionBaseUrl;
    }
  }

  // ===========================================================================
  // 2. TIMEOUT & KONEKSI
  // ===========================================================================

  /// Durasi batas waktu (timeout) HTTP request
  static const Duration timeoutDuration = Duration(seconds: 15);

  // ===========================================================================
  // 3. DAFTAR ENDPOINT BACKEND (NODE.JS + EXPRESS)
  // ===========================================================================

  // Modul Health Check (Load Balancing & Status Server)
  static const String endpointHealth = '/health';

  // Modul Autentikasi (/api/auth)
  static const String endpointRegister = '/auth/register';
  static const String endpointLogin = '/auth/login';
  static const String endpointMe = '/auth/me';

  // Modul Presensi Karyawan (/api/attendance)
  static const String endpointCheckIn = '/attendance/check-in';
  static const String endpointCheckOut = '/attendance/check-out';
  static const String endpointTodayAttendance = '/attendance/today';
  static const String endpointAttendanceHistory = '/attendance/history';
  static const String endpointMonthlyStats = '/attendance/monthly-stats';

  // Modul Jadwal Kerja (/api/schedules)
  static const String endpointSchedules = '/schedules';

  // ===========================================================================
  // 4. HEADER STANDAR & HELPER
  // ===========================================================================

  /// Header default tanpa token (untuk publik: login, register, health)
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Header terproteksi menyertakan JWT Bearer Token
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Nama header respons indikator load balancing dari backend Nginx/AWS
  static const String headerBackendServer = 'x-backend-server';
  static const String headerServerPort = 'x-server-port';
}
