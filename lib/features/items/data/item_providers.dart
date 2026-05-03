import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import 'item_repository_provider.dart';

final itemsProvider = FutureProvider<List<Item>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  return repository.getAllItems();
});