import 'package:mongo_dart/mongo_dart.dart';

class RoleModel {
  final String name;
  final String description;

  RoleModel({required this.name, required this.description});

  factory RoleModel.fromMap(Map<String, dynamic> map) {
    return RoleModel(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }
}

class UserModel {
  final ObjectId? id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final RoleModel role;
  final String status;
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.role,
    this.status = 'active',
    this.avatarUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['_id'] as ObjectId?,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      phone: map['phone'] ?? '',
      role: RoleModel.fromMap(map['role'] as Map<String, dynamic>? ?? {}),
      status: map['status'] ?? 'active',
      avatarUrl: map['avatarUrl'] as String?,
      createdAt: map['created_at'] is DateTime
          ? map['created_at'] as DateTime
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role.toMap(),
      'status': status,
      'avatarUrl': avatarUrl,
      'created_at': createdAt,
    };

    final currentId = id;
    if (currentId != null) {
      map['_id'] = currentId;
    }

    return map;
  }
}