import 'dart:convert';
import 'package:dart_api/src/models/medical_record_model.dart';
import 'package:shelf/shelf.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../config/database.dart';
import '../utils/json_utils.dart';


class RecordController {
  Future<Response> getAll(Request request) async {
    try {
      final collection = await DatabaseService.getCollection('medical_records');
      final data = await collection.find().toList();

      final records = data.map((item) {
        return jsonSafe(MedicalRecordModel.fromMap(item).toMap());
      }).toList();

      return Response.ok(
        jsonEncode(records),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch medical records: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }


  Future<Response> getById(Request request, String id) async {
    try {
      final collection = await DatabaseService.getCollection('medical_records');
      final data = await collection.findOne(where.id(ObjectId.fromHexString(id)));

      if (data == null) {
        return Response.notFound(
          jsonEncode({'error': 'Medical record not found'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final record = MedicalRecordModel.fromMap(data);

      return Response.ok(
        jsonEncode(jsonSafe(record.toMap())),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch medical record: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }


  Future<Response> create(Request request) async {
    try {
      final payload = await request.readAsString();
      if (payload.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Request body cannot be empty'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final body = jsonDecode(payload) as Map<String, dynamic>;
      final record = MedicalRecordModel.fromMap(body);

      final collection = await DatabaseService.getCollection('medical_records');
      await collection.insertOne(record.toMap());

      return Response.ok(
        jsonEncode({
          'message': 'Medical record created successfully',
          'data': jsonSafe(record.toMap()),
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create medical record: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }


  Future<Response> update(Request request, String id) async {
    try {
      final payload = await request.readAsString();
      final body = jsonDecode(payload) as Map<String, dynamic>;

      final collection = await DatabaseService.getCollection('medical_records');
      final objId = ObjectId.fromHexString(id);

      final updatedRecord = MedicalRecordModel.fromMap({...body, '_id': objId});

      await collection.updateOne(
        where.id(objId),
        modify
            .set('animal_id', updatedRecord.animalId.oid)
            .set('owner_id', updatedRecord.ownerId.oid)
            .set('veterinarian_id', updatedRecord.veterinarianId.oid)
            .set('symptoms', updatedRecord.symptoms)
            .set('diagnosis', updatedRecord.diagnosis)
            .set('treatment', updatedRecord.treatment)
            .set('prescription', {
              'items': updatedRecord.prescriptionItems.map((i) => i.toMap()).toList(),
            }),
      );

      return Response.ok(
        jsonEncode({'message': 'Medical record updated successfully'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update medical record: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }


  Future<Response> delete(Request request, String id) async {
    try {
      final collection = await DatabaseService.getCollection('medical_records');
      await collection.remove(where.id(ObjectId.fromHexString(id)));

      return Response.ok(
        jsonEncode({'message': 'Medical record deleted successfully'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete medical record: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
