import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/features/items/data/item_providers.dart';
import 'package:flutter_startup_app/features/notifications/data/notification_providers.dart';
import 'package:flutter_startup_app/features/shared_lists/data/shared_list_providers.dart';

import '../../../core/database/database_provider.dart';
import 'item_repository.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sharedListRepository = ref.watch(sharedListRepositoryProvider);
  final notificationRepository = ref.watch(notificationRepositoryProvider);

  return ItemRepository(db, sharedListRepository, notificationRepository);
});

final sharedItemsSyncProvider = StreamProvider<void>((ref) {
  final repository = ref.watch(itemRepositoryProvider);

  return repository.watchSharedListItems().map((_) {
    ref.invalidate(allItemsProvider);
  });
});
