import 'package:mongo_dart/mongo_dart.dart';

class BatchModel {
  final ObjectId id;
  final String batchNumber;
  final DateTime manufactureDate;
  final DateTime expiryDate;
  final int quantity;
  final double purchasePrice;
  final double sellingPrice;

  BatchModel({
    ObjectId? id,
    required this.batchNumber,
    required this.manufactureDate,
    required this.expiryDate,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
  }) : id = id ?? ObjectId();

  factory BatchModel.fromMap(Map<String, dynamic> map) {
  
    DateTime parseDate(dynamic date) {
      if (date is DateTime) return date;
      if (date is String && date.isNotEmpty) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    ObjectId parseObjectId(dynamic id) {
      if (id is ObjectId) return id;
      if (id is String && id.isNotEmpty) {
        try {
          return ObjectId.fromHexString(id);
        } catch (_) {
          return ObjectId();
        }
      }
      return ObjectId();
    }

    return BatchModel(
      id: parseObjectId(map['_id']),
      batchNumber: map['batch_number']?.toString() ?? '',
      manufactureDate: parseDate(map['manufacture_date']),
      expiryDate: parseDate(map['expiry_date']),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'batch_number': batchNumber,
      'manufacture_date': manufactureDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
    };
  }
}

class MedicineModel {
  final ObjectId? id;
  final String name;
  final String genericName;
  final String categoryName;
  final String manufacturer;
  final double purchasePrice;
  final double sellingPrice;
  final String image;
  final List<BatchModel> batches;

  MedicineModel({
    this.id,
    required this.name,
    required this.genericName,
    required this.categoryName,
    required this.manufacturer,
    required this.purchasePrice,
    required this.sellingPrice,
    this.image = '',
    required this.batches,
  });

  factory MedicineModel.fromMap(Map<String, dynamic> map) {

    String extractCategory(dynamic category) {
      if (category is Map) {
        return category['name']?.toString() ?? '';
      } else if (category is String) {
        return category;
      }
      return '';
    }

    // 2. Parse ObjectId
    ObjectId? parseObjectId(dynamic id) {
      if (id is ObjectId) return id;
      if (id is String && id.isNotEmpty) {
        try {
          return ObjectId.fromHexString(id);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return MedicineModel(
      id: parseObjectId(map['_id']),
      name: map['name']?.toString() ?? '',
      genericName: map['generic_name']?.toString() ?? '',
      categoryName: extractCategory(map['category']),
      manufacturer: map['manufacturer']?.toString() ?? '',
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0.0,
      image: map['image']?.toString() ?? '',
      batches: (map['batches'] is List)
          ? (map['batches'] as List)
              .whereType<Map<String, dynamic>>()
              .map((b) => BatchModel.fromMap(b))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'generic_name': genericName,
      'category': {'name': categoryName},
      'manufacturer': manufacturer,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'image': image,
      'batches': batches.map((b) => b.toMap()).toList(),
    };

    final currentId = id;
    if (currentId != null) {
      map['_id'] = currentId;
    }

    return map;
  }
}
