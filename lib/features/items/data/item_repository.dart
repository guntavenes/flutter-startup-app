import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter_startup_app/features/shared_lists/data/shared_list_repository.dart';

import '../../../core/database/app_database.dart';

class ItemRepository {
  ItemRepository(this._database, this._sharedListRepository);

  final AppDatabase _database;
  final SharedListRepository _sharedListRepository;

  Future<List<Item>> getAllItems() {
    return _database.select(_database.items).get();
  }

  Future<CollectionReference<Map<String, dynamic>>> _itemsCollection() async {
    final listRef = await _sharedListRepository.getActiveListRef();
    return listRef.collection('items');
  }

  Future<int> addItem(ItemsCompanion item) async {
    final insertedId = await _database.into(_database.items).insert(item);

    final insertedItem = await (_database.select(
      _database.items,
    )..where((tbl) => tbl.id.equals(insertedId))).getSingle();

    await _setItemToFirestore(insertedItem);

    return insertedId;
  }

  Stream<void> watchSharedListItems() async* {
    final collection = await _itemsCollection();

    yield* collection.snapshots().asyncMap((snapshot) async {
      final remoteIds = <int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final id = data['id'] as int;

        remoteIds.add(id);

        await _database
            .into(_database.items)
            .insertOnConflictUpdate(
              ItemsCompanion(
                id: Value(id),
                categoryId: Value(data['categoryId'] as int),
                name: Value(data['name'] as String),
                brand: Value(data['brand'] as String?),
                model: Value(data['model'] as String?),
                link: Value(data['link'] as String?),
                plannedPrice: Value((data['plannedPrice'] as num?)?.toDouble()),
                purchasedPrice: Value(
                  (data['purchasedPrice'] as num?)?.toDouble(),
                ),
                purchaseDate: Value(data['purchaseDate'] as int?),
                storeName: Value(data['storeName'] as String?),
                note: Value(data['note'] as String?),
                extraFeatures: Value(data['extraFeatures'] as String?),
                imagePath: Value(data['imagePath'] as String?),
                isPurchased: Value(data['isPurchased'] as bool? ?? false),
                createdAt: Value(data['createdAt'] as int),
                updateAt: Value(data['updateAt'] as int),
                estimatedPurchaseDate: Value(
                  data['estimatedPurchaseDate'] as int?,
                ),
              ),
            );
      }

      final localItems = await getAllItems();

      for (final item in localItems) {
        if (!remoteIds.contains(item.id)) {
          await (_database.delete(
            _database.items,
          )..where((tbl) => tbl.id.equals(item.id))).go();
        }
      }
    });
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
            brand: const Value(null),
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
    final collection = await _itemsCollection();

    for (final item in items) {
      batch.set(
        collection.doc(item.id.toString()),
        _itemToMap(item),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> _setItemToFirestore(Item item) async {
    final collection = await _itemsCollection();

    await collection
        .doc(item.id.toString())
        .set(_itemToMap(item), SetOptions(merge: true));
  }

  Future<void> _deleteItemFromFirestore(int id) async {
    final collection = await _itemsCollection();

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

  Future<void> addItemsFromTemplate(List<ItemsCompanion> items) async {
    await _database.batch((batch) {
      batch.insertAll(_database.items, items);
    });

    await syncAllItemsToFirestore();
  }

  Future<void> addItemsToLocalOnly(List<ItemsCompanion> items) async {
    await _database.batch((batch) {
      batch.insertAll(_database.items, items);
    });
  }

  Future<void> syncItemsFromFirestore() async {
    final collection = await _itemsCollection();
    final snapshot = await collection.get();

    final remoteIds = <int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final id = data['id'] as int;

      remoteIds.add(id);

      await _database
          .into(_database.items)
          .insertOnConflictUpdate(
            ItemsCompanion(
              id: Value(id),
              categoryId: Value(data['categoryId'] as int),
              name: Value(data['name'] as String),
              brand: Value(data['brand'] as String?),
              model: Value(data['model'] as String?),
              link: Value(data['link'] as String?),
              plannedPrice: Value((data['plannedPrice'] as num?)?.toDouble()),
              purchasedPrice: Value(
                (data['purchasedPrice'] as num?)?.toDouble(),
              ),
              purchaseDate: Value(data['purchaseDate'] as int?),
              storeName: Value(data['storeName'] as String?),
              note: Value(data['note'] as String?),
              extraFeatures: Value(data['extraFeatures'] as String?),
              imagePath: Value(data['imagePath'] as String?),
              isPurchased: Value(data['isPurchased'] as bool? ?? false),
              createdAt: Value(data['createdAt'] as int),
              updateAt: Value(data['updateAt'] as int),
              estimatedPurchaseDate: Value(
                data['estimatedPurchaseDate'] as int?,
              ),
            ),
          );
    }

    final localItems = await getAllItems();

    for (final item in localItems) {
      if (!remoteIds.contains(item.id)) {
        await (_database.delete(
          _database.items,
        )..where((tbl) => tbl.id.equals(item.id))).go();
      }
    }
  }
}
