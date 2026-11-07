import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';
import '../models/schedule_model.dart';
import '../models/request_model.dart';
import '../models/user_model.dart';
import 'local_db_service.dart';

class FirestoreService {
  final LocalDbService _localDb = LocalDbService();

  bool get isFirebaseAvailable => Firebase.apps.isNotEmpty;

  // ── ATTENDANCE ──

  // Check in
  Future<String> checkIn({
    required String uid,
    required String userName,
    required String method,
    required String scheduleStart,
  }) async {
    // 1. Simpan ke database lokal HP
    final localAtt = await _localDb.checkIn(
      uid: uid,
      userName: userName,
      method: method,
      scheduleStart: scheduleStart,
    );

    // 2. Simpan juga ke Firebase jika aktif
    if (isFirebaseAvailable) {
      try {
        final docRef = await FirebaseFirestore.instance
            .collection('attendances')
            .add(localAtt.toFirestore());
        return docRef.id;
      } catch (_) {}
    }

    return localAtt.id;
  }

  // Check out
  Future<void> checkOut(String uid) async {
    // 1. Update database lokal HP
    await _localDb.checkOut(uid);

    // 2. Update Firebase jika aktif
    if (isFirebaseAvailable) {
      try {
        final now = DateTime.now();
        final date =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        final existing = await FirebaseFirestore.instance
            .collection('attendances')
            .where('uid', isEqualTo: uid)
            .where('date', isEqualTo: date)
            .get();

        if (existing.docs.isNotEmpty) {
          final doc = existing.docs.first;
          final checkIn = (doc.data()['checkIn'] as Timestamp).toDate();
          final workHours = now.difference(checkIn).inMinutes / 60.0;

          await doc.reference.update({
            'checkOut': Timestamp.fromDate(now),
            'workHours': double.parse(workHours.toStringAsFixed(2)),
          });
        }
      } catch (_) {}
    }
  }

  // Get today's attendance for a user
  Future<AttendanceModel?> getTodayAttendance(String uid) async {
    if (isFirebaseAvailable) {
      try {
        final now = DateTime.now();
        final date =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        final result = await FirebaseFirestore.instance
            .collection('attendances')
            .where('uid', isEqualTo: uid)
            .where('date', isEqualTo: date)
            .get();

        if (result.docs.isNotEmpty) {
          return AttendanceModel.fromFirestore(result.docs.first);
        }
      } catch (_) {}
    }

    return _localDb.getTodayAttendance(uid);
  }

  // Get attendance history for a user
  Stream<List<AttendanceModel>> getAttendanceHistory(String uid) {
    if (isFirebaseAvailable) {
      try {
        return FirebaseFirestore.instance
            .collection('attendances')
            .where('uid', isEqualTo: uid)
            .orderBy('date', descending: true)
            .limit(30)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => AttendanceModel.fromFirestore(doc))
                .toList());
      } catch (_) {}
    }

    // Stream dari database lokal
    return _localDb.attendanceStream.map(
        (list) => list.where((a) => a.uid == uid).toList());
  }

  // Get all attendances (admin)
  Stream<List<AttendanceModel>> getAllAttendances({String? date}) {
    if (isFirebaseAvailable) {
      try {
        Query query = FirebaseFirestore.instance.collection('attendances');
        if (date != null) {
          query = query.where('date', isEqualTo: date);
        }
        return query
            .orderBy('date', descending: true)
            .limit(100)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => AttendanceModel.fromFirestore(doc))
                .toList());
      } catch (_) {}
    }

    return _localDb.attendanceStream.map((list) {
      if (date != null) {
        return list.where((a) => a.date == date).toList();
      }
      return list;
    });
  }

  // Get attendance stats for a user in current month
  Future<Map<String, int>> getMonthlyStats(String uid) async {
    if (isFirebaseAvailable) {
      try {
        final now = DateTime.now();
        final startOfMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
        final endOfMonth =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-31';

        final result = await FirebaseFirestore.instance
            .collection('attendances')
            .where('uid', isEqualTo: uid)
            .where('date', isGreaterThanOrEqualTo: startOfMonth)
            .where('date', isLessThanOrEqualTo: endOfMonth)
            .get();

        int present = 0;
        int late = 0;
        int absent = 0;

        for (final doc in result.docs) {
          final status = doc.data()['status'] as String? ?? '';
          if (status == 'present') present++;
          if (status == 'late') late++;
          if (status == 'absent') absent++;
        }

        return {
          'present': present,
          'late': late,
          'absent': absent,
          'total': result.docs.length,
        };
      } catch (_) {}
    }

    return _localDb.getMonthlyStats(uid);
  }

  // ── SCHEDULES ──

  // Get schedules for a user (or global)
  Stream<List<ScheduleModel>> getSchedules(String uid) {
    if (isFirebaseAvailable) {
      try {
        return FirebaseFirestore.instance
            .collection('schedules')
            .where('uid', whereIn: [uid, 'all'])
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => ScheduleModel.fromFirestore(doc))
                .toList());
      } catch (_) {}
    }

    return _localDb.scheduleStream;
  }

  // Set default schedules (admin)
  Future<void> setDefaultSchedules() async {
    final workDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
    for (final day in workDays) {
      final s = ScheduleModel(
        uid: 'all',
        dayOfWeek: day,
        startTime: '08:00',
        endTime: '17:00',
      );
      await _localDb.saveSchedule(s);

      if (isFirebaseAvailable) {
        try {
          final existing = await FirebaseFirestore.instance
              .collection('schedules')
              .where('uid', isEqualTo: 'all')
              .where('dayOfWeek', isEqualTo: day)
              .get();

          if (existing.docs.isEmpty) {
            await FirebaseFirestore.instance
                .collection('schedules')
                .add(s.toFirestore());
          }
        } catch (_) {}
      }
    }
  }

  // Update schedule (admin)
  Future<void> updateSchedule(String docId, ScheduleModel schedule) async {
    await _localDb.updateSchedule(docId, schedule);

    if (isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('schedules')
            .doc(docId)
            .update(schedule.toFirestore());
      } catch (_) {}
    }
  }

  // Add schedule (admin)
  Future<void> addSchedule(ScheduleModel schedule) async {
    await _localDb.saveSchedule(schedule);

    if (isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('schedules')
            .add(schedule.toFirestore());
      } catch (_) {}
    }
  }

  // ── REQUESTS ──

  // Submit request
  Future<void> submitRequest(RequestModel request) async {
    await _localDb.submitRequest(request);

    if (isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('requests')
            .add(request.toFirestore());
      } catch (_) {}
    }
  }

  // Get user's requests
  Stream<List<RequestModel>> getUserRequests(String uid) {
    if (isFirebaseAvailable) {
      try {
        return FirebaseFirestore.instance
            .collection('requests')
            .where('uid', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => RequestModel.fromFirestore(doc))
                .toList());
      } catch (_) {}
    }

    return _localDb.requestStream.map(
        (list) => list.where((r) => r.uid == uid).toList());
  }

  // Get all requests (admin)
  Stream<List<RequestModel>> getAllRequests({String? status}) {
    if (isFirebaseAvailable) {
      try {
        Query query = FirebaseFirestore.instance.collection('requests');
        if (status != null) {
          query = query.where('status', isEqualTo: status);
        }
        return query
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => RequestModel.fromFirestore(doc))
                .toList());
      } catch (_) {}
    }

    return _localDb.requestStream.map((list) {
      if (status != null) {
        return list.where((r) => r.status == status).toList();
      }
      return list;
    });
  }

  // Update request status (admin)
  Future<void> updateRequestStatus(
    String docId, {
    required String status,
    String adminNote = '',
  }) async {
    await _localDb.updateRequestStatus(docId,
        status: status, adminNote: adminNote);

    if (isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(docId)
            .update({
          'status': status,
          'adminNote': adminNote,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } catch (_) {}
    }
  }

  // ── EMPLOYEES (Admin) ──

  // Get all employees
  Stream<List<UserModel>> getAllEmployees() {
    if (isFirebaseAvailable) {
      try {
        return FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'employee')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList());
      } catch (_) {}
    }

    return _localDb.employeeStream;
  }

  // Get all users
  Stream<List<UserModel>> getAllUsers() {
    return getAllEmployees();
  }

  // Toggle employee active status
  Future<void> toggleEmployeeStatus(String uid, bool isActive) async {
    await _localDb.toggleEmployeeStatus(uid, isActive);

    if (isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'isActive': isActive});
      } catch (_) {}
    }
  }

  // Update employee data
  Future<void> updateEmployee(String uid, Map<String, dynamic> data) async {
    await _localDb.updateEmployee(uid, data);

    if (isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(data);
      } catch (_) {}
    }
  }

  // Delete employee
  Future<void> deleteEmployee(String uid) async {
    await _localDb.deleteEmployee(uid);

    if (isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      } catch (_) {}
    }
  }

  // Get total employee count
  Future<int> getEmployeeCount() async {
    if (isFirebaseAvailable) {
      try {
        final result = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'employee')
            .get();
        return result.docs.length;
      } catch (_) {}
    }

    return _localDb.getAllEmployees().length;
  }

  // Get today's attendance count
  Future<Map<String, int>> getTodayAttendanceStats() async {
    if (isFirebaseAvailable) {
      try {
        final now = DateTime.now();
        final date =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        final result = await FirebaseFirestore.instance
            .collection('attendances')
            .where('date', isEqualTo: date)
            .get();

        int present = 0;
        int late = 0;

        for (final doc in result.docs) {
          final status = doc.data()['status'] as String? ?? '';
          if (status == 'present') present++;
          if (status == 'late') late++;
        }

        return {
          'present': present,
          'late': late,
          'total': result.docs.length,
        };
      } catch (_) {}
    }

    return _localDb.getTodayStats();
  }

  // Get pending request count
  Future<int> getPendingRequestCount() async {
    if (isFirebaseAvailable) {
      try {
        final result = await FirebaseFirestore.instance
            .collection('requests')
            .where('status', isEqualTo: 'pending')
            .get();
        return result.docs.length;
      } catch (_) {}
    }

    return _localDb
        .getAllRequests(status: 'pending')
        .length;
  }
}
