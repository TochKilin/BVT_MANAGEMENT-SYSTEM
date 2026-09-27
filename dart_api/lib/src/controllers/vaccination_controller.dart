import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import '../config/database.dart';
import '../models/vaccination_model.dart';

class VaccinationController {
  static const _headers = {'content-type': 'application/json'};

  Future<Response> getAll(Request request) async {
    try {
      final records = await (await DatabaseService.getCollection('vaccinations')).find(where.sortBy('next_due_at')).toList();
      return Response.ok(jsonEncode(records.map(_json).toList()), headers: _headers);
    } catch (error) { return _error(error); }
  }

  Future<Response> create(Request request) async {
    try {
      final body = await _body(request);
      final vaccination = VaccinationModel.fromMap(body);
      if (vaccination.ownerId.isEmpty || vaccination.animalId.isEmpty || vaccination.vaccineName.isEmpty) return Response.badRequest(body: jsonEncode({'error': 'owner_id, animal_id and vaccine_name are required'}), headers: _headers);
      final result = await (await DatabaseService.getCollection('vaccinations')).insertOne(vaccination.toMap());
      return Response(201, body: jsonEncode({'data': _json(result.document ?? vaccination.toMap())}), headers: _headers);
    } catch (error) { return _error(error); }
  }

  Future<Response> update(Request request, String id) async {
    try {
      final objectId = ObjectId.fromHexString(id);
      final body = await _body(request);
      body.remove('_id');
      await (await DatabaseService.getCollection('vaccinations')).updateOne(where.id(objectId), {'\$set': body});
      return Response.ok(jsonEncode({'message': 'Vaccination updated'}), headers: _headers);
    } catch (error) { return _error(error); }
  }

  Future<Response> delete(Request request, String id) async {
    try {
      await (await DatabaseService.getCollection('vaccinations')).deleteOne(where.id(ObjectId.fromHexString(id)));
      return Response.ok(jsonEncode({'message': 'Vaccination deleted'}), headers: _headers);
    } catch (error) { return _error(error); }
  }

  Future<Map<String, dynamic>> _body(Request request) async => jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  Response _error(Object error) => Response.internalServerError(body: jsonEncode({'error': error.toString()}), headers: _headers);
  Map<String, dynamic> _json(Map<String, dynamic> item) => item.map((key, value) => MapEntry(key, value is ObjectId ? value.oid : value));
}
