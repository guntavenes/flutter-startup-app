import 'dart:async';

import 'package:ceyizim_plus/features/notifications/data/notification_repository.dart';
import 'package:ceyizim_plus/features/shared_lists/data/shared_list_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

class ItemRepository {
  final NotificationRepository _notificationRepository;

  ItemRepository(
    this._database,
    this._sharedListRepository,
    this._notificationRepository,
  );

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

  Future<void> mergeLocalItemsToActiveSharedList() async {
    final localItems = await getAllItems();
    if (localItems.isEmpty) return;

    final collection = await _itemsCollection();
    final snapshot = await collection.get();

    final remoteItems = snapshot.docs.map((doc) {
      return {...doc.data(), '_docId': doc.id};
    }).toList();

    for (final localItem in localItems) {
      final localName = _normalizeItemName(localItem.name);

      final existsRemoteSameItem = remoteItems.any((remote) {
        final remoteName = _normalizeItemName(remote['name'] as String);

        return remote['categoryId'] == localItem.categoryId &&
            remoteName == localName;
      });

      // Sadece alınmayan ürünlerde duplicate engelle
      if (!localItem.isPurchased && existsRemoteSameItem) {
        continue;
      }

      // Alınan ürünlerde her zaman ekle
      final newDoc = collection.doc();
      final newId = DateTime.now().microsecondsSinceEpoch;

      final map = _itemToMap(localItem);
      map['id'] = newId;
      map['name'] = localItem.name.trim();
      map['syncedAt'] = FieldValue.serverTimestamp();

      await newDoc.set(map);

      remoteItems.add({...map, '_docId': newDoc.id});
    }
  }

  String _normalizeItemName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+\(\d+\)$'), '')
        .replaceAll(RegExp(r'\s+\d+$'), '');
  }

  Future<void> cleanupDuplicateRemoteItems() async {
    final collection = await _itemsCollection();
    final snapshot = await collection.get();

    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final categoryId = data['categoryId'];
      final name = _normalizeItemName(data['name'] as String);
      final key = '$categoryId|$name';

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add({...data, '_docId': doc.id});
    }

    for (final entry in grouped.entries) {
      final items = entry.value;

      if (items.length <= 1) continue;

      items.sort((a, b) {
        final aPurchased = a['isPurchased'] as bool? ?? false;
        final bPurchased = b['isPurchased'] as bool? ?? false;

        if (aPurchased != bPurchased) {
          return bPurchased ? 1 : -1;
        }

        final aUpdate = a['updateAt'] as int? ?? 0;
        final bUpdate = b['updateAt'] as int? ?? 0;

        return bUpdate.compareTo(aUpdate);
      });

      final keep = items.first;
      final keepDocId = keep['_docId'] as String;

      for (final item in items.skip(1)) {
        final docId = item['_docId'] as String;
        if (docId == keepDocId) continue;

        await collection.doc(docId).delete();
      }
    }
  }

  Stream<void> watchSharedListItems() async* {
    final collection = await _itemsCollection();

    yield* collection.snapshots().asyncMap((snapshot) async {
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
    final newIsPurchased = !item.isPurchased;

    final result =
        await (_database.update(
          _database.items,
        )..where((tbl) => tbl.id.equals(item.id))).write(
          ItemsCompanion(
            isPurchased: Value(newIsPurchased),
            updateAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    final updatedItem = await (_database.select(
      _database.items,
    )..where((tbl) => tbl.id.equals(item.id))).getSingle();

    await _setItemToFirestore(updatedItem);

    if (newIsPurchased) {
      try {
        await _notificationRepository.addItemPurchasedNotification(
          itemId: updatedItem.id,
          itemName: updatedItem.name,
        );
      } catch (error) {
        debugPrint('ADD_NOTIFICATION_ERROR: $error');
      }
    }

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

    if (!item.isPurchased) {
      try {
        await _notificationRepository.addItemPurchasedNotification(
          itemName: updatedItem.name,
          itemId: updatedItem.id,
        );
      } catch (error) {
        debugPrint('ADD_NOTIFICATION_ERROR: $error');
      }
    }

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
            note: const Value(null),
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

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final id = data['id'] as int;

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

  Future<Item> getById(int id) {
    return (_database.select(
      _database.items,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
  }
}
