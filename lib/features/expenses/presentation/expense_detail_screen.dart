import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/core/extensions/currency_extensions.dart';
import 'package:flutter_startup_app/core/extensions/date_extensions.dart';
import 'package:flutter_startup_app/features/categories/data/category_providers.dart';
import 'package:flutter_startup_app/features/expenses/domain/expense_sort_type.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  const ExpenseDetailScreen({super.key, required this.items});

  final List<Item> items;

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  ExpenseSortType _sortType = ExpenseSortType.dateDesc;
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    final purchasedItems = widget.items.where((item) {
      if (!item.isPurchased) {
        return false;
      }

      if (_selectedCategoryId == null) {
        return true;
      }

      return item.categoryId == _selectedCategoryId;
    }).toList();
    final sortedItems = _sortItems(purchasedItems);

    final totalExpense = purchasedItems.fold<double>(
      0,
      (sum, item) => sum + (item.purchasedPrice ?? 0),
    );

    final averageExpense = purchasedItems.isEmpty
        ? 0.0
        : totalExpense / purchasedItems.length;

    final mostExpensiveItem = purchasedItems.isEmpty
        ? null
        : purchasedItems.reduce(
            (a, b) =>
                (a.purchasedPrice ?? 0) >= (b.purchasedPrice ?? 0) ? a : b,
          );

    final completionPercent = widget.items.isEmpty
        ? 0.0
        : (purchasedItems.length / widget.items.length) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: const Text('Harcama Detayı'),
        backgroundColor: const Color(0xFFFFF5FA),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF5FA), Color(0xFFFFF7F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              _buildHeader(totalExpense, purchasedItems.length),
              categoriesAsync.when(
                loading: () => _buildStatisticsCards(
                  mostExpensiveItem: mostExpensiveItem,
                  averageExpense: averageExpense,
                  topCategoryName: '-',
                  completionPercent: completionPercent,
                ),
                error: (_, _) => _buildStatisticsCards(
                  mostExpensiveItem: mostExpensiveItem,
                  averageExpense: averageExpense,
                  topCategoryName: '-',
                  completionPercent: completionPercent,
                ),
                data: (categories) {
                  final selectedCategory = _selectedCategoryId == null
                      ? null
                      : categories
                            .where((c) => c.id == _selectedCategoryId)
                            .firstOrNull;

                  final chartItems = _selectedCategoryId == null
                      ? _buildCategoryExpenseItems(purchasedItems, categories)
                      : _buildItemExpenseItems(purchasedItems);

                  final chartTitle = selectedCategory == null
                      ? 'Harcama Dağılımı'
                      : '${selectedCategory.name} Harcama Dağılımı';

                  final topExpenseName = chartItems.isEmpty
                      ? '-'
                      : chartItems.first.categoryName;

                  return Column(
                    children: [
                      _buildStatisticsCards(
                        mostExpensiveItem: mostExpensiveItem,
                        averageExpense: averageExpense,
                        topCategoryName: topExpenseName,
                        completionPercent: completionPercent,
                      ),
                      if (chartItems.isNotEmpty)
                        _buildPieChartCard(
                          chartItems,
                          title: chartTitle,
                          showLegendOnRight: _selectedCategoryId == null,
                        ),
                    ],
                  );
                },
              ),
              categoriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (categories) {
                  return _buildCategoryFilterBar(categories);
                },
              ),
              _buildSortBar(),
              if (sortedItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    'Henüz alınan ürün yok',
                    style: TextStyle(
                      color: Color(0xFF8A6B79),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Column(
                    children: sortedItems.map(_buildExpenseCard).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterBar(List<Category> categories) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        children: [
          _buildCategoryFilterChip(
            title: 'Tümü',
            isSelected: _selectedCategoryId == null,
            onTap: () {
              setState(() {
                _selectedCategoryId = null;
              });
            },
          ),
          ...categories.map((category) {
            return _buildCategoryFilterChip(
              title: category.name,
              isSelected: _selectedCategoryId == category.id,
              onTap: () {
                setState(() {
                  _selectedCategoryId = category.id;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChip({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD96BA7) : Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFD96BA7)
                  : const Color(0xFFFFD6EA),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF8A6B79),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  List<Item> _sortItems(List<Item> items) {
    final sortedItems = [...items];

    switch (_sortType) {
      case ExpenseSortType.dateDesc:
        sortedItems.sort(
          (a, b) => (b.purchaseDate ?? b.updateAt).compareTo(
            a.purchaseDate ?? a.updateAt,
          ),
        );
        break;

      case ExpenseSortType.dateAsc:
        sortedItems.sort(
          (a, b) => (a.purchaseDate ?? a.updateAt).compareTo(
            b.purchaseDate ?? b.updateAt,
          ),
        );
        break;

      case ExpenseSortType.priceDesc:
        sortedItems.sort(
          (a, b) => (b.purchasedPrice ?? 0).compareTo(a.purchasedPrice ?? 0),
        );
        break;

      case ExpenseSortType.priceAsc:
        sortedItems.sort(
          (a, b) => (a.purchasedPrice ?? 0).compareTo(b.purchasedPrice ?? 0),
        );
        break;
    }

    return sortedItems;
  }

  Widget _buildHeader(double totalExpense, int itemCount) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD96BA7), Color(0xFFFF8DBA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
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
            width: 48,
            height: 48,
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
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: totalExpense),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      value.toCurrency(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount alınan ürün',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards({
    required Item? mostExpensiveItem,
    required double averageExpense,
    required String topCategoryName,
    required double completionPercent,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  icon: Icons.emoji_events_outlined,
                  title: 'En Pahalı',
                  value: mostExpensiveItem == null
                      ? '-'
                      : (mostExpensiveItem.purchasedPrice ?? 0).toCurrency(),
                  subtitle: mostExpensiveItem?.name ?? '',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStatCard(
                  icon: Icons.calculate_outlined,
                  title: 'Ortalama',
                  value: averageExpense.toCurrency(),
                  subtitle: 'Ürün başı',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  icon: Icons.category_outlined,
                  title: 'En Çok Harcama',
                  value: topCategoryName,
                  subtitle: 'Kategori',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _buildCompletionBadgeCard(completionPercent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBadgeCard(double percent) {
    final badge = percent >= 100
        ? (Icons.verified_rounded, 'Tamamlandı')
        : percent >= 75
        ? (Icons.home_rounded, 'Neredeyse Hazır')
        : percent >= 50
        ? (Icons.diamond_rounded, 'Yaklaşıyor')
        : percent >= 25
        ? (Icons.local_florist_rounded, 'Hazırlık')
        : (Icons.eco_rounded, 'Başlangıç');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(badge.$1, color: const Color(0xFFD96BA7), size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  badge.$2,
                  style: const TextStyle(
                    color: Color(0xFF8A6B79),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '%${percent.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFF2C1E26),
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Alınan oranı',
            style: TextStyle(
              color: Color(0xFFB08A9A),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD6EA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD96BA7), size: 22),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8A6B79),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF2C1E26),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8A6B79),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: GestureDetector(
        onTap: _showSortBottomSheet,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFE3F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD96BA7).withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.sort_rounded, color: Color(0xFFD96BA7)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getSortTitle(_sortType),
                  style: const TextStyle(
                    color: Color(0xFF2C1E26),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF8A6B79),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF5FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6C2CC),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sıralama',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C1E26),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildSortOption(ExpenseSortType.dateDesc),
              _buildSortOption(ExpenseSortType.dateAsc),
              _buildSortOption(ExpenseSortType.priceDesc),
              _buildSortOption(ExpenseSortType.priceAsc),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(ExpenseSortType sortType) {
    final isSelected = _sortType == sortType;

    return GestureDetector(
      onTap: () {
        setState(() {
          _sortType = sortType;
        });

        Navigator.of(context).pop();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFE3F0) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD96BA7)
                : const Color(0xFFFFE3F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getSortIcon(sortType),
              color: isSelected
                  ? const Color(0xFFD96BA7)
                  : const Color(0xFF8A6B79),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getSortTitle(sortType),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? const Color(0xFFD96BA7)
                      : const Color(0xFF2C1E26),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFFD96BA7)),
          ],
        ),
      ),
    );
  }

  String _getSortTitle(ExpenseSortType sortType) {
    switch (sortType) {
      case ExpenseSortType.dateDesc:
        return 'En Yeni Ürünler';
      case ExpenseSortType.dateAsc:
        return 'En Eski Ürünler';
      case ExpenseSortType.priceDesc:
        return 'En Yüksek Fiyat';
      case ExpenseSortType.priceAsc:
        return 'En Düşük Fiyat';
    }
  }

  IconData _getSortIcon(ExpenseSortType sortType) {
    switch (sortType) {
      case ExpenseSortType.dateDesc:
        return Icons.calendar_month_rounded;
      case ExpenseSortType.dateAsc:
        return Icons.event_available_rounded;
      case ExpenseSortType.priceDesc:
        return Icons.trending_up_rounded;
      case ExpenseSortType.priceAsc:
        return Icons.trending_down_rounded;
    }
  }

  Widget _buildExpenseCard(Item item) {
    final price = item.purchasedPrice ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD6EA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.10),
            blurRadius: 16,
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
                      Icons.shopping_bag_outlined,
                      color: Color(0xFFD96BA7),
                      size: 22,
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
                  item.purchaseDate.toShortDateText(),
                  style: const TextStyle(
                    color: Color(0xFF8A6B79),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price.toCurrency(),
            style: const TextStyle(
              color: Color(0xFFD96BA7),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  List<CategoryExpenseChartItem> _buildCategoryExpenseItems(
    List<Item> items,
    List<Category> categories,
  ) {
    final Map<int, double> totalsByCategory = {};

    for (final item in items) {
      final price = item.purchasedPrice ?? 0;

      totalsByCategory[item.categoryId] =
          (totalsByCategory[item.categoryId] ?? 0) + price;
    }

    final chartItems = totalsByCategory.entries
        .where((entry) => entry.value > 0)
        .map((entry) {
          final category = categories
              .where((category) => category.id == entry.key)
              .firstOrNull;

          final categoryName = category?.name ?? 'Diğer';

          return CategoryExpenseChartItem(
            categoryName: categoryName,
            amount: entry.value,
            color: _categoryColor(categoryName),
          );
        })
        .toList();

    chartItems.sort((a, b) => b.amount.compareTo(a.amount));

    return chartItems;
  }

  List<CategoryExpenseChartItem> _buildItemExpenseItems(List<Item> items) {
    final Map<String, double> totalsByItemName = {};

    for (final item in items) {
      final price = item.purchasedPrice ?? 0;
      if (price <= 0) continue;

      final itemName = item.name.trim();

      totalsByItemName[itemName] = (totalsByItemName[itemName] ?? 0) + price;
    }

    int colorIndex = 0;

    final chartItems = totalsByItemName.entries.map((entry) {
      final item = CategoryExpenseChartItem(
        categoryName: entry.key,

        amount: entry.value,

        color: _chartColors[colorIndex % _chartColors.length],
      );

      colorIndex++;

      return item;
    }).toList();

    chartItems.sort((a, b) => b.amount.compareTo(a.amount));

    return chartItems;
  }

  Color _categoryColor(String categoryName) {
    final index = categoryName.hashCode.abs() % _chartColors.length;
    return _chartColors[index];
  }

  static const List<Color> _chartColors = [
    Color(0xFFD96BA7),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFFFB74D),
    Color(0xFF7E57C2),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFF5C6BC0),
    Color(0xFFFF7043),
    Color(0xFFAB47BC),
    Color(0xFF29B6F6),
    Color(0xFF9CCC65),
    Color(0xFFFFCA28),
    Color(0xFFEC407A),
    Color(0xFF8D6E63),
    Color(0xFF78909C),
    Color(0xFF26C6DA),
    Color(0xFFFF8A65),
    Color(0xFF9575CD),
    Color(0xFF4DB6AC),
  ];

  Widget _buildPieChartCard(
    List<CategoryExpenseChartItem> items, {
    String title = 'Harcama Dağılımı',
    bool showLegendOnRight = true,
  }) {
    final total = items.fold<double>(0, (sum, item) => sum + item.amount);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Harcama Dağılımı',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),

          if (showLegendOnRight)
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            centerSpaceRadius: 42,
                            sectionsSpace: 2,
                            sections: items.map((item) {
                              final percent = total == 0
                                  ? 0
                                  : (item.amount / total) * 100;

                              return PieChartSectionData(
                                color: item.color,
                                value: item.amount,
                                title: '%${percent.toStringAsFixed(0)}',
                                radius: 42,
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatChartAmount(total),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2C1E26),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              title == 'Harcama Dağılımı'
                                  ? 'Toplam'
                                  : title.replaceAll(' Harcama Dağılımı', ''),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8A6B79),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: items.map((item) {
                        final percent = total == 0
                            ? 0
                            : (item.amount / total) * 100;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.categoryName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                '%${percent.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            SizedBox(
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 38,
                      sectionsSpace: 2,
                      sections: items.map((item) {
                        final percent = total == 0
                            ? 0
                            : (item.amount / total) * 100;

                        return PieChartSectionData(
                          color: item.color,
                          value: item.amount,
                          title: percent >= 8
                              ? '%${percent.toStringAsFixed(0)}'
                              : '',
                          radius: 44,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatChartAmount(total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2C1E26),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title.replaceAll(' Harcama Dağılımı', ''),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A6B79),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            ...items.take(5).map((item) {
              final percent = total == 0 ? 0 : (item.amount / total) * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C1E26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.amount.toCurrency(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A6B79),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '%${percent.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2C1E26),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

String _formatChartAmount(double value) {
  if (value >= 1000000) {
    return '₺${(value / 1000000).toStringAsFixed(1)}M';
  }

  if (value >= 1000) {
    return '₺${(value / 1000).toStringAsFixed(0)}K';
  }

  return value.toCurrency();
}

class CategoryExpenseChartItem {
  const CategoryExpenseChartItem({
    required this.categoryName,
    required this.amount,
    required this.color,
  });

  final String categoryName;
  final double amount;
  final Color color;
}
