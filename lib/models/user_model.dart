import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String position;
  final String department;
  final String role; // 'employee' | 'admin'
  final String photoUrl;
  final DateTime joinDate;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.position = '',
    this.department = '',
    this.role = 'employee',
    this.photoUrl = '',
    DateTime? joinDate,
    this.isActive = true,
    DateTime? createdAt,
  })  : joinDate = joinDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      position: data['position'] ?? '',
      department: data['department'] ?? '',
      role: data['role'] ?? 'employee',
      photoUrl: data['photoUrl'] ?? '',
      joinDate: data['joinDate'] != null
          ? (data['joinDate'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'position': position,
      'department': department,
      'role': role,
      'photoUrl': photoUrl,
      'joinDate': Timestamp.fromDate(joinDate),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? position,
    String? department,
    String? role,
    String? photoUrl,
    DateTime? joinDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      position: position ?? this.position,
      department: department ?? this.department,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      joinDate: joinDate ?? this.joinDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
