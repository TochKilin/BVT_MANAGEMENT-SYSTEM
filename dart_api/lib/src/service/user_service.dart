
import '../config/database.dart';
import '../models/owner_model.dart';

class OwnerService {
  Future<List<OwnerModel>> getAllOwners() async {
    final collection = await DatabaseService.getCollection('owners');
    final ownersData = await collection.find().toList();
    return ownersData.map((map) => OwnerModel.fromMap(map)).toList();
  }

  Future<void> createOwner(OwnerModel owner) async {
    final collection = await DatabaseService.getCollection('owners');
    await collection.insertOne(owner.toMap());
  }
}