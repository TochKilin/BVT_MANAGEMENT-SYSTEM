import 'package:mongo_dart/mongo_dart.dart';

/// Converts MongoDB values to values accepted by jsonEncode.
dynamic jsonSafe(dynamic value) {
  if (value is ObjectId) return value.oid;
  if (value is DateTime) return value.toIso8601String();
  if (value is Map) return value.map((key, item) => MapEntry(key.toString(), jsonSafe(item)));
  if (value is Iterable) return value.map(jsonSafe).toList();
  return value;
}
