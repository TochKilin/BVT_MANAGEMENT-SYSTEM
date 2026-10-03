import 'package:mongo_dart/mongo_dart.dart';

class VaccinationModel {
  final ObjectId? id;
  final String ownerId;
  final String animalId;
  final String vaccineName;
  final String unit;
  final String manufacturer;
  final String batchNumber;
  final DateTime administeredAt;
  final DateTime? nextDueAt;
  final String veterinarian;
  final String notes;
  final String image;

  VaccinationModel({
    this.id,
    required this.ownerId,
    required this.animalId,
    required this.vaccineName,
    this.unit = '',
    this.manufacturer = '',
    this.batchNumber = '',
    DateTime? administeredAt,
    this.nextDueAt,
    this.veterinarian = '',
    this.notes = '',
    this.image = '',
  }) : administeredAt = administeredAt ?? DateTime.now();

  factory VaccinationModel.fromMap(Map<String, dynamic> map) => VaccinationModel(
        id: _id(map['_id']),
        ownerId: map['owner_id']?.toString() ?? '',
        animalId: map['animal_id']?.toString() ?? '',
        vaccineName: map['vaccine_name']?.toString() ?? '',
        unit: map['unit']?.toString() ?? '',
        manufacturer: map['manufacturer']?.toString() ?? '',
        batchNumber: map['batch_number']?.toString() ?? '',
        administeredAt: _date(map['administered_at']) ?? DateTime.now(),
        nextDueAt: _date(map['next_due_at']),
        veterinarian: map['veterinarian']?.toString() ?? '',
        notes: map['notes']?.toString() ?? '',
        image: map['image']?.toString() ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) '_id': id,
        'owner_id': ownerId,
        'animal_id': animalId,
        'vaccine_name': vaccineName,
        'unit': unit,
        'manufacturer': manufacturer,
        'batch_number': batchNumber,
        'administered_at': administeredAt.toIso8601String(),
        'next_due_at': nextDueAt?.toIso8601String(),
        'veterinarian': veterinarian,
        'notes': notes,
        'image': image,
      };

  static ObjectId? _id(dynamic value) {
    if (value is ObjectId) return value;
    if (value is String) {
      try { return ObjectId.fromHexString(value); } catch (_) { return null; }
    }
    return null;
  }

  static DateTime? _date(dynamic value) => value is DateTime ? value : value is String ? DateTime.tryParse(value) : null;
}
