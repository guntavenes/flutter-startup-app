import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/database/app_database.dart';
import '../../categories/data/category_providers.dart';
import 'item_repository_provider.dart';

enum ItemFilter { all, remaining, purchased }

final itemFilterProvider = StateProvider<ItemFilter>((ref) {
  return ItemFilter.all;
});

final allItemsProvider = FutureProvider<List<Item>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  return repository.getAllItems();
});

final itemsProvider = FutureProvider<List<Item>>((ref) async {
  final filter = ref.watch(itemFilterProvider);
  final items = await ref.watch(allItemsProvider.future);

  switch (filter) {
    case ItemFilter.remaining:
      return items.where((e) => !e.isPurchased).toList();
    case ItemFilter.purchased:
      return items.where((e) => e.isPurchased).toList();
    case ItemFilter.all:
      return items;
  }
});

final groupedItemsProvider = FutureProvider<Map<Category, List<Item>>>((
  ref,
) async {
  final items = await ref.watch(itemsProvider.future);
  final categories = await ref.watch(categoriesProvider.future);

  final Map<Category, List<Item>> grouped = {};

  for (final category in categories) {
    grouped[category] = [];
  }

  for (final item in items) {
    final category = categories.firstWhere(
      (c) => c.id == item.categoryId,
      orElse: () => categories.first,
    );

    grouped[category]!.add(item);
  }

  return grouped;
});
