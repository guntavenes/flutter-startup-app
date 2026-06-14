import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/core/database/database_provider.dart';
import 'package:flutter_startup_app/core/extensions/currency_extensions.dart';
import 'package:flutter_startup_app/core/extensions/date_extensions.dart';
import 'package:flutter_startup_app/core/notifications/notification_planner_service.dart';
import 'package:flutter_startup_app/features/auth/data/auth_providers.dart';
import 'package:flutter_startup_app/features/auth/data/auth_service.dart';
import 'package:flutter_startup_app/features/categories/data/category_providers.dart';
import 'package:flutter_startup_app/features/categories/presentation/category_detail_screen.dart';
import 'package:flutter_startup_app/features/expenses/presentation/expense_detail_screen.dart';
import 'package:flutter_startup_app/features/export/data/excel_export_service.dart';
import 'package:flutter_startup_app/features/items/data/item_providers.dart';
import 'package:flutter_startup_app/features/items/data/item_repository_provider.dart';
import 'package:flutter_startup_app/features/items/domain/planned_item_filter.dart';
import 'package:flutter_startup_app/features/items/presentation/item_form_screen.dart';
import 'package:flutter_startup_app/features/items/presentation/item_list_screen.dart';
import 'package:flutter_startup_app/features/items/presentation/planned_items_screen.dart';
import 'package:flutter_startup_app/features/items/presentation/recent_purchased_screen.dart';
import 'package:flutter_startup_app/features/templates/presentation/template_preview_screen.dart';
import 'package:flutter_startup_app/features/categories/presentation/category_management_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final repository = ref.read(itemRepositoryProvider);

      await repository.syncItemsFromFirestore();

      ref.invalidate(allItemsProvider);

      ref.invalidate(groupedItemsProvider);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _checkTodayPlannedItemsNotification();
      } catch (e, s) {
        debugPrint('NOTIFICATION_ERROR: $e');
        debugPrintStack(stackTrace: s);
      }
    });
  }

  Future<void> _checkTodayPlannedItemsNotification() async {
    final database = ref.read(appDatabaseProvider);

    await NotificationPlannerService.checkTodayItems(database);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.value;
    final allItemsAsync = ref.watch(allItemsProvider);
    final groupedItemsAsync = ref.watch(groupedItemsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
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
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  allItemsAsync.when(
                    loading: () => _buildHeader([], currentUser),
                    error: (_, _) => _buildHeader([], currentUser),
                    data: (allItems) => _buildHeader(allItems, currentUser),
                  ),
                  const SizedBox(height: 14),
                  allItemsAsync.when(
                    loading: () => _buildSummary([]),
                    error: (_, _) => _buildSummary([]),
                    data: (allItems) => _buildSummary(allItems),
                  ),
                  const SizedBox(height: 10),
                  _buildRecentPurchasedCard(),
                  const SizedBox(height: 10),
                  _buildTemplateCard(),
                  const SizedBox(height: 12),
                  allItemsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (allItems) {
                      if (allItems.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: [_buildFilters(), const SizedBox(height: 12)],
                      );
                    },
                  ),
                  groupedItemsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text('Hata: $error')),
                    ),
                    data: (groupedItems) {
                      final hasAnyItem = groupedItems.values.any(
                        (items) => items.isNotEmpty,
                      );

                      if (!hasAnyItem) {
                        return _buildEmptyState();
                      }

                      return _buildGroupedItemList(groupedItems);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(List<Item> allItems, User? user) {
    final isAnonymous = user?.isAnonymous ?? true;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC7E3), Color(0xFFFFEEF7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('🎁', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Çeyiz Özeti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C1E26),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Listen, harcamaların ve planların',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A6B79),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF6D4C5B)),
            onPressed: () => _showHomeMenu(allItems),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<Item> items) {
    final total = items.length;
    final purchased = items.where((e) => e.isPurchased).length;
    final remaining = total - purchased;
    final upcomingItems = _getUpcomingItems(items);

    final totalExpense = items
        .where((e) => e.isPurchased)
        .fold<double>(0, (sum, item) => sum + (item.purchasedPrice ?? 0));

    return Column(
      children: [
        Row(
          children: [
            _summaryCard(
              'Toplam',
              total.toString(),
              Icons.list_alt_rounded,
              const Color(0xFFFF8DBA),
              onTap: () => _openItemList('Tüm Ürünler', items, ItemFilter.all),
            ),
            const SizedBox(width: 10),
            _summaryCard(
              'Alınan',
              purchased.toString(),
              Icons.check_circle_rounded,
              const Color(0xFF7ACFA6),
              onTap: () => _openItemList(
                'Alınan Ürünler',
                items.where((e) => e.isPurchased).toList(),
                ItemFilter.purchased,
              ),
            ),
            const SizedBox(width: 10),
            _summaryCard(
              'Kalan',
              remaining.toString(),
              Icons.hourglass_bottom_rounded,
              const Color(0xFFFFB74D),
              onTap: () => _openItemList(
                'Kalan Ürünler',
                items.where((e) => !e.isPurchased).toList(),
                ItemFilter.remaining,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _expenseCard(totalExpense, items),
        if (upcomingItems.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildUpcomingCard(upcomingItems),
        ],
      ],
    );
  }

  Future<void> _showHomeMenu(List<Item> allItems) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8D3DD),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFC1DE), Color(0xFFD96BA7)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menü',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2C1E26),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Liste ayarları ve dışa aktarma',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9A7A89),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _buildHomeMenuTile(
                  icon: Icons.category_outlined,
                  title: 'Kategorileri Yönet',
                  subtitle: 'Kategori ekle, düzenle veya sil',
                  onTap: () async {
                    Navigator.of(bottomSheetContext).pop();

                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CategoryManagementScreen(),
                      ),
                    );

                    if (!mounted) return;

                    ref.invalidate(categoriesProvider);
                    ref.invalidate(groupedItemsProvider);
                  },
                ),

                _buildHomeMenuTile(
                  icon: Icons.ios_share_rounded,
                  title: 'Paylaş',
                  subtitle: 'Liste paylaşımı için hazırlanıyor',
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Paylaş özelliği yakında eklenecek.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                _buildHomeMenuTile(
                  icon: Icons.table_chart_rounded,
                  title: 'Excel Olarak Dışa Aktar',
                  subtitle: 'Listeyi Excel dosyası olarak oluştur',
                  onTap: () async {
                    Navigator.of(bottomSheetContext).pop();

                    final path = await ExcelExportService.exportItems(
                      items: allItems,
                    );

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          path == null
                              ? 'Excel dosyası oluşturulamadı.'
                              : 'Excel çıktısı hazırlandı.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                _buildHomeMenuTile(
                  icon: Icons.login_rounded,
                  title: 'Google Hesabına Geç',
                  subtitle: 'Verilerini Google hesabınla eşitle',
                  onTap: () async {
                    Navigator.of(bottomSheetContext).pop();

                    try {
                      await AuthService.linkAnonymousUserWithGoogle();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Google hesabına geçildi.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (error) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Google giriş hatası: $error'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFFFF6FA),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD6EA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: const Color(0xFFD96BA7), size: 24),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2C1E26),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9A7A89),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB48A9D),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingCard(List<Item> items) {
    final firstItem = items.first;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                const PlannedItemsScreen(filter: PlannedItemFilter.today),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFD59E)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${items.length} yaklaşan alım',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C1E26),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${firstItem.name} • ${firstItem.estimatedPurchaseDate.toShortDateText()}',
                    style: const TextStyle(
                      color: Color(0xFF8A6B79),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A6B79)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                  fontSize: 19,
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
      ),
    );
  }

  void _openItemList(String title, List<Item> items, ItemFilter filter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ItemListScreen(title: title, items: items, filter: filter),
      ),
    );
  }

  Widget _expenseCard(double totalExpense, List<Item> items) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ExpenseDetailScreen(items: items)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
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
              width: 40,
              height: 40,
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
                    totalExpense.toCurrency(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final current = ref.watch(itemFilterProvider);

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (current == ItemFilter.all) {
              return;
            }

            ref.read(itemFilterProvider.notifier).state = ItemFilter.all;
          },
          child: _filterChip('Tümü', current == ItemFilter.all),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            if (current == ItemFilter.remaining) {
              return;
            }

            ref.read(itemFilterProvider.notifier).state = ItemFilter.remaining;
          },
          child: _filterChip('Kalan', current == ItemFilter.remaining),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            if (current == ItemFilter.purchased) {
              return;
            }

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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            'Bu filtrede ürün yok',
            style: TextStyle(
              color: Color(0xFF8A6B79),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ...categories.map((category) {
          final allCategoryItems = groupedItems[category]!;
          final visibleItems = _filterCategoryItems(allCategoryItems);

          return _buildCategoryCard(category, visibleItems);
        }),
        const SizedBox(height: 100),
      ],
    );
  }

  List<Item> _filterCategoryItems(List<Item> items) {
    final currentFilter = ref.read(itemFilterProvider);

    switch (currentFilter) {
      case ItemFilter.remaining:
        return items.where((item) => !item.isPurchased).toList();

      case ItemFilter.purchased:
        return items.where((item) => item.isPurchased).toList();

      case ItemFilter.all:
        return items;
    }
  }

  Future<void> _openCategoryDetail(
    Category category,
    List<Item> items,
    ItemFilter filter,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(
          category: category,
          items: items,
          filter: filter,
        ),
      ),
    );

    if (result == true) {
      ref.invalidate(allItemsProvider);
      ref.invalidate(groupedItemsProvider);
    }
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFFFFD6EA)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, color: Color(0xFFD96BA7), size: 34),
          SizedBox(height: 10),
          Text(
            'Henüz ürün eklenmedi',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF2C1E26),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Hazır çeyiz listesiyle başlayabilir veya + ile ürün ekleyebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8A6B79),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category, List<Item> items) {
    final currentFilter = ref.watch(itemFilterProvider);

    final purchasedItems = items.where((e) => e.isPurchased).toList();
    final remainingItems = items.where((e) => !e.isPurchased).toList();

    final purchasedCount = purchasedItems.length;
    final remainingCount = remainingItems.length;

    final totalExpense = purchasedItems.fold<double>(
      0,
      (sum, item) => sum + (item.purchasedPrice ?? 0),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD6EA), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              _openCategoryDetail(category, items, currentFilter);
            },
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFC7E3), Color(0xFFFFEEF7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getCategoryIcon(category.name),
                    color: const Color(0xFFD96BA7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
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
                        '${items.length} ürün',
                        style: const TextStyle(
                          fontSize: 12,
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
          ),
          const SizedBox(height: 12),

          if (currentFilter == ItemFilter.all) ...[
            Row(
              children: [
                _miniInfoCard(
                  'Alınan',
                  purchasedCount.toString(),
                  const Color(0xFF7ACFA6),
                  onTap: purchasedCount == 0
                      ? null
                      : () {
                          _openCategoryDetail(
                            category,
                            purchasedItems,
                            ItemFilter.purchased,
                          );
                        },
                ),
                const SizedBox(width: 10),
                _miniInfoCard(
                  'Kalan',
                  remainingCount.toString(),
                  const Color(0xFFFFB74D),
                  onTap: remainingCount == 0
                      ? null
                      : () {
                          _openCategoryDetail(
                            category,
                            remainingItems,
                            ItemFilter.remaining,
                          );
                        },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else if (currentFilter == ItemFilter.remaining) ...[
            _singleInfoCard(
              'Kalan Ürün',
              items.length.toString(),
              const Color(0xFFFFB74D),
              onTap: () {
                _openCategoryDetail(category, items, ItemFilter.remaining);
              },
            ),
            const SizedBox(height: 12),
          ] else if (currentFilter == ItemFilter.purchased) ...[
            _singleInfoCard(
              'Alınan Ürün',
              items.length.toString(),
              const Color(0xFF7ACFA6),
              onTap: () {
                _openCategoryDetail(category, items, ItemFilter.purchased);
              },
            ),
            const SizedBox(height: 12),
          ],

          if (currentFilter != ItemFilter.remaining)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Toplam Harcama',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalExpense.toCurrency(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD96BA7),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _singleInfoCard(
    String title,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C1E26),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A6B79),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniInfoCard(
    String title,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: onTap == null ? 0.07 : 0.14),
            borderRadius: BorderRadius.circular(15),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8A6B79),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('mutfak')) {
      return Icons.restaurant_menu_rounded;
    }

    if (name.contains('yatak')) {
      return Icons.bed_rounded;
    }

    if (name.contains('banyo')) {
      return Icons.shower_rounded;
    }

    if (name.contains('salon')) {
      return Icons.chair_rounded;
    }

    if (name.contains('elektronik')) {
      return Icons.devices_rounded;
    }

    return Icons.category_rounded;
  }

  Widget _buildRecentPurchasedCard() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecentPurchasedScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD96BA7).withValues(alpha: 0.10),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD96BA7), Color(0xFFFF8DBA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.shopping_cart_checkout_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Son Alınanlar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C1E26),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Son 7 günde aldığın ürünleri görüntüle',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A6B79),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A6B79)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                const TemplatePreviewScreen(title: 'Hazır Çeyiz Şablonu'),
          ),
        );

        if (result != null && context.mounted) {
          Future.microtask(() {
            ref.invalidate(allItemsProvider);
            ref.invalidate(groupedItemsProvider);
          });
        }

        final addedCount = result['addedCount'] ?? 0;
        final skippedCount = result['skippedCount'] ?? 0;

        final message = addedCount > 0
            ? '$addedCount ürün listene eklendi. $skippedCount ürün zaten vardı.'
            : 'Seçili ürünler zaten listende vardı.';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD96BA7).withValues(alpha: 0.10),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFD96BA7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.playlist_add_check_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hazır Çeyiz Şablonu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C1E26),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hazır Liste İle Hemen Başla',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A6B79),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A6B79)),
          ],
        ),
      ),
    );
  }

  List<Item> _getUpcomingItems(List<Item> items) {
    final now = DateTime.now();

    return items.where((item) {
      if (item.isPurchased) {
        return false;
      }

      if (item.estimatedPurchaseDate == null) {
        return false;
      }

      final estimatedDate = DateTime.fromMillisecondsSinceEpoch(
        item.estimatedPurchaseDate!,
      );

      final diff = estimatedDate.difference(now).inDays;

      return diff >= 0 && diff <= 7;
    }).toList();
  }
}
