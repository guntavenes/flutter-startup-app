import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_startup_app/features/shared_lists/data/shared_list_repository.dart';

import '../../../core/database/app_database.dart';

class ItemRepository {
  ItemRepository(this._database, this._sharedListRepository);

  final AppDatabase _database;
  final SharedListRepository _sharedListRepository;
  bool _isSyncingToFirestore = false;

  Future<List<Item>> getAllItems() {
    return _database.select(_database.items).get();
  }

  Future<CollectionReference<Map<String, dynamic>>> _itemsCollection() async {
    final listRef = await _sharedListRepository.getActiveListRef();

    debugPrint('ITEM_WRITE_PATH=${listRef.collection('items').path}');

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

  Future<void> mergeLocalItemsToActiveSharedList() async {
    final localItems = await getAllItems();
    if (localItems.isEmpty) return;

    final collection = await _itemsCollection();
    final snapshot = await collection.get();

    final remoteItems = snapshot.docs.map((doc) => doc.data()).toList();

    for (final localItem in localItems) {
      final matchingRemote = remoteItems.where((remote) {
        return remote['categoryId'] == localItem.categoryId &&
            (remote['name'] as String).trim().toLowerCase() ==
                localItem.name.trim().toLowerCase();
      }).firstOrNull;

      if (matchingRemote == null) {
        final newDoc = collection.doc();
        final newId = DateTime.now().microsecondsSinceEpoch;

        final map = _itemToMap(localItem);
        map['id'] = newId;
        map['syncedAt'] = FieldValue.serverTimestamp();

        await newDoc.set(map);

        remoteItems.add(map);

        continue;
      }

      final remoteIsPurchased = matchingRemote['isPurchased'] as bool? ?? false;

      // İkisi de alınmışsa ayrı ürün oluştur
      if (localItem.isPurchased && remoteIsPurchased) {
        final itemName = _generateUniqueItemName(
          baseName: localItem.name,
          categoryId: localItem.categoryId,
          remoteItems: remoteItems,
        );

        final newDoc = collection.doc();
        final newId = DateTime.now().microsecondsSinceEpoch;

        final map = _itemToMap(localItem);
        map['id'] = newId;
        map['name'] = itemName;
        map['syncedAt'] = FieldValue.serverTimestamp();

        await newDoc.set(map);

        remoteItems.add(map);

        continue;
      }

      final remoteId = matchingRemote['id'] as int;
      final remoteUpdateAt = matchingRemote['updateAt'] as int? ?? 0;

      final mergedIsPurchased = localItem.isPurchased || remoteIsPurchased;

      final mergedUpdateAt = localItem.updateAt > remoteUpdateAt
          ? localItem.updateAt
          : remoteUpdateAt;

      final mergedMap = {
        ...matchingRemote,
        'isPurchased': mergedIsPurchased,
        'brand': localItem.brand ?? matchingRemote['brand'],
        'model': localItem.model ?? matchingRemote['model'],
        'link': localItem.link ?? matchingRemote['link'],
        'plannedPrice':
            localItem.plannedPrice ?? matchingRemote['plannedPrice'],
        'purchasedPrice':
            localItem.purchasedPrice ?? matchingRemote['purchasedPrice'],
        'purchaseDate':
            localItem.purchaseDate ?? matchingRemote['purchaseDate'],
        'storeName': localItem.storeName ?? matchingRemote['storeName'],
        'note': localItem.note ?? matchingRemote['note'],
        'extraFeatures':
            localItem.extraFeatures ?? matchingRemote['extraFeatures'],
        'imagePath': localItem.imagePath ?? matchingRemote['imagePath'],
        'updateAt': mergedUpdateAt,
        'syncedAt': FieldValue.serverTimestamp(),
      };

      await collection
          .doc(remoteId.toString())
          .set(mergedMap, SetOptions(merge: true));
    }
  }

  String _generateUniqueItemName({
    required String baseName,
    required int categoryId,
    required List<Map<String, dynamic>> remoteItems,
  }) {
    final normalizedBaseName = baseName.trim().toLowerCase();

    final existingNames = remoteItems
        .where((item) => item['categoryId'] == categoryId)
        .map((item) => (item['name'] as String).trim().toLowerCase())
        .toSet();

    if (!existingNames.contains(normalizedBaseName)) {
      return baseName;
    }

    var counter = 2;

    while (existingNames.contains('$normalizedBaseName $counter')) {
      counter++;
    }

    return '$baseName $counter';
  }

  Stream<void> watchSharedListItems() async* {
    final collection = await _itemsCollection();

    debugPrint('ITEM_LISTENER_PATH=${collection.path}');

    yield* collection.snapshots().asyncMap((snapshot) async {
      debugPrint('ITEM_LISTENER_DOC_COUNT=${snapshot.docs.length}');

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final isDeleted = data['isDeleted'] as bool? ?? false;

        final id = data['id'] as int;

        if (isDeleted) {
          await (_database.delete(
            _database.items,
          )..where((tbl) => tbl.id.equals(id))).go();

          continue;
        }

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
    });
  }

  Stream<List<Item>> watchAllItems() {
    return _database.select(_database.items).watch();
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
    final now = DateTime.now().millisecondsSinceEpoch;

    final result = await (_database.delete(
      _database.items,
    )..where((tbl) => tbl.id.equals(id))).go();

    final collection = await _itemsCollection();

    await collection.doc(id.toString()).set({
      'id': id,
      'isDeleted': true,
      'deletedAt': now,
      'updateAt': now,
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

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

  Future<void> addTemplateItemsAndSync(List<ItemsCompanion> companions) async {
    if (companions.isEmpty) return;

    final collection = await _itemsCollection();

    for (final companion in companions) {
      final id = await _database.into(_database.items).insert(companion);

      final item = await (_database.select(
        _database.items,
      )..where((tbl) => tbl.id.equals(id))).getSingle();

      await collection
          .doc(item.id.toString())
          .set(_itemToMap(item), SetOptions(merge: true));

      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }
}
