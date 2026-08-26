import 'package:mongo_dart/mongo_dart.dart';

class AppointmentModel {
  final ObjectId? id;
  final String ownerId;
  final String animalId;
  final DateTime scheduledAt;
  final String reason;
  final String veterinarian;
  final String status;
  final String notes;

  AppointmentModel({this.id, required this.ownerId, required this.animalId, required this.scheduledAt, required this.reason, this.veterinarian = '', this.status = 'scheduled', this.notes = ''});

  factory AppointmentModel.fromMap(Map<String, dynamic> map) => AppointmentModel(
        id: _id(map['_id']), ownerId: map['owner_id']?.toString() ?? '', animalId: map['animal_id']?.toString() ?? '',
        scheduledAt: _date(map['scheduled_at']) ?? DateTime.now(), reason: map['reason']?.toString() ?? '',
        veterinarian: map['veterinarian']?.toString() ?? '', status: map['status']?.toString() ?? 'scheduled', notes: map['notes']?.toString() ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) '_id': id, 'owner_id': ownerId, 'animal_id': animalId, 'scheduled_at': scheduledAt.toIso8601String(),
        'reason': reason, 'veterinarian': veterinarian, 'status': status, 'notes': notes,
      };

  static ObjectId? _id(dynamic value) {
    if (value is ObjectId) return value;
    if (value is String) { try { return ObjectId.fromHexString(value); } catch (_) { return null; } }
    return null;
  }
  static DateTime? _date(dynamic value) => value is DateTime ? value : value is String ? DateTime.tryParse(value) : null;
}
