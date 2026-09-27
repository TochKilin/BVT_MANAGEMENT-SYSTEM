import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';
import '../utils/json_utils.dart';

class SalesController {
  static const _headers = {'content-type': 'application/json'};

  Future<Response> create(Request request) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final requested = (body['items'] as List? ?? const [])
          .whereType<Map>()
          .toList();
      if (requested.isEmpty) return _bad('Cart is empty');

      final medicines = await DatabaseService.getCollection('medicines');
      final prepared = <Map<String, dynamic>>[];
      final updates = <String, Map<String, dynamic>>{};
      var total = 0.0;
      for (final item in requested) {
        final medicineId = _parseId(item['medicine_id']);
        final batchId = _parseId(item['batch_id']);
        final quantity = item['quantity'];
        if (medicineId == null ||
            batchId == null ||
            quantity is! num ||
            quantity <= 0 ||
            quantity != quantity.toInt()) {
          return _bad('Each item needs a valid medicine, batch, and quantity');
        }
        final key = medicineId.oid;
        final medicine =
            updates[key]?['medicine'] as Map<String, dynamic>? ??
            await medicines.findOne(where.id(medicineId));
        if (medicine == null) return _bad('Medicine not found');
        final batches =
            (updates[key]?['batches'] as List<Map<String, dynamic>>?) ??
            (medicine['batches'] as List? ?? const [])
                .whereType<Map>()
                .map((b) => Map<String, dynamic>.from(b))
                .toList();
        final index = batches.indexWhere((b) => _sameId(b['_id'], batchId));
        if (index < 0) return _bad('Medicine batch not found');
        final batch = batches[index];
        final available = (batch['quantity'] as num? ?? 0).toInt();
        if (available < quantity.toInt()) {
          return _bad('Insufficient stock for ${medicine['name']}');
        }
        final unitPrice =
            (batch['selling_price'] as num? ??
                    medicine['selling_price'] as num? ??
                    0)
                .toDouble();
        batch['quantity'] = available - quantity.toInt();
        updates[key] = {'medicine': medicine, 'batches': batches};
        final lineTotal = unitPrice * quantity;
        total += lineTotal;
        prepared.add({
          'medicine_id': medicineId,
          'batch_id': batchId,
          'medicine_name': medicine['name']?.toString() ?? '',
          'batch_number': batch['batch_number']?.toString() ?? '',
          'quantity': quantity.toInt(),
          'unit_price': unitPrice,
          'line_total': lineTotal,
        });
      }

      // Validate the complete cart before writing stock changes.
      for (final update in updates.values) {
        final medicine = update['medicine'] as Map<String, dynamic>;
        await medicines.updateOne(where.id(medicine['_id'] as ObjectId), {
          '\$set': {
            'batches': update['batches'],
            'updated_at': DateTime.now().toIso8601String(),
          },
        });
      }

      final sale = <String, dynamic>{
        'sale_number': 'SO-${DateTime.now().millisecondsSinceEpoch}',
        'items': prepared,
        'subtotal': total,
        'discount': 0,
        'tax': 0,
        'total': total,
        'created_at': DateTime.now().toIso8601String(),
      };
      final result = await (await DatabaseService.getCollection(
        'sales',
      )).insertOne(sale);
      return Response(
        201,
        body: jsonEncode(jsonSafe(result.document ?? sale)),
        headers: _headers,
      );
    } catch (error) {
      return Response.internalServerError(
        body: jsonEncode({'error': error.toString()}),
        headers: _headers,
      );
    }
  }

  Response _bad(String message) =>
      Response(400, body: jsonEncode({'error': message}), headers: _headers);

  ObjectId? _parseId(dynamic value) {
    try {
      return ObjectId.fromHexString(value.toString());
    } catch (_) {
      return null;
    }
  }

  bool _sameId(dynamic value, ObjectId id) =>
      value is ObjectId ? value == id : value?.toString() == id.oid;
}
