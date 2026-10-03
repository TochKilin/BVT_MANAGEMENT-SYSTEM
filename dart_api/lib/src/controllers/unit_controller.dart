import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';
import '../utils/json_utils.dart';

class UnitController {
  static const _headers = {'content-type': 'application/json'};
  static const _defaults = {
    'medicine': ['kg', 'g', 'mg', 'tablet', 'bottle'],
    'vaccine': ['ml', 'l', 'dose', 'vial'],
  };

  Future<Response> getAll(Request request) async {
    try {
      final collection = await DatabaseService.getCollection('units');
      for (final entry in _defaults.entries) {
        for (final name in entry.value) {
          if (await collection.findOne(where.eq('type', entry.key).eq('name', name)) == null) {
            await collection.insertOne(<String, dynamic>{'_id': ObjectId(), 'type': entry.key, 'name': name, 'created_at': DateTime.now().toIso8601String()});
          }
        }
      }
      final rows = await collection.find(where.sortBy('type').sortBy('name')).toList();
      return Response.ok(jsonEncode(jsonSafe(rows)), headers: _headers);
    } catch (error, stackTrace) {
      print('Unit list failed: $error');
      print(stackTrace);
      return _error(error);
    }
  }

  Future<Response> create(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final type = body['type']?.toString().trim() ?? '';
      final name = body['name']?.toString().trim() ?? '';
      if (!_defaults.containsKey(type) || name.isEmpty) return _bad('A valid type and unit name are required');
      final collection = await DatabaseService.getCollection('units');
      if (await collection.findOne(where.eq('type', type).eq('name', name)) != null) return _bad('This unit already exists');
      final unit = <String, dynamic>{'_id': ObjectId(), 'type': type, 'name': name, 'created_at': DateTime.now().toIso8601String()};
      await collection.insertOne(unit);
      return Response(201, body: jsonEncode(jsonSafe(unit)), headers: _headers);
    } catch (error, stackTrace) {
      print('Unit create failed: $error');
      print(stackTrace);
      return _error(error);
    }
  }

  Future<Response> delete(Request request, String id) async {
    try {
      ObjectId objectId;
      try { objectId = ObjectId.fromHexString(id); } catch (_) { return _bad('Invalid unit id'); }
      final result = await (await DatabaseService.getCollection('units')).deleteOne(where.id(objectId));
      if (result.nRemoved == 0) return Response.notFound(jsonEncode({'error': 'Unit not found'}), headers: _headers);
      return Response.ok(jsonEncode({'message': 'Unit deleted'}), headers: _headers);
    } catch (error) {
      return _error(error);
    }
  }

  Response _bad(String message) => Response.badRequest(body: jsonEncode({'error': message}), headers: _headers);
  Response _error(Object error) => Response.internalServerError(body: jsonEncode({'error': error.toString()}), headers: _headers);
}
