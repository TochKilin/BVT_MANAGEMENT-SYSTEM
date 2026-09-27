import 'dart:convert';
import 'package:http/http.dart' as http;
import 'vet_api.dart';

class PurchaseApi {
  PurchaseApi._();

  static Future<List<Map<String, dynamic>>> getPurchases() async {
    final response = await http.get(Uri.parse('${VetApi.baseUrl}/api/v1/purchases'));
    if (response.statusCode != 200) throw ApiException(_message(response.body, response.statusCode));
    return (jsonDecode(response.body) as List).cast<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Future<void> createPurchase({required String supplierId, required String medicineId, required int quantity, required double purchasePrice}) async {
    final response = await http.post(
      Uri.parse('${VetApi.baseUrl}/api/v1/purchases'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'supplier_id': supplierId, 'items': [{'medicine_id': medicineId, 'quantity': quantity, 'purchase_price': purchasePrice}]}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException(_message(response.body, response.statusCode));
  }

  static String _message(String body, int status) {
    try { return (jsonDecode(body) as Map<String, dynamic>)['error']?.toString() ?? 'Server error ($status)'; }
    catch (_) { return 'Server error ($status)'; }
  }
}
