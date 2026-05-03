import '../../../core/database/app_database.dart';

class ItemRepository {
  ItemRepository(this._database);

  final AppDatabase _database;

  Future<List<Item>> getAllItems() {
    return _database.select(_database.items).get();
  }

  Future<int> addItem(ItemsCompanion item) {
    return _database.into(_database.items).insert(item);
  }

  Future<bool> updateItem(ItemsCompanion item) {
    return _database.update(_database.items).replace(item);
  }

  Future<int> deleteItem(int id) {
    return (_database.delete(_database.items)..where((tbl) => tbl.id.equals(id))).go();
  }
}