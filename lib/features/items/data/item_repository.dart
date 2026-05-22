import 'package:drift/drift.dart';

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

  Future<int> updateItemDetails({
    required int id,
    required ItemsCompanion companion,
  }) {
    return (_database.update(
      _database.items,
    )..where((tbl) => tbl.id.equals(id))).write(companion);
  }

  Future<int> deleteItemById(int id) {
    return (_database.delete(
      _database.items,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> togglePurchased(Item item) {
    return (_database.update(
      _database.items,
    )..where((tbl) => tbl.id.equals(item.id))).write(
      ItemsCompanion(
        isPurchased: Value(!item.isPurchased),
        updateAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<int> markAsPurchased({
  required Item item,
  required double price,
  required String? brand,
  required int purchaseDate,
}) {
  return (_database.update(_database.items)..where((tbl) => tbl.id.equals(item.id)))
      .write(
    ItemsCompanion(
      isPurchased: const Value(true),
      purchasedPrice: Value(price),
      brand: Value(brand),
      purchaseDate: Value(purchaseDate),
      updateAt: Value(DateTime.now().millisecondsSinceEpoch),
    ),
  );
}

Future<int> markAsNotPurchased(Item item) {
  return (_database.update(_database.items)..where((tbl) => tbl.id.equals(item.id)))
      .write(
    ItemsCompanion(
      isPurchased: const Value(false),
      purchaseDate: const Value.absent(),
      updateAt: Value(DateTime.now().millisecondsSinceEpoch),
    ),
  );
}
}
