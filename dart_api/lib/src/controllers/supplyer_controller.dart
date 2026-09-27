import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';
import '../models/supplyer.dart';

class SupplierController {
  static const _headers = {'content-type': 'application/json'};

  Future<Response> getAll(Request request) async {
    try {
      final records = await (await DatabaseService.getCollection('suppliers'))
          .find(where.sortBy('name'))
          .toList();
      return Response.ok(jsonEncode(records.map(_json).toList()), headers: _headers);
    } catch (error) {
      return _error(error);
    }
  }

  Future<Response> getById(Request request, String id) async {
    try {
      final objectId = _parseId(id);
      if (objectId == null) {
        return Response.badRequest(body: jsonEncode({'error': 'Invalid supplier id'}), headers: _headers);
      }
      final record = await (await DatabaseService.getCollection('suppliers')).findOne(where.id(objectId));
      if (record == null) {
        return Response.notFound(jsonEncode({'error': 'Supplier not found'}), headers: _headers);
      }
      return Response.ok(jsonEncode(_json(record)), headers: _headers);
    } catch (error) {
      return _error(error);
    }
  }

  Future<Response> create(Request request) async {
    try {
      final supplier = SupplierModel.fromMap(await _body(request));
      if (supplier.name.isEmpty || supplier.phone.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'name and phone are required'}),
          headers: _headers,
        );
      }


      final existing = await (await DatabaseService.getCollection('suppliers')).findOne(
        where.eq('name', supplier.name),
      );
      if (existing != null) {
        return Response(409, body: jsonEncode({'error': 'supplier heve already'}), headers: _headers);
      }

      final result = await (await DatabaseService.getCollection('suppliers')).insertOne(supplier.toMap());
      return Response(201, body: jsonEncode({'data': _json(result.document ?? supplier.toMap())}), headers: _headers);
    } catch (error) {
      return _error(error);
    }
  }

  Future<Response> update(Request request, String id) async {
    try {
      final objectId = _parseId(id);
      if (objectId == null) {
        return Response.badRequest(body: jsonEncode({'error': 'Invalid supplier id'}), headers: _headers);
      }
      final body = await _body(request);
      body.remove('_id');
      body['updated_at'] = DateTime.now().toIso8601String();

      final result = await (await DatabaseService.getCollection('suppliers'))
          .updateOne(where.id(objectId), {r'$set': body});
      if (result.nModified == 0) {
        return Response.notFound(jsonEncode({'error': 'Supplier not found'}), headers: _headers);
      }
      return Response.ok(jsonEncode({'message': 'Supplier updated'}), headers: _headers);
    } catch (error) {
      return _error(error);
    }
  }

  Future<Response> delete(Request request, String id) async {
    try {
      final objectId = _parseId(id);
      if (objectId == null) {
        return Response.badRequest(body: jsonEncode({'error': 'Invalid supplier id'}), headers: _headers);
      }


      final medicines = await DatabaseService.getCollection('medicines');
      final linked = await medicines.findOne(where.eq('batches.supplier_id', objectId));
      if (linked != null) {
        return Response(
          409,
          body: jsonEncode({
            'error': 'can not delete cuz your supplyer connect with the sale'
          }),
          headers: _headers,
        );
      }

      final result = await (await DatabaseService.getCollection('suppliers')).deleteOne(where.id(objectId));
      if (result.nRemoved == 0) {
        return Response.notFound(jsonEncode({'error': 'Supplier not found'}), headers: _headers);
      }
      return Response.ok(jsonEncode({'message': 'Supplier deleted'}), headers: _headers);
    } catch (error) {
      return _error(error);
    }
  }


  Future<Response> getMedicinesBySupplier(Request request, String id) async {
    try {
      final objectId = _parseId(id);
      if (objectId == null) {
        return Response.badRequest(body: jsonEncode({'error': 'Invalid supplier id'}), headers: _headers);
      }

      final medicines = await DatabaseService.getCollection('medicines');
      final records = await medicines.find(where.eq('batches.supplier_id', objectId)).toList();

      // សម្រាប់ medicine នីមួយៗ គណនាតែ batch ដែលជាកម្មសិទ្ធិ supplier នេះប៉ុណ្ណោះ
      final result = records.map((medicine) {
        final allBatches = (medicine['batches'] as List? ?? const []).cast<Map>();
        final supplierBatches = allBatches.where((b) {
          final bSupplierId = b['supplier_id'];
          return bSupplierId != null && bSupplierId.toString() == objectId.toHexString();
        }).toList();

        final totalQuantity = supplierBatches.fold<int>(
          0,
          (sum, b) => sum + ((b['quantity'] as num? ?? 0).toInt()),
        );
        final totalValue = supplierBatches.fold<double>(
          0,
          (sum, b) => sum + ((b['quantity'] as num? ?? 0) * (b['unit_cost'] as num? ?? 0)),
        );

        return {
          '_id': medicine['_id'] is ObjectId ? (medicine['_id'] as ObjectId).oid : medicine['_id'],
          'name': medicine['name'],
          'batch_count': supplierBatches.length,
          'total_quantity': totalQuantity,
          'total_value': totalValue,
        };
      }).toList();

      return Response.ok(jsonEncode(result), headers: _headers);
    } catch (error) {
      return _error(error);
    }
  }


  Future<Response> getSummary(Request request, String id) async {
    try {
      final objectId = _parseId(id);
      if (objectId == null) {
        return Response.badRequest(body: jsonEncode({'error': 'Invalid supplier id'}), headers: _headers);
      }

      final medicines = await DatabaseService.getCollection('medicines');
      final records = await medicines.find(where.eq('batches.supplier_id', objectId)).toList();

      int medicineCount = records.length;
      int totalBatches = 0;
      double totalValue = 0;

      for (final medicine in records) {
        final allBatches = (medicine['batches'] as List? ?? const []).cast<Map>();
        for (final b in allBatches) {
          final bSupplierId = b['supplier_id'];
          if (bSupplierId != null && bSupplierId.toString() == objectId.toHexString()) {
            totalBatches++;
            totalValue += (b['quantity'] as num? ?? 0) * (b['unit_cost'] as num? ?? 0);
          }
        }
      }

      return Response.ok(
        jsonEncode({
          'medicine_count': medicineCount,
          'total_batches': totalBatches,
          'total_purchase_value': totalValue,
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

  Future<Map<String, dynamic>> _body(Request request) async =>
      jsonDecode(await request.readAsString()) as Map<String, dynamic>;

  Response _error(Object error) =>
      Response.internalServerError(body: jsonEncode({'error': error.toString()}), headers: _headers);

  Map<String, dynamic> _json(Map<String, dynamic> item) =>
      item.map((key, value) => MapEntry(key, value is ObjectId ? value.oid : value));
}