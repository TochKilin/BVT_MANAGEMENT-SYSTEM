import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class VetApi {
  VetApi._();

  /// Override for Android devices with --dart-define=API_URL=http://YOUR_PC_IP:8080.
  // Android emulator maps the development machine to 10.0.2.2; iOS simulator uses 127.0.0.1.
  // A physical device must use the Mac's LAN IP through --dart-define=API_URL=...
  static const _configuredBaseUrl = String.fromEnvironment('API_URL', defaultValue: '');
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
  }) => _post('/api/owners', {
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
          }
        ],
      });

  static Future<List<Map<String, dynamic>>> getPatients() async {
    return _getList('/api/owners');
  }

  static Future<List<Map<String, dynamic>>> getMedicines() => _getList('/api/medicines');
  static Future<List<Map<String, dynamic>>> getVaccinations() => _getList('/api/vaccinations');
  static Future<List<Map<String, dynamic>>> getAppointments() => _getList('/api/appointments');

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(Uri.parse('$baseUrl/api/dashboard/summary'));
    if (response.statusCode != 200) throw ApiException(_message(response.body, response.statusCode));
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode != 200) throw ApiException(_message(response.body, response.statusCode));
    return (jsonDecode(response.body) as List).cast<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Future<void> createMedicine({required String name, required String category, required String quantity, required String sellingPrice, String image = ''}) => _post('/api/medicines', {
        'name': name,
        'generic_name': '',
        'category': category,
        'manufacturer': '',
        'purchase_price': 0,
        'selling_price': double.tryParse(sellingPrice) ?? 0,
        'image': image,
        'batches': [
          {
            'batch_number': 'INITIAL',
            'manufacture_date': DateTime.now().toIso8601String(),
            'expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
            'quantity': int.tryParse(quantity) ?? 0,
            'purchase_price': 0,
            'selling_price': double.tryParse(sellingPrice) ?? 0,
          }
        ],
      });

  static Future<void> createVaccination({required String ownerId, required String animalId, required String vaccineName, required DateTime nextDueAt, String image = ''}) => _post('/api/vaccinations', {
        'owner_id': ownerId,
        'animal_id': animalId,
        'vaccine_name': vaccineName,
        'administered_at': DateTime.now().toIso8601String(),
        'next_due_at': nextDueAt.toIso8601String(),
        'image': image,
      });

  static Future<void> createAppointment({required String ownerId, required String animalId, required String reason, required DateTime scheduledAt}) => _post('/api/appointments', {
        'owner_id': ownerId,
        'animal_id': animalId,
        'reason': reason,
        'scheduled_at': scheduledAt.toIso8601String(),
      });

  static Future<void> _post(String path, Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$baseUrl$path'), headers: const {'content-type': 'application/json'}, body: jsonEncode(data));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(response.body, response.statusCode));
    }
  }

  static String _message(String body, int status) {
    try { return (jsonDecode(body) as Map<String, dynamic>)['error']?.toString() ?? 'Server error ($status)'; } catch (_) { return 'Server error ($status)'; }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
