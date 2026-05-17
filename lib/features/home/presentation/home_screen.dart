import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/features/items/data/item_providers.dart';
import 'package:flutter_startup_app/features/items/data/item_repository_provider.dart';
import 'package:flutter_startup_app/features/items/presentation/item_form_screen.dart';
import 'dart:io';
import 'package:flutter_startup_app/features/items/presentation/item_detail_screen.dart';
import 'package:flutter_startup_app/features/categories/presentation/category_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<int> _collapsedCategoryIds = {};

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);
    final allItemsAsync = ref.watch(allItemsProvider);
    final groupedItemsAsync = ref.watch(groupedItemsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ItemFormScreen()));
        },
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF5FA), Color(0xFFFFF7F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 26, 18, 0),
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Hata: $error')),
              data: (_) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    allItemsAsync.when(
                      loading: () => _buildSummary([]),
                      error: (_, __) => _buildSummary([]),
                      data: (allItems) => _buildSummary(allItems),
                    ),
                    const SizedBox(height: 16),
                    _buildFilters(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: groupedItemsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) =>
                            Center(child: Text('Hata: $error')),
                        data: (groupedItems) {
                          return _buildGroupedItemList(groupedItems);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8DBA), Color(0xFFD96BA7), Color(0xFFFFB6D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: Text('🎁', style: TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Çeyiz Takip',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'İhtiyaçlarını, aldıklarını ve bütçeni kolayca yönet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<Item> items) {
    final total = items.length;
    final purchased = items.where((e) => e.isPurchased).length;
    final remaining = total - purchased;

    final totalExpense = items
        .where((e) => e.isPurchased && e.purchasedPrice != null)
        .fold<double>(0, (sum, item) => sum + item.purchasedPrice!);

    return Column(
      children: [
        Row(
          children: [
            _summaryCard(
              'Toplam',
              total.toString(),
              Icons.list_alt_rounded,
              const Color(0xFFFF8DBA),
            ),
            const SizedBox(width: 10),
            _summaryCard(
              'Alınan',
              purchased.toString(),
              Icons.check_circle_rounded,
              const Color(0xFF7ACFA6),
            ),
            const SizedBox(width: 10),
            _summaryCard(
              'Kalan',
              remaining.toString(),
              Icons.hourglass_bottom_rounded,
              const Color(0xFFFFB74D),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _expenseCard(totalExpense),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C1E26),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8A6B79),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expenseCard(double totalExpense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD96BA7), Color(0xFFFF8DBA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.payments_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toplam Harcama',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalExpense.toStringAsFixed(2)} ₺',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final current = ref.watch(itemFilterProvider);

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            ref.read(itemFilterProvider.notifier).state = ItemFilter.all;
          },
          child: _filterChip('Tümü', current == ItemFilter.all),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            ref.read(itemFilterProvider.notifier).state = ItemFilter.remaining;
          },
          child: _filterChip('Kalan', current == ItemFilter.remaining),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            ref.read(itemFilterProvider.notifier).state = ItemFilter.purchased;
          },
          child: _filterChip('Alınan', current == ItemFilter.purchased),
        ),
      ],
    );
  }

  Widget _filterChip(String text, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFFD96BA7), Color(0xFFFF8DBA)],
              )
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.transparent : const Color(0xFFF0D7E5),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFD96BA7).withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : const Color(0xFF6D4C5B),
        ),
      ),
    );
  }

  Widget _buildGroupedItemList(Map<Category, List<Item>> groupedItems) {
    final currentFilter = ref.watch(itemFilterProvider);

    final categories = groupedItems.keys.where((category) {
      final items = groupedItems[category] ?? [];

      if (currentFilter == ItemFilter.all) {
        return true;
      }

      if (currentFilter == ItemFilter.remaining) {
        return items.any((item) => !item.isPurchased);
      }

      if (currentFilter == ItemFilter.purchased) {
        return items.any((item) => item.isPurchased);
      }

      return true;
    }).toList();

    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'Bu filtrede ürün yok',
          style: TextStyle(
            color: Color(0xFF8A6B79),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    categories.sort((a, b) {
      final aItems = groupedItems[a]!;
      final bItems = groupedItems[b]!;

      if (aItems.isEmpty && bItems.isNotEmpty) return 1;
      if (bItems.isEmpty && aItems.isNotEmpty) return -1;

      if (aItems.isNotEmpty && bItems.isNotEmpty) {
        final aLast = aItems
            .map((e) => e.createdAt)
            .reduce((v, e) => v > e ? v : e);

        final bLast = bItems
            .map((e) => e.createdAt)
            .reduce((v, e) => v > e ? v : e);

        return bLast.compareTo(aLast);
      }

      return a.name.compareTo(b.name);
    });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final items = groupedItems[category]!;

        return _buildCategoryCard(category, items);
      },
    );
  }

  Widget _buildCategoryCard(Category category, List<Item> items) {
    final purchasedCount = items.where((e) => e.isPurchased).length;
    final remainingCount = items.length - purchasedCount;

    final totalExpense = items
        .where((e) => e.isPurchased && e.purchasedPrice != null)
        .fold<double>(0, (sum, item) => sum + item.purchasedPrice!);

    final lastItem = items.isNotEmpty ? items.last : null;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CategoryDetailScreen(category: category, items: items),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD96BA7).withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFC7E3), Color(0xFFFFEEF7)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getCategoryIcon(category.name),
                    color: const Color(0xFFD96BA7),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2C1E26),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${items.length} ürün',
                        style: const TextStyle(
                          color: Color(0xFF8A6B79),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8A6B79),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _miniInfoCard(
                  'Alınan',
                  purchasedCount.toString(),
                  const Color(0xFF7ACFA6),
                ),
                const SizedBox(width: 10),
                _miniInfoCard(
                  'Kalan',
                  remainingCount.toString(),
                  const Color(0xFFFFB74D),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7FB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Toplam Harcama',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalExpense.toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD96BA7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniInfoCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C1E26),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A6B79),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('mutfak')) return Icons.restaurant_menu_rounded;
    if (name.contains('yatak')) return Icons.bed_rounded;
    if (name.contains('banyo')) return Icons.shower_rounded;
    if (name.contains('salon')) return Icons.chair_rounded;
    if (name.contains('elektronik')) return Icons.devices_rounded;

    return Icons.category_rounded;
  }
}
