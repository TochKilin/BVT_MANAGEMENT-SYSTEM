import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';
import '../utils/json_utils.dart';

class PurchaseController {
  static const _headers = {'content-type': 'application/json'};

  Future<Response> getAll(Request request) async {
    try {
      final records = await (await DatabaseService.getCollection('purchases'))
          .find(where.sortBy('created_at', descending: true)).toList();
      return Response.ok(jsonEncode(jsonSafe(records)), headers: _headers);
    } catch (error) {
      return _error(error);
    }
  }

  Future<Response> create(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final supplierId = _id(body['supplier_id']);
      final supplier = supplierId == null
          ? null
          : await (await DatabaseService.getCollection('suppliers')).findOne(where.id(supplierId));
      if (supplier == null) return Response.badRequest(body: jsonEncode({'error': 'Valid supplier_id is required'}), headers: _headers);
      final inputItems = (body['items'] as List? ?? const []).whereType<Map>().toList();
      if (inputItems.isEmpty) return Response.badRequest(body: jsonEncode({'error': 'At least one item is required'}), headers: _headers);

      final items = <Map<String, dynamic>>[];
      var total = 0.0;
      for (final input in inputItems) {
        final medicineId = _id(input['medicine_id']);
        final qty = input['quantity'];
        final price = input['purchase_price'];
        if (medicineId == null || qty is! num || qty <= 0 || price is! num || price < 0) {
          return Response.badRequest(body: jsonEncode({'error': 'Each item needs a valid medicine, quantity, and purchase_price'}), headers: _headers);
        }
        final medicine = await (await DatabaseService.getCollection('medicines')).findOne(where.id(medicineId));
        if (medicine == null) return Response.badRequest(body: jsonEncode({'error': 'Medicine not found'}), headers: _headers);
        items.add({'medicine_id': medicineId, 'medicine_name': medicine['name'], 'quantity': qty, 'purchase_price': price});
        total += qty * price;
      }

      final collection = await DatabaseService.getCollection('purchases');
      final order = <String, dynamic>{
        'order_number': 'PO-${DateTime.now().millisecondsSinceEpoch}',
        'supplier_id': supplierId,
        'supplier_name': supplier['name'],
        'items': items,
        'total': total,
        'status': 'ordered',
        'created_at': DateTime.now().toIso8601String(),
      };
      final result = await collection.insertOne(order);
      return Response(201, body: jsonEncode(jsonSafe(result.document ?? order)), headers: _headers);
    } catch (error) {
      return _error(error);
    }
  }

  ObjectId? _id(dynamic value) {
    try { return ObjectId.fromHexString(value.toString()); } catch (_) { return null; }
  }

  Response _error(Object error) => Response.internalServerError(body: jsonEncode({'error': error.toString()}), headers: _headers);
}
