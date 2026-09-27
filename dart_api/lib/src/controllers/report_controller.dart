import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../config/database.dart';

class ReportController {
  Future<Response> summary(Request request) async {
    const headers = {'content-type': 'application/json'};
    try {
      final days =
          int.tryParse(request.url.queryParameters['days'] ?? '') ?? 30;
      final safeDays = days.clamp(1, 366).toInt();
      final now = DateTime.now();
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: safeDays - 1));
      final sales = await (await DatabaseService.getCollection(
        'sales',
      )).find().toList();
      final purchases = await (await DatabaseService.getCollection(
        'purchases',
      )).find().toList();
      final medicines = await (await DatabaseService.getCollection(
        'medicines',
      )).find().toList();

      DateTime? dateOf(Map record) => DateTime.tryParse(
        (record['created_at'] ?? record['date'] ?? '').toString(),
      );
      bool inRange(Map record) {
        final date = dateOf(record);
        return date != null && !date.isBefore(start) && !date.isAfter(now);
      }

      final periodSales = sales.where(inRange).toList();
      final periodPurchases = purchases.where(inRange).toList();
      double amount(Map record) =>
          (record['total'] as num? ?? record['total_amount'] as num? ?? 0)
              .toDouble();
      final daily = <String, double>{};
      for (var offset = 0; offset < safeDays; offset++) {
        final day = start.add(Duration(days: offset));
        final key =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        daily[key] = 0;
      }
      for (final sale in periodSales) {
        final date = dateOf(sale);
        if (date == null) continue;
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        if (daily.containsKey(key)) daily[key] = daily[key]! + amount(sale);
      }

      var stockUnits = 0;
      var lowStock = 0;
      var expiredBatches = 0;
      for (final medicine in medicines) {
        final batches = (medicine['batches'] as List? ?? const [])
            .whereType<Map>();
        var medicineUnits = 0;
        for (final batch in batches) {
          final quantity = (batch['quantity'] as num? ?? 0).toInt();
          medicineUnits += quantity;
          final expiry = DateTime.tryParse(
            (batch['expiry_date'] ?? '').toString(),
          );
          if (expiry != null && expiry.isBefore(now) && quantity > 0) {
            expiredBatches++;
          }
        }
        stockUnits += medicineUnits;
        if (medicineUnits <= 10) lowStock++;
      }

      return Response.ok(
        jsonEncode({
          'days': safeDays,
          'from': start.toIso8601String(),
          'to': now.toIso8601String(),
          'sales_count': periodSales.length,
          'sales_total': periodSales.fold<double>(
            0,
            (sum, sale) => sum + amount(sale),
          ),
          'purchase_count': periodPurchases.length,
          'purchase_total': periodPurchases.fold<double>(
            0,
            (sum, order) => sum + amount(order),
          ),
          'medicine_count': medicines.length,
          'stock_units': stockUnits,
          'low_stock_count': lowStock,
          'expired_batch_count': expiredBatches,
          'daily_sales': daily.entries
              .map((entry) => {'date': entry.key, 'total': entry.value})
              .toList(),
        }),
        headers: headers,
      );
    } catch (error) {
      return Response.internalServerError(
        body: jsonEncode({'error': error.toString()}),
        headers: headers,
      );
    }
  }
}
