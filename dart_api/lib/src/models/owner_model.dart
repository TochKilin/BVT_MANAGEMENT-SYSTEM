import 'package:mongo_dart/mongo_dart.dart';

class AnimalModel {
  final ObjectId id;
  final String name;
  final String species;
  final String breed;
  final String gender;
  final DateTime? dateOfBirth;
  final double weight;
  final String color;
  final String photo;

  AnimalModel({
    ObjectId? id,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    this.dateOfBirth,
    required this.weight,
    required this.color,
    this.photo = '',
  }) : id = id ?? ObjectId();

  factory AnimalModel.fromMap(Map<String, dynamic> map) {

    DateTime? parseDate(dynamic date) {
      if (date is DateTime) return date;
      if (date is String && date.isNotEmpty) return DateTime.tryParse(date);
      return null;
    }

   
    ObjectId parseObjectId(dynamic id) {
      if (id is ObjectId) return id;
      if (id is String && id.isNotEmpty) {
        try {
          return ObjectId.fromHexString(id);
        } catch (_) {
          return ObjectId();
        }
      }
      return ObjectId();
    }

    return AnimalModel(
      id: parseObjectId(map['_id']),
      name: map['name']?.toString() ?? '',
      species: map['species']?.toString() ?? '',
      breed: map['breed']?.toString() ?? '',
      gender: map['gender']?.toString() ?? '',
      dateOfBirth: parseDate(map['date_of_birth']),
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      color: map['color']?.toString() ?? '',
      photo: map['photo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id.oid,
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'weight': weight,
      'color': color,
      'photo': photo,
    };
  }
}

class OwnerModel {
  final ObjectId? id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final List<AnimalModel> animals;
  final DateTime createdAt;

  OwnerModel({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.animals,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory OwnerModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic date) {
      if (date is DateTime) return date;
      if (date is String && date.isNotEmpty) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    ObjectId? parseObjectId(dynamic id) {
      if (id is ObjectId) return id;
      if (id is String && id.isNotEmpty) {
        try {
          return ObjectId.fromHexString(id);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return OwnerModel(
      id: parseObjectId(map['_id']),
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      animals: (map['animals'] is List)
          ? (map['animals'] as List)
              .whereType<Map<String, dynamic>>()
              .map((a) => AnimalModel.fromMap(a))
              .toList()
          : [],
      createdAt: parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'animals': animals.map((a) => a.toMap()).toList(),
      'created_at': createdAt.toIso8601String(), 
    };

    final currentId = id;
    if (currentId != null) {
      map['_id'] = currentId.oid;
    }

    return map;
  }
}