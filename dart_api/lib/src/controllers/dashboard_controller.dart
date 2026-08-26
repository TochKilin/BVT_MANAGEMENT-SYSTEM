import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';

import '../config/database.dart';

class DashboardController {
  Future<Response> summary(Request request) async {
    try {
      final owners = await DatabaseService.getCollection('owners');
      final medicines = await DatabaseService.getCollection('medicines');
      final vaccinations = await DatabaseService.getCollection('vaccinations');
      final appointments = await DatabaseService.getCollection('appointments');
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrow = todayStart.add(const Duration(days: 1));
      final medicineList = await medicines.find().toList();
      final lowStock = medicineList.where((medicine) {
        final batches = medicine['batches'] as List? ?? const [];
        final quantity = batches.fold<int>(0, (sum, batch) => sum + ((batch as Map)['quantity'] as num? ?? 0).toInt());
        return quantity <= 10;
      }).length;
      final dueVaccines = (await vaccinations.find(where.gte('next_due_at', now.toIso8601String()).lte('next_due_at', now.add(const Duration(days: 30)).toIso8601String())).toList()).length;
      final todayAppointments = (await appointments.find(where.gte('scheduled_at', todayStart.toIso8601String()).lt('scheduled_at', tomorrow.toIso8601String())).toList()).length;
      final ownerList = await owners.find().toList();
      final animalCount = ownerList.fold<int>(0, (sum, owner) => sum + ((owner['animals'] as List?)?.length ?? 0));
      return Response.ok(jsonEncode({
        'animal_count': animalCount, 'medicine_count': medicineList.length, 'low_stock_count': lowStock,
        'vaccines_due_30_days': dueVaccines, 'today_appointments': todayAppointments,
      }), headers: {'content-type': 'application/json'});
    } catch (error) {
      return Response.internalServerError(body: jsonEncode({'error': error.toString()}), headers: {'content-type': 'application/json'});
    }
  }
}
