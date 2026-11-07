import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String uid;
  final String userName;
  final String type; // 'leave' | 'overtime' | 'resignation'
  final String reason;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String adminNote;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RequestModel({
    this.id = '',
    required this.uid,
    required this.userName,
    required this.type,
    required this.reason,
    required this.startDate,
    this.endDate,
    this.status = 'pending',
    this.adminNote = '',
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RequestModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? '',
      type: data['type'] ?? '',
      reason: data['reason'] ?? '',
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'pending',
      adminNote: data['adminNote'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'userName': userName,
      'type': type,
      'reason': reason,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'status': status,
      'adminNote': adminNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt':
          updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  RequestModel copyWith({
    String? id,
    String? uid,
    String? userName,
    String? type,
    String? reason,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? adminNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RequestModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'leave':
        return 'Cuti / Izin';
      case 'overtime':
        return 'Lembur';
      case 'resignation':
        return 'Pengunduran Diri';
      default:
        return type;
    }
  }

  String get typeIcon {
    switch (type) {
      case 'leave':
        return '🏖️';
      case 'overtime':
        return '⏰';
      case 'resignation':
        return '📝';
      default:
        return '📋';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }
}
