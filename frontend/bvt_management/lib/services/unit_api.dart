import 'dart:convert';

import 'package:http/http.dart' as http;

import 'vet_api.dart' show VetApi, ApiException;

class UnitApi {
  UnitApi._();

  static Future<List<Map<String, dynamic>>> getUnits() async {
    final response = await http.get(Uri.parse('${VetApi.baseUrl}/api/v1/units'));
    if (response.statusCode != 200) throw ApiException(_message(response.body, response.statusCode));
    return (jsonDecode(response.body) as List).cast<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Future<Map<String, dynamic>> createUnit({required String type, required String name}) async {
    final response = await http.post(Uri.parse('${VetApi.baseUrl}/api/v1/units'), headers: const {'content-type': 'application/json'}, body: jsonEncode({'type': type, 'name': name}));
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException(_message(response.body, response.statusCode));
    final created = jsonDecode(response.body) as Map;
    return Map<String, dynamic>.from(created);
  }

  static Future<void> deleteUnit(String id) async {
    final response = await http.delete(Uri.parse('${VetApi.baseUrl}/api/v1/units/$id'));
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException(_message(response.body, response.statusCode));
  }

  static String _message(String body, int status) {
    try { return (jsonDecode(body) as Map<String, dynamic>)['error']?.toString() ?? 'Server error ($status)'; }
    catch (_) { return 'Server error ($status)'; }
  }
}
