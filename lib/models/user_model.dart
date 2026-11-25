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

  /// Factory untuk memetakan respons JSON dari REST API Node.js + Express
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      role: json['role']?.toString() ?? 'employee',
      photoUrl: json['photoUrl']?.toString() ??
          json['photo_url']?.toString() ??
          '',
      joinDate: json['joinDate'] != null
          ? DateTime.tryParse(json['joinDate'].toString()) ?? DateTime.now()
          : (json['join_date'] != null
              ? DateTime.tryParse(json['join_date'].toString()) ?? DateTime.now()
              : DateTime.now()),
      isActive: json['isActive'] == true ||
          json['is_active'] == 1 ||
          json['is_active'] == true ||
          json['isActive'] == 1 ||
          json['isActive'] == null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  /// Konversi ke format Map JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'position': position,
      'department': department,
      'role': role,
      'photoUrl': photoUrl,
      'joinDate': joinDate.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

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
