import 'dart:convert';
import 'package:http/http.dart' as http;
import 'vet_api.dart' show VetApi, ApiException;

class PrescriptionApi {
  static Future<List<Map<String, dynamic>>> getAll() async {
    final res = await http.get(Uri.parse('${VetApi.baseUrl}/api/v1/prescriptions'));
    if (res.statusCode != 200) throw ApiException(_error(res.body, res.statusCode));
    return (jsonDecode(res.body) as List).cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${VetApi.baseUrl}/api/v1/prescriptions'), headers: const {'content-type': 'application/json'}, body: jsonEncode(data));
    if (res.statusCode < 200 || res.statusCode >= 300) throw ApiException(_error(res.body, res.statusCode));
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  static String _error(String body, int status) {
    try { return (jsonDecode(body) as Map)['error']?.toString() ?? 'Server error ($status)'; } catch (_) { return 'Server error ($status)'; }
  }
}
