
import 'package:mongo_dart/mongo_dart.dart';

class PrescriptionItem {
  final ObjectId medicineId;
  final String medicineName;
  final String unit;
  final String dosage;
  final String frequency;
  final String duration;

  PrescriptionItem({
    required this.medicineId,
    required this.medicineName,
    this.unit = '',
    required this.dosage,
    required this.frequency,
    required this.duration,
  });

  factory PrescriptionItem.fromMap(Map<String, dynamic> map) {
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

    return PrescriptionItem(
      medicineId: parseObjectId(map['medicine_id']),
      medicineName: map['medicine_name']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      dosage: map['dosage']?.toString() ?? '',
      frequency: map['frequency']?.toString() ?? '',
      duration: map['duration']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicine_id': medicineId.oid,
      'medicine_name': medicineName,
      'unit': unit,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
    };
  }
}

class MedicalRecordModel {
  final ObjectId? id;
  final ObjectId animalId;
  final ObjectId ownerId;
  final ObjectId veterinarianId;
  final DateTime visitDate;
  final String symptoms;
  final String diagnosis;
  final String treatment;
  final List<PrescriptionItem> prescriptionItems;

  MedicalRecordModel({
    this.id,
    required this.animalId,
    required this.ownerId,
    required this.veterinarianId,
    DateTime? visitDate,
    required this.symptoms,
    required this.diagnosis,
    required this.treatment,
    required this.prescriptionItems,
  }) : visitDate = visitDate ?? DateTime.now();

  factory MedicalRecordModel.fromMap(Map<String, dynamic> map) {
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

    return MedicalRecordModel(
      id: parseObjectId(map['_id']),
      animalId: parseObjectId(map['animal_id']) ?? ObjectId(),
      ownerId: parseObjectId(map['owner_id']) ?? ObjectId(),
      veterinarianId: parseObjectId(map['veterinarian_id']) ?? ObjectId(),
      visitDate: parseDate(map['visit_date']),
      symptoms: map['symptoms']?.toString() ?? '',
      diagnosis: map['diagnosis']?.toString() ?? '',
      treatment: map['treatment']?.toString() ?? '',
      prescriptionItems: (map['prescription']?['items'] is List)
          ? (map['prescription']['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map((i) => PrescriptionItem.fromMap(i))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'animal_id': animalId.oid,
      'owner_id': ownerId.oid,
      'veterinarian_id': veterinarianId.oid,
      'visit_date': visitDate.toIso8601String(),
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescription': {
        'items': prescriptionItems.map((i) => i.toMap()).toList(),
      }
    };

    final currentId = id;
    if (currentId != null) {
      map['_id'] = currentId.oid;
    }

    return map;
  }
}
