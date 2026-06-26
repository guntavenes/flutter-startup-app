import 'package:ceyizim_plus/features/shared_lists/data/shared_list_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import 'category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sharedListRepository = ref.watch(sharedListRepositoryProvider);

  return CategoryRepository(db, sharedListRepository);
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAll();
});

final sharedCategoriesSyncProvider = StreamProvider<void>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);

  return repository.watchSharedListCategories().map((_) {
    ref.invalidate(categoriesProvider);
  });
});
