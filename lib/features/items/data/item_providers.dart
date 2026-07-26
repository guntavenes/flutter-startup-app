import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/database/app_database.dart';
import '../../categories/data/category_providers.dart';
import 'item_repository_provider.dart';

enum ItemFilter { all, remaining, purchased }

final itemFilterProvider = StateProvider<ItemFilter>((ref) {
  return ItemFilter.all;
});

final allItemsProvider = StreamProvider<List<Item>>((ref) {
  final repository = ref.watch(itemRepositoryProvider);

  return repository.watchAllItems();
});

final itemsProvider = Provider<AsyncValue<List<Item>>>((ref) {
  final filter = ref.watch(itemFilterProvider);
  final itemsAsync = ref.watch(allItemsProvider);

  return itemsAsync.when(
    loading: () => const AsyncLoading(),
    error: (error, stackTrace) => AsyncError(error, stackTrace),
    data: (items) {
      switch (filter) {
        case ItemFilter.remaining:
          return AsyncData(items.where((e) => !e.isPurchased).toList());
        case ItemFilter.purchased:
          return AsyncData(items.where((e) => e.isPurchased).toList());
        case ItemFilter.all:
          return AsyncData(items);
      }
    },
  );
});

final recentPurchasedItemsProvider = Provider<AsyncValue<List<Item>>>((ref) {
  final itemsAsync = ref.watch(allItemsProvider);

  return itemsAsync.when(
    loading: () => const AsyncLoading(),
    error: (error, stackTrace) => AsyncError(error, stackTrace),
    data: (items) {
      final sevenDaysAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;

      final recentItems = items.where((item) {
        return item.isPurchased && item.updateAt >= sevenDaysAgo;
      }).toList();

      recentItems.sort((a, b) {
        return b.updateAt.compareTo(a.updateAt);
      });

      return AsyncData(recentItems);
    },
  );
});

final groupedItemsProvider = Provider<AsyncValue<Map<Category, List<Item>>>>((
  ref,
) {
  final itemsAsync = ref.watch(allItemsProvider);
  final categoriesAsync = ref.watch(categoriesProvider);

  return itemsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
    data: (items) {
      return categoriesAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
        data: (categories) {
          final groupedItems = <Category, List<Item>>{};

          for (final category in categories) {
            final categoryItems = items
                .where((item) => item.categoryId == category.id)
                .toList();

            if (categoryItems.isNotEmpty) {
              groupedItems[category] = categoryItems;
            }
          }

          return AsyncValue.data(groupedItems);
        },
      );
    },
  );
});
