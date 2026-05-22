import 'package:drift/drift.dart';
import 'categories_table.dart';

class Items extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get categoryId => integer().references(Categories, #id)();

  TextColumn get name => text()();

  TextColumn get brand => text().nullable()();

  TextColumn get model => text().nullable()();

  TextColumn get link => text().nullable()();

  RealColumn get plannedPrice => real().nullable()();

  RealColumn get purchasedPrice => real().nullable()();

  IntColumn get purchaseDate => integer().nullable()();

  TextColumn get storeName => text().nullable()();

  TextColumn get note => text().nullable()();

  TextColumn get extraFeatures => text().nullable()();

  TextColumn get imagePath => text().nullable()();

  BoolColumn get isPurchased => boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();

  IntColumn get updateAt => integer()();
  
  IntColumn get estimatedPurchaseDate => integer().nullable()();
}
