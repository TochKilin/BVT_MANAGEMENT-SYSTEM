import 'dart:convert';
import 'package:http/http.dart' as http;
import 'vet_api.dart' show VetApi, ApiException;

class MedicineApi {
  MedicineApi._();

  static Future<List<Map<String, dynamic>>> getMedicines() async {
    final res = await http.get(Uri.parse('${VetApi.baseUrl}/api/v1/medicines'));
    if (res.statusCode != 200)
      throw ApiException(_msg(res.body, res.statusCode));
    return (jsonDecode(res.body) as List)
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getCategories() async {
    final res = await http.get(
      Uri.parse('${VetApi.baseUrl}/api/v1/medicine-categories'),
    );
    if (res.statusCode != 200)
      throw ApiException(_msg(res.body, res.statusCode));
    return (jsonDecode(res.body) as List)
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> createCategory(String name) async {
    final res = await http.post(
      Uri.parse('${VetApi.baseUrl}/api/v1/medicine-categories'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'name': name.trim()}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300)
      throw ApiException(_msg(res.body, res.statusCode));
  }

  static Future<Map<String, dynamic>> createMedicine({
    required String name,
    String genericName = '',
    required String category,
    String manufacturer = '',
    String dosageForm = '',
    String description = '',
    String unit = 'Bottle',
    String barcode = '',
    required double sellingPrice,
    String image = '',
    required int initialQuantity,
    required double purchasePrice,
    String? supplierId,
  }) async {
    final res = await http.post(
      Uri.parse('${VetApi.baseUrl}/api/v1/medicines'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'name': name.trim(),
        'generic_name': genericName.trim(),
        'category': category.trim(),
        'manufacturer': manufacturer.trim(),
        'dosage_form': dosageForm.trim(),
        'description': description.trim(),
        'unit': unit.trim(),
        'barcode': barcode.trim(),
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'image': image,
        'batches': [
          {
            'batch_number': 'INITIAL-${DateTime.now().millisecondsSinceEpoch}',
            'manufacture_date': DateTime.now().toIso8601String(),
            'expiry_date': DateTime.now()
                .add(const Duration(days: 365))
                .toIso8601String(),
            'quantity': initialQuantity,
            'purchase_price': purchasePrice,
            'selling_price': sellingPrice,
            'received_at': DateTime.now().toIso8601String(),
            if (supplierId != null && supplierId.isNotEmpty)
              'supplier_id': supplierId,
          },
        ],
      }),
    );
    if (res.statusCode == 409) throw ApiException('Vanarity have already');
    if (res.statusCode < 200 || res.statusCode >= 300)
      throw ApiException(_msg(res.body, res.statusCode));
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(decoded['data'] ?? {});
  }

  static Future<void> updateMedicine(
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('${VetApi.baseUrl}/api/v1/medicines/$id'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(data),
    );
    if (res.statusCode < 200 || res.statusCode >= 300)
      throw ApiException(_msg(res.body, res.statusCode));
  }

  static Future<void> addBatch({
    required String medicineId,
    required int quantity,
    required double purchasePrice,
    required double sellingPrice,
    String? supplierId,
    DateTime? expiryDate,
  }) async {
    final res = await http.post(
      Uri.parse('${VetApi.baseUrl}/api/v1/medicines/$medicineId/batches'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'batch_number': 'B-${DateTime.now().millisecondsSinceEpoch}',
        'manufacture_date': DateTime.now().toIso8601String(),
        'expiry_date':
            (expiryDate ?? DateTime.now().add(const Duration(days: 365)))
                .toIso8601String(),
        'quantity': quantity,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'received_at': DateTime.now().toIso8601String(),
        if (supplierId != null && supplierId.isNotEmpty)
          'supplier_id': supplierId,
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300)
      throw ApiException(_msg(res.body, res.statusCode));
  }

  static Future<void> stockOut({
    required String medicineId,
    required int quantity,
  }) async {
    final res = await http.post(
      Uri.parse('${VetApi.baseUrl}/api/v1/medicines/$medicineId/stock-out'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'quantity': quantity}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_msg(res.body, res.statusCode));
    }
  }

  static Future<void> deleteMedicine(String id) async {
    final res = await http.delete(
      Uri.parse('${VetApi.baseUrl}/api/v1/medicines/$id'),
    );
    if (res.statusCode < 200 || res.statusCode >= 300)
      throw ApiException(_msg(res.body, res.statusCode));
  }

  static int quantityOf(Map<String, dynamic> medicine) {
    final batches = (medicine['batches'] as List? ?? const []).cast<Map>();
    return batches.fold<int>(
      0,
      (sum, b) => sum + ((b['quantity'] as num? ?? 0).toInt()),
    );
  }

  static bool isLowStock(Map<String, dynamic> medicine) =>
      quantityOf(medicine) <= 10;

  static String? latestSupplierId(Map<String, dynamic> medicine) {
    final batches = (medicine['batches'] as List? ?? const []).cast<Map>();
    if (batches.isEmpty) return null;
    final sorted = [...batches]
      ..sort((a, b) {
        final da =
            DateTime.tryParse(a['received_at']?.toString() ?? '') ??
            DateTime(2000);
        final db =
            DateTime.tryParse(b['received_at']?.toString() ?? '') ??
            DateTime(2000);
        return db.compareTo(da);
      });
    final id = sorted.first['supplier_id']?.toString();
    return (id == null || id.isEmpty) ? null : id;
  }

  /// category
  static String categoryName(Map<String, dynamic> medicine) {
    final category = medicine['category'];
    if (category == null) return '';
    if (category is Map) return category['name']?.toString() ?? '';
    return category.toString();
  }

  static String _msg(String body, int status) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['error']?.toString() ??
          'Server error ($status)';
    } catch (_) {
      return 'Server error ($status)';
    }
  }
}
