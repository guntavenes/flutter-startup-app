import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import 'item_repository.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return ItemRepository(database);
});