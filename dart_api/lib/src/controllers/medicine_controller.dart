import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../config/database.dart';
import '../models/medicine_model.dart';
import '../utils/json_utils.dart';

class MedicineController {
  static const _headers = {'content-type': 'application/json'};

  Future<Response> getAll(Request request) async {
    try {
      final collection = await DatabaseService.getCollection('medicines');
      final data = await collection.find().toList();
      final list = data
          .map((m) => jsonSafe(MedicineModel.fromMap(m).toMap()))
          .toList();
      return Response.ok(jsonEncode(list), headers: _headers);
    } catch (error) {
      return _error(error);
    }
  }

  Future<Response> getById(Request request, String id) async {
    try {
      final objectId = _parseId(id);
      if (objectId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid medicine id'}),
          headers: _headers,
        );
      }
      final collection = await DatabaseService.getCollection('medicines');
      final record = await collection.findOne(where.id(objectId));
      if (record == null) {
        return Response.notFound(
          jsonEncode({'error': 'Medicine not found'}),
          headers: _headers,
        );
      }
      return Response.ok(
        jsonEncode(jsonSafe(MedicineModel.fromMap(record).toMap())),
        headers: _headers,
      );
    } catch (error) {
      return _error(error);
    }
  }

  Future<Response> create(Request request) async {
    try {
      final payload = await request.readAsString();
      if (payload.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Request body cannot be empty'}),
          headers: _headers,
        );
      }

      final body = jsonDecode(payload) as Map<String, dynamic>;
      final medicine = MedicineModel.fromMap(body);

      if (medicine.name.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'name is required'}),
          headers: _headers,
        );
      }

      final collection = await DatabaseService.getCollection('medicines');

      // duplicate
      final existing = await collection.findOne(
        where.eq('name', medicine.name),
      );
      if (existing != null) {
        return Response(
          409,
          body: jsonEncode({'error': 'Medicine have already'}),
          headers: _headers,
        );
      }

      await collection.insertOne(medicine.toMap());

      return Response(
        201,
        body: jsonEncode({
          'message': 'Medicine added successfully',
          'data': jsonSafe(medicine.toMap()),
        }),
        headers: _headers,
      );
    } catch (error, stackTrace) {
      print('Medicine Create Error: $error');
      print(stackTrace);
      return _error(error);
    }
  }

  Future<Response> update(Request request, String id) async {
    try {
      final objectId = _parseId(id);
      if (objectId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid medicine id'}),
          headers: _headers,
        );
      }
      final payload = await request.readAsString();
      if (payload.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Request body cannot be empty'}),
          headers: _headers,
        );
      }
      final body = jsonDecode(payload) as Map<String, dynamic>;
      body.remove('_id');

      final collection = await DatabaseService.getCollection('medicines');
      final result = await collection.updateOne(where.id(objectId), {
        r'$set': body,
      });
      if (result.nModified == 0) {
        return Response.notFound(
          jsonEncode({'error': 'Medicine not found'}),
          headers: _headers,
        );
      }
      return Response.ok(
        jsonEncode({'message': 'Medicine updated successfully'}),
        headers: _headers,
      );
    } catch (error) {
      return _error(error);
    }
  }

  Future<Response> delete(Request request, String id) async {
    try {
      final objectId = _parseId(id);
      if (objectId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid medicine id'}),
          headers: _headers,
        );
      }
      final collection = await DatabaseService.getCollection('medicines');
      final result = await collection.deleteOne(where.id(objectId));
      if (result.nRemoved == 0) {
        return Response.notFound(
          jsonEncode({'error': 'Medicine not found'}),
          headers: _headers,
        );
      }
      return Response.ok(
        jsonEncode({'message': 'Medicine deleted successfully'}),
        headers: _headers,
      );
    } catch (error) {
      return _error(error);
    }
  }

  Future<Response> addBatch(Request request, String id) async {
    try {
      final objectId = _parseId(id);
      if (objectId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid medicine id'}),
          headers: _headers,
        );
      }
      final payload = await request.readAsString();
      if (payload.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Request body cannot be empty'}),
          headers: _headers,
        );
      }
      final body = jsonDecode(payload) as Map<String, dynamic>;

      // quantity
      final quantity = body['quantity'];
      if (quantity == null || (quantity is num && quantity <= 0)) {
        return Response.badRequest(
          body: jsonEncode({'error': 'quantity more than 0'}),
          headers: _headers,
        );
      }

      // supplier_id from String ទៅ ObjectId 
      if (body['supplier_id'] != null &&
          body['supplier_id'].toString().trim().isNotEmpty) {
        try {
          body['supplier_id'] = ObjectId.fromHexString(
            body['supplier_id'].toString(),
          );
        } catch (_) {
          return Response.badRequest(
            body: jsonEncode({'error': 'Invalid supplier_id'}),
            headers: _headers,
          );
        }
      } else {
        body.remove('supplier_id');
      }

      body['batch_number'] ??= 'B-${DateTime.now().millisecondsSinceEpoch}';
      body['manufacture_date'] ??= DateTime.now().toIso8601String();
      body['expiry_date'] ??= DateTime.now()
          .add(const Duration(days: 365))
          .toIso8601String();
      body['received_at'] ??= DateTime.now().toIso8601String();
      body['purchase_price'] ??= 0;
      body['selling_price'] ??= 0;

      final collection = await DatabaseService.getCollection('medicines');
      final result = await collection.updateOne(where.id(objectId), {
        r'$push': {'batches': body},
        r'$set': {'updated_at': DateTime.now().toIso8601String()},
      });
      if (result.nModified == 0) {
        return Response.notFound(
          jsonEncode({'error': 'Medicine not found'}),
          headers: _headers,
        );
      }
      return Response.ok(
        jsonEncode({'message': 'Batch added successfully'}),
        headers: _headers,
      );
    } catch (error) {
      return _error(error);
    }
  }

  Future<Response> stockOut(Request request, String id) async {
    try {
      final objectId = _parseId(id);
      if (objectId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid medicine id'}),
          headers: _headers,
        );
      }
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final quantity = int.tryParse(body['quantity']?.toString() ?? '');
      if (quantity == null || quantity <= 0) {
        return Response.badRequest(
          body: jsonEncode({'error': 'quantity must be greater than 0'}),
          headers: _headers,
        );
      }

      final collection = await DatabaseService.getCollection('medicines');
      final medicine = await collection.findOne(where.id(objectId));
      if (medicine == null) {
        return Response.notFound(
          jsonEncode({'error': 'Medicine not found'}),
          headers: _headers,
        );
      }
      final batches = ((medicine['batches'] as List?) ?? const [])
          .whereType<Map>()
          .map((batch) => Map<String, dynamic>.from(batch))
          .toList();
      bool isExpired(Map<String, dynamic> batch) {
        final expiry = DateTime.tryParse(
          batch['expiry_date']?.toString() ?? '',
        );
        return expiry != null && expiry.isBefore(DateTime.now());
      }

      final available = batches
          .where((batch) => !isExpired(batch))
          .fold<int>(
            0,
            (sum, batch) => sum + ((batch['quantity'] as num?)?.toInt() ?? 0),
          );
      if (available < quantity) {
        return Response(
          409,
          body: jsonEncode({
            'error': 'Insufficient stock. Available: $available',
          }),
          headers: _headers,
        );
      }

      final order = List<int>.generate(batches.length, (index) => index)
        ..sort((a, b) {
          final aExpiry =
              DateTime.tryParse(batches[a]['expiry_date']?.toString() ?? '') ??
              DateTime(9999);
          final bExpiry =
              DateTime.tryParse(batches[b]['expiry_date']?.toString() ?? '') ??
              DateTime(9999);
          return aExpiry.compareTo(bExpiry);
        });
      var remaining = quantity;
      for (final index in order) {
        if (remaining == 0) break;
        if (isExpired(batches[index])) continue;
        final current = (batches[index]['quantity'] as num?)?.toInt() ?? 0;
        final taken = current < remaining ? current : remaining;
        batches[index]['quantity'] = current - taken;
        remaining -= taken;
      }
      await collection.updateOne(where.id(objectId), {
        r'$set': {
          'batches': batches,
          'updated_at': DateTime.now().toIso8601String(),
        },
      });
      return Response.ok(
        jsonEncode({
          'message': 'Stock issued successfully',
          'quantity': quantity,
        }),
        headers: _headers,
      );
    } catch (error) {
      return _error(error);
    }
  }

  ObjectId? _parseId(String id) {
    try {
      return ObjectId.fromHexString(id);
    } catch (_) {
      return null;
    }
  }

  Response _error(Object error) => Response.internalServerError(
    body: jsonEncode({'error': error.toString()}),
    headers: _headers,
  );
}
