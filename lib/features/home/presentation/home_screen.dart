import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/features/items/data/item_providers.dart';
import 'package:flutter_startup_app/features/items/data/item_repository_provider.dart';
import 'package:flutter_startup_app/features/items/presentation/item_form_screen.dart';
import 'dart:io';

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
    final categories = groupedItems.keys.toList();

    if (groupedItems.values.every((items) => items.isEmpty)) {
      return const Center(
        child: Text(
          'Henüz ürün eklenmedi',
          style: TextStyle(
            color: Color(0xFF8A6B79),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final items = groupedItems[category]!;

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryHeader(category, items),
              const SizedBox(height: 10),
              if (!_collapsedCategoryIds.contains(category.id))
                ...items.map((item) => _buildItemCard(item)),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryHeader(Category category, List<Item> items) {
    final isCollapsed = _collapsedCategoryIds.contains(category.id);
    final totalExpense = _calculateCategoryExpense(items);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isCollapsed) {
            _collapsedCategoryIds.remove(category.id);
          } else {
            _collapsedCategoryIds.add(category.id);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD96BA7).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC7E3), Color(0xFFFFEEF7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getCategoryIcon(category.name),
                size: 20,
                color: const Color(0xFFD96BA7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C1E26),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${items.length} ürün • ${totalExpense.toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A6B79),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: isCollapsed ? -0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF8A6B79),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.13),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: item.imagePath != null && item.imagePath!.isNotEmpty
                ? Image.file(
                    File(item.imagePath!),
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFC7E3), Color(0xFFFFEEF7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFFD96BA7),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.trim().isEmpty ? 'İsimsiz Ürün' : item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C1E26),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _buildItemSubtitle(item),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: item.isPurchased
                        ? const Color(0xFF2EAD5B)
                        : const Color(0xFF8A6B79),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final repo = ref.read(itemRepositoryProvider);

              await repo.togglePurchased(item);

              ref.invalidate(allItemsProvider);
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                item.isPurchased
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                key: ValueKey(item.isPurchased),
                color: item.isPurchased
                    ? const Color(0xFF2EAD5B)
                    : const Color(0xFFC7A9B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildItemSubtitle(Item item) {
    final status = item.isPurchased ? 'Alındı' : 'Alınmadı';

    if (item.purchasedPrice == null) {
      return status;
    }

    return '$status • ${item.purchasedPrice!.toStringAsFixed(2)} ₺';
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

  double _calculateCategoryExpense(List<Item> items) {
    return items
        .where((item) => item.isPurchased && item.purchasedPrice != null)
        .fold<double>(0, (sum, item) => sum + item.purchasedPrice!);
  }
}
