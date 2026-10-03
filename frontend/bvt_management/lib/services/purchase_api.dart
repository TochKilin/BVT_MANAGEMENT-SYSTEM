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

  static Future<void> createInboundPurchase({
    required String supplierId,
    required String productType,
    required String productName,
    String? medicineId,
    required int quantity,
    required double purchasePrice,
    String unit = '',
    String image = '',
  }) async {
    final response = await http.post(
      Uri.parse('${VetApi.baseUrl}/api/v1/purchases'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'supplier_id': supplierId,
        'items': [{
          'product_type': productType,
          if (medicineId != null) 'medicine_id': medicineId,
          'product_name': productName,
          'quantity': quantity,
          'purchase_price': purchasePrice,
          'unit': unit,
          'image': image,
        }],
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(response.body, response.statusCode));
    }
    if (productType == 'vaccine' && image.isNotEmpty) {
      try {
        final saved = jsonDecode(response.body) as Map<String, dynamic>;
        final savedItems = (saved['items'] as List? ?? const []).whereType<Map>();
        final imageWasSaved = savedItems.any(
          (item) => item['product_type']?.toString() == 'vaccine' &&
              item['image']?.toString().isNotEmpty == true,
        );
        if (!imageWasSaved) {
          throw ApiException(
            'រូបមិនបានរក្សាទុកទេ។ សូម restart API server និងបើក app ឡើងវិញ។',
          );
        }
      } on ApiException {
        rethrow;
      } catch (_) {
        throw ApiException('មិនអាចផ្ទៀងផ្ទាត់ការរក្សាទុករូបបានទេ។ សូម restart API server។');
      }
    }
  }

  static Future<void> updateVaccineImage({
    required String purchaseId,
    required int itemIndex,
    required String image,
  }) async {
    final response = await http.put(
      Uri.parse('${VetApi.baseUrl}/api/v1/purchases/$purchaseId/items/$itemIndex/image'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'image': image}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(response.body, response.statusCode));
    }
  }

  static String _message(String body, int status) {
    try { return (jsonDecode(body) as Map<String, dynamic>)['error']?.toString() ?? 'Server error ($status)'; }
    catch (_) { return 'Server error ($status)'; }
  }
}
