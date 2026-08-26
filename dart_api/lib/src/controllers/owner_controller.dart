import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../config/database.dart';
import '../models/owner_model.dart';
import '../utils/json_utils.dart';

class OwnerController {

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
}
