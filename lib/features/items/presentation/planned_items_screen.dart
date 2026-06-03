import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/core/extensions/date_extensions.dart';
import 'package:flutter_startup_app/features/items/data/item_providers.dart';
import 'package:flutter_startup_app/features/items/domain/planned_item_filter.dart';
import 'package:flutter_startup_app/features/items/presentation/item_detail_screen.dart';

class PlannedItemsScreen extends ConsumerWidget {
  const PlannedItemsScreen({super.key, required this.filter});

  final PlannedItemFilter filter;

  String get title {
    switch (filter) {
      case PlannedItemFilter.today:
        return 'Bugün Alınacaklar';
      case PlannedItemFilter.week:
        return 'Bu Hafta Alınacaklar';
    }
  }

  String get emptyMessage {
    switch (filter) {
      case PlannedItemFilter.today:
        return 'Bugün alınması planlanan ürün yok.';
      case PlannedItemFilter.week:
        return 'Bu hafta alınması planlanan ürün yok.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allItemsAsync = ref.watch(allItemsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFFFF5FA),
        elevation: 0,
      ),
      body: allItemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Hata: $error')),
        data: (items) {
          final plannedItems = _filterItems(items);

          plannedItems.sort((a, b) {
            final aDate = a.estimatedPurchaseDate ?? 0;
            final bDate = b.estimatedPurchaseDate ?? 0;

            return aDate.compareTo(bDate);
          });

          return _buildBody(context, ref, plannedItems);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<Item> items) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF5FA), Color(0xFFFFF7F0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: items.isEmpty
          ? Center(
              child: Text(
                emptyMessage,
                style: const TextStyle(
                  color: Color(0xFF8A6B79),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(item: item),
                      ),
                    );

                    if (result == true) {
                      ref.invalidate(allItemsProvider);
                    }
                  },
                  child: _buildItemCard(item),
                );
              },
            ),
    );
  }

  List<Item> _filterItems(List<Item> items) {
    switch (filter) {
      case PlannedItemFilter.today:
        return _getTodayItems(items);
      case PlannedItemFilter.week:
        return _getThisWeekItems(items);
    }
  }

  List<Item> _getTodayItems(List<Item> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return items.where((item) {
      if (item.isPurchased) return false;
      if (item.estimatedPurchaseDate == null) return false;

      final targetDate = DateTime.fromMillisecondsSinceEpoch(
        item.estimatedPurchaseDate!,
      );

      final targetDay = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );

      return targetDay == today;
    }).toList();
  }

  List<Item> _getThisWeekItems(List<Item> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = today.add(const Duration(days: 7));

    return items.where((item) {
      if (item.isPurchased) return false;
      if (item.estimatedPurchaseDate == null) return false;

      final targetDate = DateTime.fromMillisecondsSinceEpoch(
        item.estimatedPurchaseDate!,
      );

      final targetDay = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );

      return !targetDay.isBefore(today) && targetDay.isBefore(endDate);
    }).toList();
  }

  Widget _buildItemCard(Item item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: item.imagePath != null && item.imagePath!.isNotEmpty
                ? Image.file(
                    File(item.imagePath!),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    cacheWidth: 160,
                    cacheHeight: 160,
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFC7E3), Color(0xFFFFEEF7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.event_note_outlined,
                      color: Color(0xFFD96BA7),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.trim().isEmpty ? 'İsimsiz Ürün' : item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C1E26),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hedef: ${item.estimatedPurchaseDate.toShortDateText()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A6B79),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A6B79)),
        ],
      ),
    );
  }
}
