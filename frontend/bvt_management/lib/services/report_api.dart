import 'dart:convert';

import 'package:http/http.dart' as http;
import 'vet_api.dart';

class ReportApi {
  static Future<Map<String, dynamic>> getSummary({int days = 30}) async {
    final uri = Uri.parse(
      '${VetApi.baseUrl}/api/v1/reports/summary',
    ).replace(queryParameters: {'days': '$days'});
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      try {
        throw ApiException(
          (jsonDecode(response.body) as Map)['error']?.toString() ??
              'Server error (${response.statusCode})',
        );
      } catch (error) {
        if (error is ApiException) rethrow;
        throw ApiException('Server error (${response.statusCode})');
      }
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }
}
