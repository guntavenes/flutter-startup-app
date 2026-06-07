import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/database/app_database.dart';

class ItemRepository {
  ItemRepository(this._database);

  final AppDatabase _database;

  Future<List<Item>> getAllItems() {
    return _database.select(_database.items).get();
  }

  Future<int> addItem(ItemsCompanion item) async {
    final insertedId = await _database.into(_database.items).insert(item);

    final insertedItem = await (_database.select(
      _database.items,
    )..where((tbl) => tbl.id.equals(insertedId))).getSingle();

    await _setItemToFirestore(insertedItem);

    return insertedId;
  }

  Future<int> updateItemDetails({
    required int id,
    required ItemsCompanion companion,
  }) async {
    final result = await (_database.update(
      _database.items,
    )..where((tbl) => tbl.id.equals(id))).write(companion);

    final updatedItem = await (_database.select(
      _database.items,
    )..where((tbl) => tbl.id.equals(id))).getSingle();

    await _setItemToFirestore(updatedItem);

    return result;
  }

  Future<int> deleteItemById(int id) async {
    final result = await (_database.delete(
      _database.items,
    )..where((tbl) => tbl.id.equals(id))).go();

    await _deleteItemFromFirestore(id);

    return result;
  }

  Future<int> togglePurchased(Item item) async {
    final result =
        await (_database.update(
          _database.items,
        )..where((tbl) => tbl.id.equals(item.id))).write(
          ItemsCompanion(
            isPurchased: Value(!item.isPurchased),
            updateAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    final updatedItem = await (_database.select(
      _database.items,
    )..where((tbl) => tbl.id.equals(item.id))).getSingle();

    await _setItemToFirestore(updatedItem);

    return result;
  }

  Future<int> markAsPurchased({
    required Item item,
    required double price,
    required String? brand,
    required int purchaseDate,
  }) async {
    final result =
        await (_database.update(
          _database.items,
        )..where((tbl) => tbl.id.equals(item.id))).write(
          ItemsCompanion(
            isPurchased: const Value(true),
            purchasedPrice: Value(price),
            brand: Value(brand),
            purchaseDate: Value(purchaseDate),
            updateAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    final updatedItem = await (_database.select(
      _database.items,
    )..where((tbl) => tbl.id.equals(item.id))).getSingle();

    await _setItemToFirestore(updatedItem);

    return result;
  }

  Future<int> markAsNotPurchased(Item item) async {
    final result =
        await (_database.update(
          _database.items,
        )..where((tbl) => tbl.id.equals(item.id))).write(
          ItemsCompanion(
            isPurchased: const Value(false),
            purchasedPrice: const Value(null),
            purchaseDate: const Value(null),
            imagePath: const Value(null),
            link: const Value(null),
            updateAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    final updatedItem = await (_database.select(
      _database.items,
    )..where((tbl) => tbl.id.equals(item.id))).getSingle();

    await _setItemToFirestore(updatedItem);

    return result;
  }

  Future<int> undoPurchased(Item item) {
    return markAsNotPurchased(item);
  }

  Future<void> syncAllItemsToFirestore() async {
    final items = await getAllItems();

    final batch = FirebaseFirestore.instance.batch();
    final collection = _itemsCollection();

    if (collection == null) {
      return;
    }

    for (final item in items) {
      batch.set(
        collection.doc(item.id.toString()),
        _itemToMap(item),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>>? _itemsCollection() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('items');
  }

  Future<void> _setItemToFirestore(Item item) async {
    final collection = _itemsCollection();

    if (collection == null) {
      return;
    }

    await collection
        .doc(item.id.toString())
        .set(_itemToMap(item), SetOptions(merge: true));
  }

  Future<void> _deleteItemFromFirestore(int id) async {
    final collection = _itemsCollection();

    if (collection == null) {
      return;
    }

    await collection.doc(id.toString()).delete();
  }

  Map<String, dynamic> _itemToMap(Item item) {
    return {
      'id': item.id,
      'categoryId': item.categoryId,
      'name': item.name,
      'brand': item.brand,
      'model': item.model,
      'link': item.link,
      'plannedPrice': item.plannedPrice,
      'purchasedPrice': item.purchasedPrice,
      'purchaseDate': item.purchaseDate,
      'storeName': item.storeName,
      'note': item.note,
      'extraFeatures': item.extraFeatures,
      'imagePath': item.imagePath,
      'isPurchased': item.isPurchased,
      'createdAt': item.createdAt,
      'updateAt': item.updateAt,
      'estimatedPurchaseDate': item.estimatedPurchaseDate,
      'syncedAt': FieldValue.serverTimestamp(),
    };
  }
}
