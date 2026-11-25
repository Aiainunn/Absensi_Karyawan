import '../../config/api_constants.dart';
import '../../models/attendance_model.dart';
import '../../models/schedule_model.dart';
import 'api_client.dart';

/// Service untuk menangani modul presensi karyawan dan jadwal kerja via REST API.
///
/// Endpoint backend:
/// - POST /api/attendance/check-in
/// - POST /api/attendance/check-out
/// - GET  /api/attendance/today
/// - GET  /api/attendance/history
/// - GET  /api/attendance/monthly-stats
/// - GET  /api/schedules
class AttendanceApiService {
  static final AttendanceApiService _instance =
      AttendanceApiService._internal();
  factory AttendanceApiService() => _instance;
  AttendanceApiService._internal();

  final ApiClient _api = ApiClient();

  /// Check-in presensi masuk karyawan.
  ///
  /// [method] : 'camera' atau 'fingerprint'
  /// [photoUrl] : String base64 (wajib jika method adalah 'camera')
  Future<AttendanceModel> checkIn({
    required String method,
    String? photoUrl,
  }) async {
    final body = <String, dynamic>{
      'method': method,
      if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
    };

    final response = await _api.post(
      ApiConstants.endpointCheckIn,
      body: body,
      requiresAuth: true,
    );

    final data = response['data'] as Map<String, dynamic>;
    return AttendanceModel.fromJson(data);
  }

  /// Check-out presensi pulang karyawan.
  ///
  /// [note] : Catatan pekerjaan opsional.
  Future<AttendanceModel> checkOut({String? note}) async {
    final body = <String, dynamic>{
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };

    final response = await _api.post(
      ApiConstants.endpointCheckOut,
      body: body,
      requiresAuth: true,
    );

    final data = response['data'] as Map<String, dynamic>;
    return AttendanceModel.fromJson(data);
  }

  /// Mengambil data status absensi hari ini milik karyawan yang login.
  /// Mengembalikan `null` jika karyawan belum melakukan absensi hari ini.
  Future<AttendanceModel?> getTodayAttendance() async {
    final response = await _api.get(
      ApiConstants.endpointTodayAttendance,
      requiresAuth: true,
    );

    final data = response['data'];
    if (data == null || data is! Map<String, dynamic>) {
      return null;
    }

    return AttendanceModel.fromJson(data);
  }

  /// Mengambil riwayat absensi karyawan.
  ///
  /// [limit] : Jumlah maksimal data (default 30, maksimal 100).
  Future<List<AttendanceModel>> getHistory({int limit = 30}) async {
    final response = await _api.get(
      ApiConstants.endpointAttendanceHistory,
      queryParams: {'limit': limit},
      requiresAuth: true,
    );

    final list = response['data'];
    if (list is List) {
      return list
          .map((item) => AttendanceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Mengambil data statistik absensi bulanan.
  ///
  /// [month] : 1 - 12 (default: bulan saat ini).
  /// [year]  : 2000 - 2100 (default: tahun saat ini).
  Future<Map<String, dynamic>> getMonthlyStats({int? month, int? year}) async {
    final query = <String, dynamic>{};
    if (month != null) query['month'] = month;
    if (year != null) query['year'] = year;

    final response = await _api.get(
      ApiConstants.endpointMonthlyStats,
      queryParams: query.isNotEmpty ? query : null,
      requiresAuth: true,
    );

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return {};
  }

  /// Mengambil daftar jadwal kerja mingguan dari tabel schedules.
  Future<List<ScheduleModel>> getSchedules() async {
    final response = await _api.get(
      ApiConstants.endpointSchedules,
      requiresAuth: true,
    );

    final list = response['data'];
    if (list is List) {
      return list
          .map((item) => ScheduleModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }
}

