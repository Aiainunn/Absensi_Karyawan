import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_model.dart';
import '../models/request_model.dart';
import '../models/schedule_model.dart';
import '../models/user_model.dart';

/// Database lokal mandiri yang berjalan langsung di memori dan storage HP (Android & iOS).
/// Tidak memerlukan server database eksternal seperti Laragon, MySQL, atau phpMyAdmin.
/// Data tersimpan secara persisten menggunakan SharedPreferences (JSON).
class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  static const String _kUsers = 'local_db_users';
  static const String _kPasswords = 'local_db_passwords';
  static const String _kAttendances = 'local_db_attendances';
  static const String _kSchedules = 'local_db_schedules';
  static const String _kRequests = 'local_db_requests';

  SharedPreferences? _prefs;

  // Stream controllers untuk update data real-time ke UI
  final _attendanceStream =
      StreamController<List<AttendanceModel>>.broadcast();
  final _requestStream = StreamController<List<RequestModel>>.broadcast();
  final _employeeStream = StreamController<List<UserModel>>.broadcast();
  final _scheduleStream = StreamController<List<ScheduleModel>>.broadcast();

  Stream<List<AttendanceModel>> get attendanceStream =>
      _attendanceStream.stream;
  Stream<List<RequestModel>> get requestStream => _requestStream.stream;
  Stream<List<UserModel>> get employeeStream => _employeeStream.stream;
  Stream<List<ScheduleModel>> get scheduleStream => _scheduleStream.stream;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _seedInitialDataIfEmpty();
    _broadcastAll();
  }

  void _broadcastAll() {
    _attendanceStream.add(getAllAttendances());
    _requestStream.add(getAllRequests());
    _employeeStream.add(getAllEmployees());
    _scheduleStream.add(getAllSchedules());
  }

  // ── SEED INITIAL DATA ──
  Future<void> _seedInitialDataIfEmpty() async {
    final users = _getList(_kUsers);
    if (users.isEmpty) {
      // 1. Akun Admin Default
      final adminUser = UserModel(
        uid: 'admin_default_id',
        name: 'Admin HRD Utama',
        email: 'admin@company.com',
        phone: '081299887766',
        position: 'HR Manager',
        department: 'HRD & Personalia',
        role: 'admin',
        joinDate: DateTime.now().subtract(const Duration(days: 365)),
      );

      // 2. Akun Karyawan Default
      final employeeUser = UserModel(
        uid: 'karyawan_default_id',
        name: 'Budi Santoso',
        email: 'budi@company.com',
        phone: '081234567890',
        position: 'Staff IT & Operasional',
        department: 'Teknologi Informasi',
        role: 'employee',
        joinDate: DateTime.now().subtract(const Duration(days: 120)),
      );

      await saveUser(adminUser, password: 'admin123');
      await saveUser(employeeUser, password: '123456');

      // 3. Default Jadwal Kerja
      final defaultSchedules = [
        ScheduleModel(
            id: 'sch_mon',
            dayOfWeek: 'monday',
            startTime: '08:00',
            endTime: '17:00'),
        ScheduleModel(
            id: 'sch_tue',
            dayOfWeek: 'tuesday',
            startTime: '08:00',
            endTime: '17:00'),
        ScheduleModel(
            id: 'sch_wed',
            dayOfWeek: 'wednesday',
            startTime: '08:00',
            endTime: '17:00'),
        ScheduleModel(
            id: 'sch_thu',
            dayOfWeek: 'thursday',
            startTime: '08:00',
            endTime: '17:00'),
        ScheduleModel(
            id: 'sch_fri',
            dayOfWeek: 'friday',
            startTime: '08:00',
            endTime: '17:00'),
        ScheduleModel(
            id: 'sch_sat',
            dayOfWeek: 'saturday',
            startTime: '--:--',
            endTime: '--:--',
            isActive: false),
        ScheduleModel(
            id: 'sch_sun',
            dayOfWeek: 'sunday',
            startTime: '--:--',
            endTime: '--:--',
            isActive: false),
      ];

      for (final s in defaultSchedules) {
        await saveSchedule(s);
      }
    }
  }

  // ── USER & AUTH ──
  Future<void> saveUser(UserModel user, {String password = '123456'}) async {
    final list = _getList(_kUsers);
    list.removeWhere((item) => item['uid'] == user.uid);
    list.add({
      'uid': user.uid,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'position': user.position,
      'department': user.department,
      'role': user.role,
      'photoUrl': user.photoUrl,
      'joinDate': user.joinDate.toIso8601String(),
      'isActive': user.isActive,
      'createdAt': user.createdAt.toIso8601String(),
    });
    await _saveList(_kUsers, list);

    // Simpan password
    final passwords = _getMap(_kPasswords);
    passwords[user.email.toLowerCase()] = password;
    await _saveMap(_kPasswords, passwords);

    _employeeStream.add(getAllEmployees());
  }

  UserModel? login(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    final passwords = _getMap(_kPasswords);

    if (passwords[cleanEmail] != password) {
      return null;
    }

    final list = _getList(_kUsers);
    final userMap = list.firstWhere(
      (u) => (u['email'] as String).toLowerCase() == cleanEmail,
      orElse: () => <String, dynamic>{},
    );

    if (userMap.isEmpty) return null;
    return _mapToUser(userMap);
  }

  UserModel? getUser(String uid) {
    final list = _getList(_kUsers);
    final userMap = list.firstWhere(
      (u) => u['uid'] == uid,
      orElse: () => <String, dynamic>{},
    );
    if (userMap.isEmpty) return null;
    return _mapToUser(userMap);
  }

  bool isEmailRegistered(String email) {
    final cleanEmail = email.trim().toLowerCase();
    final list = _getList(_kUsers);
    return list.any((u) => (u['email'] as String).toLowerCase() == cleanEmail);
  }

  List<UserModel> getAllEmployees() {
    final list = _getList(_kUsers);
    return list
        .where((u) => u['role'] == 'employee')
        .map((u) => _mapToUser(u))
        .toList();
  }

  Future<void> toggleEmployeeStatus(String uid, bool isActive) async {
    final list = _getList(_kUsers);
    final idx = list.indexWhere((u) => u['uid'] == uid);
    if (idx != -1) {
      list[idx]['isActive'] = isActive;
      await _saveList(_kUsers, list);
      _employeeStream.add(getAllEmployees());
    }
  }

  Future<void> updateEmployee(String uid, Map<String, dynamic> data) async {
    final list = _getList(_kUsers);
    final idx = list.indexWhere((u) => u['uid'] == uid);
    if (idx != -1) {
      list[idx].addAll(data);
      await _saveList(_kUsers, list);
      _employeeStream.add(getAllEmployees());
    }
  }

  Future<void> deleteEmployee(String uid) async {
    final list = _getList(_kUsers);
    list.removeWhere((u) => u['uid'] == uid);
    await _saveList(_kUsers, list);
    _employeeStream.add(getAllEmployees());
  }

  // ── ATTENDANCE ──
  Future<AttendanceModel> checkIn({
    required String uid,
    required String userName,
    required String method,
    required String scheduleStart,
  }) async {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final list = _getList(_kAttendances);

    // Cek apakah sudah absen masuk hari ini
    final exists = list.any((a) => a['uid'] == uid && a['date'] == date);
    if (exists) {
      throw Exception('Anda sudah absen masuk hari ini');
    }

    String status = 'present';
    if (scheduleStart.isNotEmpty && scheduleStart != '--:--') {
      final parts = scheduleStart.split(':');
      if (parts.length == 2) {
        final scheduleHour = int.tryParse(parts[0]) ?? 8;
        final scheduleMinute = int.tryParse(parts[1]) ?? 0;
        if (now.hour > scheduleHour ||
            (now.hour == scheduleHour && now.minute > scheduleMinute)) {
          status = 'late';
        }
      }
    }

    final id = 'att_${DateTime.now().millisecondsSinceEpoch}';
    final attMap = {
      'id': id,
      'uid': uid,
      'userName': userName,
      'date': date,
      'checkIn': now.toIso8601String(),
      'checkOut': null,
      'method': method,
      'status': status,
      'workHours': 0.0,
      'note': '',
    };

    list.insert(0, attMap);
    await _saveList(_kAttendances, list);
    _attendanceStream.add(getAllAttendances());

    return _mapToAttendance(attMap);
  }

  Future<void> checkOut(String uid) async {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final list = _getList(_kAttendances);
    final idx = list.indexWhere((a) => a['uid'] == uid && a['date'] == date);

    if (idx == -1) {
      throw Exception('Anda belum absen masuk hari ini');
    }

    final checkInTime = DateTime.parse(list[idx]['checkIn']);
    final workHours = now.difference(checkInTime).inMinutes / 60.0;

    list[idx]['checkOut'] = now.toIso8601String();
    list[idx]['workHours'] = double.parse(workHours.toStringAsFixed(2));

    await _saveList(_kAttendances, list);
    _attendanceStream.add(getAllAttendances());
  }

  AttendanceModel? getTodayAttendance(String uid) {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final list = _getList(_kAttendances);
    final att = list.firstWhere(
      (a) => a['uid'] == uid && a['date'] == date,
      orElse: () => <String, dynamic>{},
    );
    if (att.isEmpty) return null;
    return _mapToAttendance(att);
  }

  List<AttendanceModel> getUserAttendanceHistory(String uid) {
    final list = _getList(_kAttendances);
    return list
        .where((a) => a['uid'] == uid)
        .map((a) => _mapToAttendance(a))
        .toList();
  }

  List<AttendanceModel> getAllAttendances({String? date}) {
    final list = _getList(_kAttendances);
    var filtered = list;
    if (date != null) {
      filtered = list.where((a) => a['date'] == date).toList();
    }
    return filtered.map((a) => _mapToAttendance(a)).toList();
  }

  Map<String, int> getMonthlyStats(String uid) {
    final now = DateTime.now();
    final monthPrefix =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final list = _getList(_kAttendances)
        .where((a) => a['uid'] == uid && (a['date'] as String).startsWith(monthPrefix))
        .toList();

    int present = 0;
    int late = 0;
    int absent = 0;

    for (final a in list) {
      final status = a['status'];
      if (status == 'present') present++;
      if (status == 'late') late++;
      if (status == 'absent') absent++;
    }

    return {
      'present': present,
      'late': late,
      'absent': absent,
      'total': list.length,
    };
  }

  Map<String, int> getTodayStats() {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final list =
        _getList(_kAttendances).where((a) => a['date'] == date).toList();

    int present = 0;
    int late = 0;

    for (final a in list) {
      final status = a['status'];
      if (status == 'present') present++;
      if (status == 'late') late++;
    }

    return {
      'present': present,
      'late': late,
      'total': list.length,
    };
  }

  // ── SCHEDULES ──
  List<ScheduleModel> getAllSchedules() {
    final list = _getList(_kSchedules);
    return list.map((s) => _mapToSchedule(s)).toList();
  }

  Future<void> saveSchedule(ScheduleModel s) async {
    final list = _getList(_kSchedules);
    list.removeWhere((item) => item['dayOfWeek'] == s.dayOfWeek);
    list.add({
      'id': s.id.isNotEmpty ? s.id : 'sch_${s.dayOfWeek}',
      'uid': s.uid,
      'dayOfWeek': s.dayOfWeek,
      'startTime': s.startTime,
      'endTime': s.endTime,
      'isActive': s.isActive,
      'note': s.note,
    });
    await _saveList(_kSchedules, list);
    _scheduleStream.add(getAllSchedules());
  }

  Future<void> updateSchedule(String docId, ScheduleModel updated) async {
    final list = _getList(_kSchedules);
    final idx = list.indexWhere(
        (s) => s['id'] == docId || s['dayOfWeek'] == updated.dayOfWeek);
    if (idx != -1) {
      list[idx] = {
        'id': docId,
        'uid': updated.uid,
        'dayOfWeek': updated.dayOfWeek,
        'startTime': updated.startTime,
        'endTime': updated.endTime,
        'isActive': updated.isActive,
        'note': updated.note,
      };
    } else {
      list.add({
        'id': docId,
        'uid': updated.uid,
        'dayOfWeek': updated.dayOfWeek,
        'startTime': updated.startTime,
        'endTime': updated.endTime,
        'isActive': updated.isActive,
        'note': updated.note,
      });
    }
    await _saveList(_kSchedules, list);
    _scheduleStream.add(getAllSchedules());
  }

  // ── REQUESTS ──
  Future<void> submitRequest(RequestModel req) async {
    final list = _getList(_kRequests);
    final id = 'req_${DateTime.now().millisecondsSinceEpoch}';
    final map = {
      'id': id,
      'uid': req.uid,
      'userName': req.userName,
      'type': req.type,
      'reason': req.reason,
      'startDate': req.startDate.toIso8601String(),
      'endDate': req.endDate?.toIso8601String(),
      'status': req.status,
      'adminNote': req.adminNote,
      'createdAt': req.createdAt.toIso8601String(),
      'updatedAt': req.updatedAt?.toIso8601String(),
    };
    list.insert(0, map);
    await _saveList(_kRequests, list);
    _requestStream.add(getAllRequests());
  }

  List<RequestModel> getUserRequests(String uid) {
    final list = _getList(_kRequests);
    return list
        .where((r) => r['uid'] == uid)
        .map((r) => _mapToRequest(r))
        .toList();
  }

  List<RequestModel> getAllRequests({String? status}) {
    final list = _getList(_kRequests);
    var filtered = list;
    if (status != null) {
      filtered = list.where((r) => r['status'] == status).toList();
    }
    return filtered.map((r) => _mapToRequest(r)).toList();
  }

  Future<void> updateRequestStatus(
    String id, {
    required String status,
    String adminNote = '',
  }) async {
    final list = _getList(_kRequests);
    final idx = list.indexWhere((r) => r['id'] == id);
    if (idx != -1) {
      list[idx]['status'] = status;
      list[idx]['adminNote'] = adminNote;
      list[idx]['updatedAt'] = DateTime.now().toIso8601String();
      await _saveList(_kRequests, list);
      _requestStream.add(getAllRequests());
    }
  }

  // ── HELPER MAPPERS ──
  UserModel _mapToUser(Map<String, dynamic> m) {
    return UserModel(
      uid: m['uid'] ?? '',
      name: m['name'] ?? '',
      email: m['email'] ?? '',
      phone: m['phone'] ?? '',
      position: m['position'] ?? '',
      department: m['department'] ?? '',
      role: m['role'] ?? 'employee',
      photoUrl: m['photoUrl'] ?? '',
      joinDate: m['joinDate'] != null
          ? DateTime.parse(m['joinDate'])
          : DateTime.now(),
      isActive: m['isActive'] ?? true,
      createdAt: m['createdAt'] != null
          ? DateTime.parse(m['createdAt'])
          : DateTime.now(),
    );
  }

  AttendanceModel _mapToAttendance(Map<String, dynamic> m) {
    return AttendanceModel(
      id: m['id'] ?? '',
      uid: m['uid'] ?? '',
      userName: m['userName'] ?? '',
      date: m['date'] ?? '',
      checkIn: m['checkIn'] != null ? DateTime.parse(m['checkIn']) : null,
      checkOut: m['checkOut'] != null ? DateTime.parse(m['checkOut']) : null,
      method: m['method'] ?? 'camera',
      status: m['status'] ?? 'present',
      workHours: (m['workHours'] ?? 0).toDouble(),
      note: m['note'] ?? '',
    );
  }

  ScheduleModel _mapToSchedule(Map<String, dynamic> m) {
    return ScheduleModel(
      id: m['id'] ?? '',
      uid: m['uid'] ?? 'all',
      dayOfWeek: m['dayOfWeek'] ?? '',
      startTime: m['startTime'] ?? '08:00',
      endTime: m['endTime'] ?? '17:00',
      isActive: m['isActive'] ?? true,
      note: m['note'] ?? '',
    );
  }

  RequestModel _mapToRequest(Map<String, dynamic> m) {
    return RequestModel(
      id: m['id'] ?? '',
      uid: m['uid'] ?? '',
      userName: m['userName'] ?? '',
      type: m['type'] ?? '',
      reason: m['reason'] ?? '',
      startDate: m['startDate'] != null
          ? DateTime.parse(m['startDate'])
          : DateTime.now(),
      endDate:
          m['endDate'] != null ? DateTime.parse(m['endDate']) : null,
      status: m['status'] ?? 'pending',
      adminNote: m['adminNote'] ?? '',
      createdAt: m['createdAt'] != null
          ? DateTime.parse(m['createdAt'])
          : DateTime.now(),
      updatedAt: m['updatedAt'] != null
          ? DateTime.parse(m['updatedAt'])
          : null,
    );
  }

  List<Map<String, dynamic>> _getList(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveList(String key, List<Map<String, dynamic>> list) async {
    await _prefs?.setString(key, jsonEncode(list));
  }

  Map<String, String> _getMap(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveMap(String key, Map<String, String> map) async {
    await _prefs?.setString(key, jsonEncode(map));
  }
}
