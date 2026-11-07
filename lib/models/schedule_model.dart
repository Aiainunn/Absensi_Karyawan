import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String id;
  final String uid; // user uid or 'all' for global
  final String dayOfWeek; // 'monday', 'tuesday', etc.
  final String startTime; // 'HH:mm'
  final String endTime; // 'HH:mm'
  final bool isActive;
  final String note;

  ScheduleModel({
    this.id = '',
    this.uid = 'all',
    required this.dayOfWeek,
    this.startTime = '08:00',
    this.endTime = '17:00',
    this.isActive = true,
    this.note = '',
  });

  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleModel(
      id: doc.id,
      uid: data['uid'] ?? 'all',
      dayOfWeek: data['dayOfWeek'] ?? '',
      startTime: data['startTime'] ?? '08:00',
      endTime: data['endTime'] ?? '17:00',
      isActive: data['isActive'] ?? true,
      note: data['note'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
      'note': note,
    };
  }

  String get dayLabel {
    switch (dayOfWeek.toLowerCase()) {
      case 'monday':
        return 'Senin';
      case 'tuesday':
        return 'Selasa';
      case 'wednesday':
        return 'Rabu';
      case 'thursday':
        return 'Kamis';
      case 'friday':
        return 'Jumat';
      case 'saturday':
        return 'Sabtu';
      case 'sunday':
        return 'Minggu';
      default:
        return dayOfWeek;
    }
  }

  String get shortDayLabel {
    switch (dayOfWeek.toLowerCase()) {
      case 'monday':
        return 'Sen';
      case 'tuesday':
        return 'Sel';
      case 'wednesday':
        return 'Rab';
      case 'thursday':
        return 'Kam';
      case 'friday':
        return 'Jum';
      case 'saturday':
        return 'Sab';
      case 'sunday':
        return 'Min';
      default:
        return dayOfWeek;
    }
  }

  static List<String> get allDays => [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];
}
