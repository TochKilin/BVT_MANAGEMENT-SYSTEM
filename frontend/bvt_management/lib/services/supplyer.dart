import 'dart:convert';
import 'package:http/http.dart' as http;
import 'vet_api.dart';

class SupplierApi {
  SupplierApi._();

  static Future<List<Map<String, dynamic>>> getSuppliers() async {
    final response = await http.get(Uri.parse('${VetApi.baseUrl}/api/v1/suppliers'));
    if (response.statusCode != 200) throw ApiException(_message(response.body, response.statusCode));
    return (jsonDecode(response.body) as List).cast<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Future<void> createSupplier({
    required String name,
    String contactPerson = '',
    required String phone,
    String email = '',
    String address = '',
    String notes = '',
  }) => _post('/api/v1/suppliers', {
        'name': name,
        'contact_person': contactPerson,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
      });

  static Future<void> updateSupplier(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${VetApi.baseUrl}/api/v1/suppliers/$id'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(response.body, response.statusCode));
    }
  }

  static Future<void> deleteSupplier(String id) async {
    final response = await http.delete(Uri.parse('${VetApi.baseUrl}/api/v1/suppliers/$id'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(response.body, response.statusCode));
    }
  }

  static Future<void> _post(String path, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${VetApi.baseUrl}$path'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(response.body, response.statusCode));
    }
  }

  static String _message(String body, int status) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error']?.toString() ?? 'Server error ($status)';
    } catch (_) {
      return 'Server error ($status)';
    }
  }
}