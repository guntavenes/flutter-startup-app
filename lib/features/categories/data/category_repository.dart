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
    if (existing.isNotEmpty) return;

    await _db.batch((batch) {
      batch.insertAll(_db.categories, [
        CategoriesCompanion.insert(name: 'Mutfak', createdAt: now),
        CategoriesCompanion.insert(name: 'Yatak Odası', createdAt: now),
        CategoriesCompanion.insert(name: 'Banyo', createdAt: now),
        CategoriesCompanion.insert(name: 'Salon', createdAt: now),
        CategoriesCompanion.insert(name: 'Elektronik', createdAt: now),
      ]);
    });
  }
}