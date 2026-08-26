import 'package:mongo_dart/mongo_dart.dart';

class DatabaseService {
  static Db? _db;
  static const String _mongoUri = 'mongodb://127.0.0.1:27017/veterinary_db';

  static Future<Db> get instance async {
    if (_db == null || !_db!.isConnected) {
      _db = await Db.create(_mongoUri);
      await _db!.open();
      print('MongoDB Connected Successfully!');
    }
    return _db!;
  }

  static Future<void> connect() async {
    await instance;
  }


  static Future<DbCollection> getCollection(String collectionName) async {
    final db = await instance;
    return db.collection(collectionName);
  }
}