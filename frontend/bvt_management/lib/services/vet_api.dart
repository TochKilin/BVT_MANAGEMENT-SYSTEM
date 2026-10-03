import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class VetApi {
  VetApi._();
  static const _configuredBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );
  static String get baseUrl => _configuredBaseUrl.isNotEmpty
      ? _configuredBaseUrl
      : Platform.isAndroid
      ? 'http://10.0.2.2:8585'
      : 'http://127.0.0.1:8585';

  static Future<void> createPatient({
    required String ownerName,
    required String phone,
    required String animalName,
    required String species,
    required String breed,
    required String gender,
    required String weight,
    String photo = '',
  }) => _post('/api/v1/owners', {
    'name': ownerName,
    'phone': phone,
    'email': '',
    'address': '',
    'animals': [
      {
        'name': animalName,
        'species': species,
        'breed': breed,
        'gender': gender,
        'weight': double.tryParse(weight) ?? 0,
        'color': '',
        'photo': photo,
      },
    ],
  });

  static Future<List<Map<String, dynamic>>> getPatients() async {
    return _getList('/api/v1/owners');
  }

  static Future<void> updatePatient({
    required String ownerId,
    required String animalId,
    required String ownerName,
    required String phone,
    required String animalName,
    required String species,
    required String breed,
    required String gender,
    required String weight,
    required String photo,
  }) => _put('/api/v1/owners/$ownerId/animals/$animalId', {
    'name': ownerName,
    'phone': phone,
    'animal': {
      '_id': animalId,
      'name': animalName,
      'species': species,
      'breed': breed,
      'gender': gender,
      'weight': double.tryParse(weight) ?? 0,
      'photo': photo,
    },
  });

  static Future<void> deletePatient({
    required String ownerId,
    required String animalId,
  }) => _delete('/api/v1/owners/$ownerId/animals/$animalId');

  static Future<List<Map<String, dynamic>>> getMedicines() =>
      _getList('/api/v1/medicines');
  static Future<List<Map<String, dynamic>>> getVaccinations() =>
      _getList('/api/v1/vaccinations');
  static Future<List<Map<String, dynamic>>> getAppointments() =>
      _getList('/api/v1/appointments');
  static Future<List<Map<String, dynamic>>> getMedicalRecords() =>
      _getList('/api/v1/records');

  static Future<Map<String, dynamic>> createMedicalRecord({
    required String ownerId,
    required String animalId,
    required String symptoms,
    required String diagnosis,
    required String treatment,
    required List<Map<String, dynamic>> prescriptionItems,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/records'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'owner_id': ownerId,
        'animal_id': animalId,
        'symptoms': symptoms,
        'diagnosis': diagnosis,
        'treatment': treatment,
        'prescription': {'items': prescriptionItems},
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(response.body, response.statusCode));
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/dashboard/summary'),
    );
    if (response.statusCode != 200)
      throw ApiException(_message(response.body, response.statusCode));
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode != 200)
      throw ApiException(_message(response.body, response.statusCode));
    return (jsonDecode(response.body) as List)
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> createMedicine({
    required String name,
    required String category,
    required String quantity,
    required String sellingPrice,
    String unit = '',
    String image = '',
  }) => _post('/api/v1/medicines', {
    'name': name,
    'generic_name': '',
    'category': category,
    'unit': unit,
    'manufacturer': '',
    'purchase_price': 0,
    'selling_price': double.tryParse(sellingPrice) ?? 0,
    'image': image,
    'batches': [
      {
        'batch_number': 'INITIAL',
        'manufacture_date': DateTime.now().toIso8601String(),
        'expiry_date': DateTime.now()
            .add(const Duration(days: 365))
            .toIso8601String(),
        'quantity': int.tryParse(quantity) ?? 0,
        'purchase_price': 0,
        'selling_price': double.tryParse(sellingPrice) ?? 0,
      },
    ],
  });

  static Future<void> createVaccination({
    required String ownerId,
    required String animalId,
    required String vaccineName,
    String unit = '',
    required DateTime nextDueAt,
    String image = '',
  }) => _post('/api/v1/vaccinations', {
    'owner_id': ownerId,
    'animal_id': animalId,
    'vaccine_name': vaccineName,
    'unit': unit,
    'administered_at': DateTime.now().toIso8601String(),
    'next_due_at': nextDueAt.toIso8601String(),
    'image': image,
  });

  static Future<void> updateVaccination({
    required String id,
    required String ownerId,
    required String animalId,
    required String vaccineName,
    String unit = '',
    required DateTime nextDueAt,
    required String image,
  }) => _put('/api/v1/vaccinations/$id', {
    'owner_id': ownerId,
    'animal_id': animalId,
    'vaccine_name': vaccineName,
    'unit': unit,
    'next_due_at': nextDueAt.toIso8601String(),
    'image': image,
  });

  static Future<void> deleteVaccination(String id) =>
      _delete('/api/v1/vaccinations/$id');

  static Future<void> createAppointment({
    required String ownerId,
    required String animalId,
    required String reason,
    required DateTime scheduledAt,
  }) => _post('/api/v1/appointments', {
    'owner_id': ownerId,
    'animal_id': animalId,
    'reason': reason,
    'scheduled_at': scheduledAt.toIso8601String(),
  });

  static Future<void> updateAppointment({
    required String id,
    required String ownerId,
    required String animalId,
    required String reason,
    required DateTime scheduledAt,
  }) => _put('/api/v1/appointments/$id', {
    'owner_id': ownerId,
    'animal_id': animalId,
    'reason': reason,
    'scheduled_at': scheduledAt.toIso8601String(),
  });

  static Future<void> setAppointmentStatus({
    required String id,
    required String status,
  }) => _put('/api/v1/appointments/$id', {'status': status});

  static Future<void> deleteAppointment(String id) =>
      _delete('/api/v1/appointments/$id');

  static Future<void> _post(String path, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(response.body, response.statusCode));
    }
  }

  static Future<void> _put(String path, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(response.body, response.statusCode));
    }
  }

  static Future<void> _delete(String path) async {
    final response = await http.delete(Uri.parse('$baseUrl$path'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(response.body, response.statusCode));
    }
  }

  static String _message(String body, int status) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error']?.toString() ??
          'Server error ($status)';
    } catch (_) {
      return 'Server error ($status)';
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
