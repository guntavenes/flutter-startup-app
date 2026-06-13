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
        CategoriesCompanion.insert(name: 'Mutfak', createdAt: now),
        CategoriesCompanion.insert(name: 'Yatak Odası', createdAt: now),
        CategoriesCompanion.insert(name: 'Banyo', createdAt: now),
        CategoriesCompanion.insert(name: 'Salon', createdAt: now),
        CategoriesCompanion.insert(name: 'Elektronik', createdAt: now),
      ]);
    });

    final insertedCategories = await getAll();

    await _syncCategoriesToFirestore(insertedCategories);
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

      batch.set(categoryRef, {
        'id': category.id,
        'name': category.name,
        'createdAt': category.createdAt,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> syncCategoriesFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('categories')
        .get();

    if (snapshot.docs.isEmpty) return;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      await _db
          .into(_db.categories)
          .insertOnConflictUpdate(
            CategoriesCompanion(
              id: Value(data['id'] as int),
              name: Value(data['name'] as String),
              createdAt: Value(data['createdAt'] as int),
            ),
          );
    }
  }
}
