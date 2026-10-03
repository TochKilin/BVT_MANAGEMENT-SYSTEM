import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';

class PrescriptionController {
  static const _headers = {'content-type': 'application/json'};

  Future<Response> getAll(Request request) async {
    try {
      final rows = await (await DatabaseService.getCollection('prescriptions'))
          .find(where.sortBy('created_at', descending: true)).toList();
      return Response.ok(jsonEncode(rows.map(_safe).toList()), headers: _headers);
    } catch (error) { return _error(error); }
  }

  Future<Response> create(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      for (final key in ['owner_id', 'animal_id', 'medicine_id', 'medicine_name', 'dosage', 'frequency', 'duration']) {
        if ((body[key]?.toString().trim() ?? '').isEmpty) {
          return Response.badRequest(body: jsonEncode({'error': '$key is required'}), headers: _headers);
        }
      }
      for (final key in ['owner_id', 'animal_id', 'medicine_id']) {
        if (!_validId(body[key].toString())) {
          return Response.badRequest(body: jsonEncode({'error': 'Invalid $key'}), headers: _headers);
        }
      }
      final doc = <String, dynamic>{
        'owner_id': ObjectId.fromHexString(body['owner_id'].toString()),
        'animal_id': ObjectId.fromHexString(body['animal_id'].toString()),
        'medicine_id': ObjectId.fromHexString(body['medicine_id'].toString()),
        'medicine_name': body['medicine_name'].toString(),
        'unit': body['unit']?.toString() ?? '',
        'dosage': body['dosage'].toString(),
        'frequency': body['frequency'].toString(),
        'duration': body['duration'].toString(),
        'quantity': int.tryParse(body['quantity']?.toString() ?? '') ?? 1,
        'notes': body['notes']?.toString() ?? '',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };
      final result = await (await DatabaseService.getCollection('prescriptions')).insertOne(doc);
      return Response(201, body: jsonEncode({'data': _safe(result.document ?? doc)}), headers: _headers);
    } catch (error) { return _error(error); }
  }

  bool _validId(String value) { try { ObjectId.fromHexString(value); return true; } catch (_) { return false; } }
  Map<String, dynamic> _safe(Map<String, dynamic> item) => item.map((key, value) => MapEntry(key, value is ObjectId ? value.oid : value));
  Response _error(Object error) => Response.internalServerError(body: jsonEncode({'error': error.toString()}), headers: _headers);
}
