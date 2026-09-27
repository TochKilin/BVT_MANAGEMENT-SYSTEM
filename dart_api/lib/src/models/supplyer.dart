import 'package:mongo_dart/mongo_dart.dart';

class SupplierModel {
  final ObjectId? id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final String status; 
  final DateTime createdAt;
  final DateTime updatedAt;

  SupplierModel({
    this.id,
    required this.name,
    this.contactPerson = '',
    required this.phone,
    this.email = '',
    this.address = '',
    this.notes = '',
    this.status = 'active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      name: (map['name'] ?? '').toString().trim(),
      contactPerson: (map['contact_person'] ?? '').toString().trim(),
      phone: (map['phone'] ?? '').toString().trim(),
      email: (map['email'] ?? '').toString().trim(),
      address: (map['address'] ?? '').toString().trim(),
      notes: (map['notes'] ?? '').toString().trim(),
      status: (map['status'] ?? 'active').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Update
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}