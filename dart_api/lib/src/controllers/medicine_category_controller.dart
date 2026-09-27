import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';
import '../utils/json_utils.dart';

class MedicineCategoryController {
  static const _headers = {'content-type': 'application/json'};

  Future<Response> getAll(Request request) async {
    try {
      final categories = await (await DatabaseService.getCollection('medicine_categories')).find().toList();
      final medicines = await (await DatabaseService.getCollection('medicines')).find().toList();
      final counts = <String, int>{};
      for (final medicine in medicines) {
        final raw = medicine['category'];
        final name = raw is Map ? raw['name']?.toString() ?? '' : raw?.toString() ?? '';
        if (name.trim().isNotEmpty) counts[name.trim()] = (counts[name.trim()] ?? 0) + 1;
      }
      final names = <String, Map<String, dynamic>>{};
      for (final category in categories) {
        final name = category['name']?.toString() ?? '';
        if (name.isNotEmpty) names[name] = {...category, 'medicine_count': counts[name] ?? 0};
      }
      for (final entry in counts.entries) {
        names.putIfAbsent(entry.key, () => {'name': entry.key, 'medicine_count': entry.value});
      }
      return Response.ok(jsonEncode(names.values.map((item) => item.map((key, value) => MapEntry(key, value is ObjectId ? value.oid : value))).toList()), headers: _headers);
    } catch (error, stackTrace) {
      print('Medicine category list failed: $error');
      print(stackTrace);
      return _error(error);
    }
  }

  Future<Response> create(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final name = body['name']?.toString().trim() ?? '';
      if (name.isEmpty) return Response.badRequest(body: jsonEncode({'error': 'name is required'}), headers: _headers);
      final collection = await DatabaseService.getCollection('medicine_categories');
      if (await collection.findOne(where.eq('name', name)) != null) {
        return Response(409, body: jsonEncode({'error': 'Category already exists'}), headers: _headers);
      }
      final doc = <String, dynamic>{
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      };
      final result = await collection.insertOne(doc);
      final saved = result.document ?? doc;
      return Response(201, body: jsonEncode(jsonSafe(saved)), headers: _headers);
    } catch (error, stackTrace) {
      print('Medicine category create failed: $error');
      print(stackTrace);
      return _error(error);
    }
  }

  Response _error(Object error) => Response.internalServerError(body: jsonEncode({'error': error.toString()}), headers: _headers);
}
