import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/database/app_database.dart';

class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  Future<List<Category>> getAll() {
    return _db.select(_db.categories).get();
  }

  Future<void> insertDefaultCategories() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await getAll();

    if (existing.isNotEmpty) {
      await _syncCategoriesToFirestore(existing);
      return;
    }

    await _db.batch((batch) {
      batch.insertAll(_db.categories, [
        CategoriesCompanion.insert(
          name: 'Mutfak',
          iconName: const Value('restaurant'),
          createdAt: now,
        ),
        CategoriesCompanion.insert(
          name: 'Yatak Odası',
          iconName: const Value('bed'),
          createdAt: now,
        ),
        CategoriesCompanion.insert(
          name: 'Banyo',
          iconName: const Value('shower'),
          createdAt: now,
        ),
        CategoriesCompanion.insert(
          name: 'Salon',
          iconName: const Value('weekend'),
          createdAt: now,
        ),
        CategoriesCompanion.insert(
          name: 'Elektronik',
          iconName: const Value('electrical'),
          createdAt: now,
        ),
      ]);
    });

    final insertedCategories = await getAll();

    await _syncCategoriesToFirestore(insertedCategories);
  }

  Future<void> syncCategoriesFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    for (final doc in snapshot.docs) {
      final data = doc.data();

      await _db
          .into(_db.categories)
          .insertOnConflictUpdate(
            CategoriesCompanion(
              id: Value(data['id'] as int),
              name: Value(data['name'] as String),
              iconName: Value(data['iconName'] as String? ?? 'category'),
              createdAt: Value(data['createdAt'] as int),
            ),
          );
    }
  }

  Future<void> addCategory({
    required String name,
    String iconName = 'category',
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return;
    }

    final existingCategories = await getAll();

    final alreadyExists = existingCategories.any((category) {
      return category.name.trim().toLowerCase() == trimmedName.toLowerCase();
    });

    if (alreadyExists) {
      throw Exception('Bu kategori zaten var.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    final id = await _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            name: trimmedName,
            iconName: Value(iconName),
            createdAt: now,
          ),
        );

    await _syncSingleCategoryToFirestore(
      Category(id: id, name: trimmedName, iconName: iconName, createdAt: now),
    );
  }

  Future<void> updateCategory({
    required Category category,
    required String name,
    required String iconName,
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return;
    }

    final existingCategories = await getAll();

    final alreadyExists = existingCategories.any((item) {
      return item.id != category.id &&
          item.name.trim().toLowerCase() == trimmedName.toLowerCase();
    });

    if (alreadyExists) {
      throw Exception('Bu kategori zaten var.');
    }

    await (_db.update(
      _db.categories,
    )..where((tbl) => tbl.id.equals(category.id))).write(
      CategoriesCompanion(name: Value(trimmedName), iconName: Value(iconName)),
    );

    await _syncSingleCategoryToFirestore(
      category.copyWith(name: trimmedName, iconName: iconName),
    );
  }

  Future<void> deleteCategory(Category category) async {
    final itemCount = await (_db.select(
      _db.items,
    )..where((tbl) => tbl.categoryId.equals(category.id))).get();

    if (itemCount.isNotEmpty) {
      throw Exception('Bu kategoride ürün olduğu için silinemez.');
    }

    await (_db.delete(
      _db.categories,
    )..where((tbl) => tbl.id.equals(category.id))).go();

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .doc(category.id.toString())
        .delete();
  }

  Future<void> updateDefaultCategoryIcons() async {
    final categories = await getAll();

    for (final category in categories) {
      final iconName = _defaultIconForCategory(category.name);

      await (_db.update(_db.categories)
            ..where((tbl) => tbl.id.equals(category.id)))
          .write(CategoriesCompanion(iconName: Value(iconName)));
    }

    final updatedCategories = await getAll();
    await _syncCategoriesToFirestore(updatedCategories);
  }

  String _defaultIconForCategory(String name) {
    final value = name.toLowerCase();

    if (value.contains('mutfak')) return 'restaurant';
    if (value.contains('yatak')) return 'bed';
    if (value.contains('banyo')) return 'shower';
    if (value.contains('salon')) return 'weekend';
    if (value.contains('elektronik')) return 'electrical';
    if (value.contains('beyaz')) return 'laundry';

    return 'category';
  }

  Future<void> _syncCategoriesToFirestore(List<Category> categories) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final batch = FirebaseFirestore.instance.batch();

    for (final category in categories) {
      final categoryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(category.id.toString());

      batch.set(categoryRef, _categoryToMap(category), SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> _syncSingleCategoryToFirestore(Category category) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .doc(category.id.toString())
        .set(_categoryToMap(category), SetOptions(merge: true));
  }

  Map<String, dynamic> _categoryToMap(Category category) {
    return {
      'id': category.id,
      'name': category.name,
      'iconName': category.iconName,
      'createdAt': category.createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
