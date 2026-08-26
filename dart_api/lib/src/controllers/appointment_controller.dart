import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';
import '../models/appointment_model.dart';

class AppointmentController {
  static const _headers = {'content-type': 'application/json'};

  Future<Response> getAll(Request request) async {
    try {
      final records = await (await DatabaseService.getCollection('appointments')).find(where.sortBy('scheduled_at')).toList();
      return Response.ok(jsonEncode(records.map(_json).toList()), headers: _headers);
    } catch (error) { return _error(error); }
  }

  Future<Response> create(Request request) async {
    try {
      final appointment = AppointmentModel.fromMap(await _body(request));
      if (appointment.ownerId.isEmpty || appointment.animalId.isEmpty || appointment.reason.isEmpty) return Response.badRequest(body: jsonEncode({'error': 'owner_id, animal_id and reason are required'}), headers: _headers);
      final result = await (await DatabaseService.getCollection('appointments')).insertOne(appointment.toMap());
      return Response(201, body: jsonEncode({'data': _json(result.document ?? appointment.toMap())}), headers: _headers);
    } catch (error) { return _error(error); }
  }

  Future<Response> update(Request request, String id) async {
    try {
      final body = await _body(request); body.remove('_id');
      await (await DatabaseService.getCollection('appointments')).updateOne(where.id(ObjectId.fromHexString(id)), {'\$set': body});
      return Response.ok(jsonEncode({'message': 'Appointment updated'}), headers: _headers);
    } catch (error) { return _error(error); }
  }

  Future<Response> delete(Request request, String id) async {
    try {
      await (await DatabaseService.getCollection('appointments')).deleteOne(where.id(ObjectId.fromHexString(id)));
      return Response.ok(jsonEncode({'message': 'Appointment deleted'}), headers: _headers);
    } catch (error) { return _error(error); }
  }

  Future<Map<String, dynamic>> _body(Request request) async => jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  Response _error(Object error) => Response.internalServerError(body: jsonEncode({'error': error.toString()}), headers: _headers);
  Map<String, dynamic> _json(Map<String, dynamic> item) => item.map((key, value) => MapEntry(key, value is ObjectId ? value.oid : value));
}
