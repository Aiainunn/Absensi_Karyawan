import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String uid;
  final String userName;
  final String date; // 'yyyy-MM-dd'
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String method; // 'camera' | 'fingerprint'
  final String status; // 'present' | 'late' | 'absent' | 'permission'
  final double workHours;
  final String note;

  AttendanceModel({
    this.id = '',
    required this.uid,
    required this.userName,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.method = 'camera',
    this.status = 'present',
    this.workHours = 0,
    this.note = '',
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? '',
      date: data['date'] ?? '',
      checkIn: data['checkIn'] != null
          ? (data['checkIn'] as Timestamp).toDate()
          : null,
      checkOut: data['checkOut'] != null
          ? (data['checkOut'] as Timestamp).toDate()
          : null,
      method: data['method'] ?? 'camera',
      status: data['status'] ?? 'present',
      workHours: (data['workHours'] ?? 0).toDouble(),
      note: data['note'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'userName': userName,
      'date': date,
      'checkIn': checkIn != null ? Timestamp.fromDate(checkIn!) : null,
      'checkOut': checkOut != null ? Timestamp.fromDate(checkOut!) : null,
      'method': method,
      'status': status,
      'workHours': workHours,
      'note': note,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? uid,
    String? userName,
    String? date,
    DateTime? checkIn,
    DateTime? checkOut,
    String? method,
    String? status,
    double? workHours,
    String? note,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      method: method ?? this.method,
      status: status ?? this.status,
      workHours: workHours ?? this.workHours,
      note: note ?? this.note,
    );
  }

  String get checkInFormatted {
    if (checkIn == null) return '--:--';
    return '${checkIn!.hour.toString().padLeft(2, '0')}:${checkIn!.minute.toString().padLeft(2, '0')}';
  }

  String get checkOutFormatted {
    if (checkOut == null) return '--:--';
    return '${checkOut!.hour.toString().padLeft(2, '0')}:${checkOut!.minute.toString().padLeft(2, '0')}';
  }

  String get workHoursFormatted {
    final hours = workHours.floor();
    final minutes = ((workHours - hours) * 60).round();
    return '${hours}j ${minutes}m';
  }

  String get statusLabel {
    switch (status) {
      case 'present':
        return 'Hadir';
      case 'late':
        return 'Terlambat';
      case 'absent':
        return 'Tidak Hadir';
      case 'permission':
        return 'Izin';
      default:
        return status;
    }
  }
}
