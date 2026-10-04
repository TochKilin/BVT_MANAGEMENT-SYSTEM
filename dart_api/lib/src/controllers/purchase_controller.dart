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
        final productType = input['product_type']?.toString() ?? 'medicine';
        final qty = input['quantity'];
        final price = input['purchase_price'];
        if (!['medicine', 'vaccine'].contains(productType) ||
            qty is! num || qty <= 0 || price is! num || price < 0) {
          return Response.badRequest(body: jsonEncode({'error': 'Each item needs a valid type, quantity, and purchase_price'}), headers: _headers);
        }
        if (productType == 'medicine') {
          final medicineId = _id(input['medicine_id']);
          if (medicineId == null) return Response.badRequest(body: jsonEncode({'error': 'Valid medicine_id is required'}), headers: _headers);
          final medicines = await DatabaseService.getCollection('medicines');
          final medicine = await medicines.findOne(where.id(medicineId));
          if (medicine == null) return Response.badRequest(body: jsonEncode({'error': 'Medicine not found'}), headers: _headers);
          final unit = input['unit']?.toString().trim().isNotEmpty == true
              ? input['unit'].toString().trim()
              : medicine['unit']?.toString() ?? '';
          items.add({'product_type': productType, 'medicine_id': medicineId, 'medicine_name': medicine['name'], 'product_name': medicine['name'], 'quantity': qty, 'purchase_price': price, 'unit': unit});
          final batches = (medicine['batches'] as List? ?? const []).toList();
          batches.add({
            '_id': ObjectId(),
            'batch_number': 'PO-${DateTime.now().millisecondsSinceEpoch}',
            'manufacture_date': DateTime.now().toIso8601String(),
            'expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
            'received_at': DateTime.now().toIso8601String(),
            'quantity': qty,
            'unit': unit,
            'purchase_price': price,
            'selling_price': medicine['selling_price'] ?? 0,
            'supplier_id': supplierId,
          });
          await medicines.updateOne(where.id(medicineId), {
            r'$set': {'batches': batches, 'unit': unit, 'updated_at': DateTime.now().toIso8601String()},
          });
        } else {
          final productName = input['product_name']?.toString().trim() ?? '';
          if (productName.isEmpty) return Response.badRequest(body: jsonEncode({'error': 'Vaccine name is required'}), headers: _headers);
          final unit = input['unit']?.toString().trim() ?? '';
          if (unit.isEmpty) return Response.badRequest(body: jsonEncode({'error': 'Vaccine unit is required'}), headers: _headers);
          items.add({'product_type': productType, 'product_name': productName, 'vaccine_name': productName, 'quantity': qty, 'purchase_price': price, 'unit': unit, 'image': input['image']?.toString() ?? ''});
        }
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

  Future<Response> updateItemImage(Request request, String id, String rawIndex) async {
    try {
      final purchaseId = _id(id);
      final index = int.tryParse(rawIndex);
      if (purchaseId == null || index == null || index < 0) {
        return Response.badRequest(body: jsonEncode({'error': 'Invalid purchase item'}), headers: _headers);
      }
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final image = body['image']?.toString() ?? '';
      final collection = await DatabaseService.getCollection('purchases');
      final purchase = await collection.findOne(where.id(purchaseId));
      if (purchase == null) return Response.notFound(jsonEncode({'error': 'Purchase not found'}), headers: _headers);
      final items = (purchase['items'] as List? ?? const []).map((item) => Map<String, dynamic>.from(item as Map)).toList();
      if (index >= items.length || items[index]['product_type']?.toString() != 'vaccine') {
        return Response.badRequest(body: jsonEncode({'error': 'Vaccine item not found'}), headers: _headers);
      }
      items[index]['image'] = image;
      await collection.updateOne(where.id(purchaseId), {'\$set': {'items': items}});
      return Response.ok(jsonEncode({'success': true}), headers: _headers);
    } catch (error) {
      return _error(error);
    }
  }

  ObjectId? _id(dynamic value) {
    try { return ObjectId.fromHexString(value.toString()); } catch (_) { return null; }
  }

  Response _error(Object error) => Response.internalServerError(body: jsonEncode({'error': error.toString()}), headers: _headers);
}
