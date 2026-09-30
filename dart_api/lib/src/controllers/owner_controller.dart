import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../config/database.dart';
import '../models/owner_model.dart';
import '../utils/json_utils.dart';

class OwnerController {

  String _idHex(dynamic value) {
    if (value is ObjectId) return value.oid;
    final match = RegExp(r'[a-fA-F0-9]{24}').firstMatch(value?.toString() ?? '');
    return match?.group(0)?.toLowerCase() ?? '';
  }

  Future<Response> getAll(Request request) async {
    try {
      final collection = await DatabaseService.getCollection('owners');
      final data = await collection.find().toList();
      final owners = data.map((m) => jsonSafe(OwnerModel.fromMap(m).toMap())).toList();

      return Response.ok(
        jsonEncode(owners),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error fetching owners: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  
  Future<Response> getById(Request request, String id) async {
    try {
      final collection = await DatabaseService.getCollection('owners');
      final data = await collection.findOne(where.id(ObjectId.fromHexString(id)));

      if (data == null) {
        return Response.notFound(
          jsonEncode({'error': 'Owner not found'}),
          headers: {'content-type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(jsonSafe(OwnerModel.fromMap(data).toMap())),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error fetching owner: $e'}),
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
      final owner = OwnerModel.fromMap(body);

      final collection = await DatabaseService.getCollection('owners');
      await collection.insertOne(owner.toMap());

      return Response.ok(
        jsonEncode({'message': 'Owner created successfully', 'data': jsonSafe(owner.toMap())}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error creating owner: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> update(Request request, String id) async {
    try {
      final payload = await request.readAsString();
      final body = jsonDecode(payload) as Map<String, dynamic>;

      final collection = await DatabaseService.getCollection('owners');
      final objId = ObjectId.fromHexString(id);

      await collection.updateOne(
        where.id(objId),
        modify
            .set('name', body['name'])
            .set('phone', body['phone'])
            .set('email', body['email'])
            .set('address', body['address']),
      );

      return Response.ok(
        jsonEncode({'message': 'Owner updated successfully'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error updating owner: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }


  Future<Response> delete(Request request, String id) async {
    try {
      final collection = await DatabaseService.getCollection('owners');
      await collection.remove(where.id(ObjectId.fromHexString(id)));

      return Response.ok(
        jsonEncode({'message': 'Owner deleted successfully'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Error deleting owner: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> updateAnimal(Request request, String ownerId, String animalId) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final animal = Map<String, dynamic>.from(body['animal'] as Map);
      animal['_id'] = ObjectId.fromHexString(animalId);
      final collection = await DatabaseService.getCollection('owners');
      final ownerObjectId = ObjectId.fromHexString(ownerId);
      final existing = await collection.findOne(where.id(ownerObjectId));
      if (existing == null) {
        return Response.notFound(jsonEncode({'error': 'Owner not found'}), headers: {'content-type': 'application/json'});
      }
      final animals = (existing['animals'] as List? ?? []).map((item) => Map<String, dynamic>.from(item as Map)).toList();
      final targetId = _idHex(animal['_id']);
      final index = animals.indexWhere((item) => _idHex(item['_id']) == targetId);
      if (index < 0) {
        return Response.notFound(jsonEncode({'error': 'Patient not found'}), headers: {'content-type': 'application/json'});
      }
      animals[index] = animal;
      await collection.updateOne(where.id(ownerObjectId), modify.set('name', body['name']).set('phone', body['phone']).set('animals', animals));
      return Response.ok(jsonEncode({'message': 'Patient updated successfully'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error updating patient: $e'}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> deleteAnimal(Request request, String ownerId, String animalId) async {
    try {
      final collection = await DatabaseService.getCollection('owners');
      final ownerObjectId = ObjectId.fromHexString(ownerId);
      final existing = await collection.findOne(where.id(ownerObjectId));
      if (existing == null) {
        return Response.notFound(jsonEncode({'error': 'Owner not found'}), headers: {'content-type': 'application/json'});
      }
      final targetId = ObjectId.fromHexString(animalId);
      final animals = (existing['animals'] as List? ?? []).where((item) => _idHex((item as Map)['_id']) != targetId.oid).toList();
      await collection.updateOne(where.id(ownerObjectId), modify.set('animals', animals));
      return Response.ok(jsonEncode({'message': 'Patient deleted successfully'}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error deleting patient: $e'}), headers: {'content-type': 'application/json'});
    }
  }
}
