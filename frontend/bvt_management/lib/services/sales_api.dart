import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_item.dart';
import 'vet_api.dart';

class SalesApi {
  SalesApi._();

  static Future<Map<String, dynamic>> checkout(
    List<CartItem> items, {
    required String paymentMethod,
    required double amountReceived,
  }) async {
    final response = await http.post(
      Uri.parse('${VetApi.baseUrl}/api/v1/sales'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'payment_method': paymentMethod,
        'amount_received': amountReceived,
        'items': items
            .map(
              (item) => {
                'medicine_id': item.medicineId,
                'batch_id': item.batchId,
                'quantity': item.quantity,
              },
            )
            .toList(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(response.body, response.statusCode));
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
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
