import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  IntColumn get createdAt => integer()();

  TextColumn get iconName => text().withDefault(const Constant('category'))();
}
