import 'dart:async';

import 'package:ceyizim_plus/core/database/app_database.dart';
import 'package:ceyizim_plus/core/database/database_provider.dart';
import 'package:ceyizim_plus/core/extensions/currency_extensions.dart';
import 'package:ceyizim_plus/core/extensions/date_extensions.dart';
import 'package:ceyizim_plus/core/notifications/notification_planner_service.dart';
import 'package:ceyizim_plus/core/sync/sync_status.dart';
import 'package:ceyizim_plus/core/widgets/skeleton_loader.dart';
import 'package:ceyizim_plus/features/auth/data/auth_providers.dart';
import 'package:ceyizim_plus/features/auth/data/auth_service.dart';
import 'package:ceyizim_plus/features/budget/presentation/budget_screen.dart';
import 'package:ceyizim_plus/features/budget/data/budget_providers.dart';
import 'package:ceyizim_plus/features/categories/data/category_providers.dart';
import 'package:ceyizim_plus/features/categories/presentation/category_detail_screen.dart';
import 'package:ceyizim_plus/features/categories/presentation/category_management_screen.dart';
import 'package:ceyizim_plus/features/expenses/presentation/expense_detail_screen.dart';
import 'package:ceyizim_plus/features/export/data/excel_export_service.dart';
import 'package:ceyizim_plus/features/export/data/pdf_report_service.dart';
import 'package:ceyizim_plus/features/items/data/item_providers.dart';
import 'package:ceyizim_plus/features/items/data/item_repository_provider.dart';
import 'package:ceyizim_plus/features/items/domain/planned_item_filter.dart';
import 'package:ceyizim_plus/features/items/presentation/item_form_screen.dart';
import 'package:ceyizim_plus/features/items/presentation/item_list_screen.dart';
import 'package:ceyizim_plus/features/items/presentation/planned_items_screen.dart';
import 'package:ceyizim_plus/features/items/presentation/recent_purchased_screen.dart';
import 'package:ceyizim_plus/features/insights/presentation/smart_insights_screen.dart';
import 'package:ceyizim_plus/features/notifications/data/notification_providers.dart';
import 'package:ceyizim_plus/features/notifications/models/shared_notification.dart';
import 'package:ceyizim_plus/features/notifications/presentation/shared_notifications_screen.dart';
import 'package:ceyizim_plus/features/shared_lists/data/shared_list_providers.dart';
import 'package:ceyizim_plus/features/shared_lists/models/shared_member.dart';
import 'package:ceyizim_plus/features/shared_lists/presentation/share_list_bottom_sheet.dart';
import 'package:ceyizim_plus/features/templates/presentation/template_preview_screen.dart';
import 'package:ceyizim_plus/features/settings/presentation/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  StreamSubscription<void>? _sharedItemsSubscription;
  StreamSubscription<void>? _sharedCategoriesSubscription;
  bool _syncRetryScheduled = false;
  final Set<int> _collapsedCategoryIds = <int>{};

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface => _isDark ? const Color(0xFF2A2027) : Colors.white;
  Color get _surfaceSoft =>
      _isDark ? const Color(0xFF352832) : const Color(0xFFFFF7FB);
  Color get _primaryText =>
      _isDark ? const Color(0xFFFFF4F8) : const Color(0xFF2C1E26);
  Color get _secondaryText =>
      _isDark ? const Color(0xFFD7BAC8) : const Color(0xFF8A6B79);
  Color get _outline =>
      _isDark ? const Color(0xFF604451) : const Color(0xFFFFD6EA);

  @override
  void dispose() {
    _sharedItemsSubscription?.cancel();

    _sharedCategoriesSubscription?.cancel();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(_initializeSharedData);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _checkTodayPlannedItemsNotification();
      } catch (error, stackTrace) {
        debugPrint('NOTIFICATION_ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }

  Future<void> _initializeSharedData() async {
    try {
      await FirebaseAuth.instance.authStateChanges().firstWhere(
        (user) => user != null,
      );

      final categoryRepository = ref.read(categoryRepositoryProvider);

      await categoryRepository.insertDefaultCategories();

      await _startSharedCategoriesListener();
      await _startSharedItemsListener();
    } catch (error, stackTrace) {
      debugPrint('HOME_INIT_ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _startSharedItemsListener() async {
    try {
      await _sharedItemsSubscription?.cancel();
      _sharedItemsSubscription = null;

      await ref.read(activeListIdProvider.future);

      final repository = ref.read(itemRepositoryProvider);

      await repository.syncItemsFromFirestore();

      final subscription = repository.watchSharedListItems().listen(
        (_) {},
        onError: (error, stackTrace) {
          debugPrint('SHARED_ITEMS_LISTENER_ERROR: $error');
          debugPrintStack(stackTrace: stackTrace);
          _scheduleSyncRetry();
        },
      );

      _sharedItemsSubscription = subscription;
    } catch (error, stackTrace) {
      debugPrint('START_SHARED_ITEMS_LISTENER_ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _checkTodayPlannedItemsNotification() async {
    final database = ref.read(appDatabaseProvider);

    await NotificationPlannerService.checkTodayItems(database);
  }

  Widget _buildHomeSkeleton() => const Padding(
    padding: EdgeInsets.only(top: 4),
    child: SkeletonLoader(height: 132),
  );

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    final allItemsAsync = ref.watch(allItemsProvider);
    final groupedItemsAsync = ref.watch(groupedItemsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF181217)
          : const Color(0xFFFFF5FA),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ItemFormScreen()));
        },
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF181217), Color(0xFF21191E)]
                : const [Color(0xFFFFF5FA), Color(0xFFFFF7F0)],
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
                    loading: () => _buildTopBar([]),
                    error: (_, _) => _buildTopBar([]),
                    data: (allItems) => _buildTopBar(allItems),
                  ),
                  _buildSyncStatusBanner(),
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
                    loading: _buildHomeSkeleton,
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text('Hata: $error')),
                    ),
                    data: (groupedItems) {
                      final hasAnyItem = groupedItems.values.any(
                        (items) => items.isNotEmpty,
                      );

                      if (!hasAnyItem) {
                        return Column(
                          children: [
                            _buildEmptyState(),
                            const SizedBox(height: 90),
                          ],
                        );
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

  Widget _buildTopBar(List<Item> allItems) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/branding/app_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Çeyizim',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF8E244E),
                ),
              ),
              const Text(
                '+',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF5B9A),
                ),
              ),
            ],
          ),

          Positioned(
            right: 0,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F7),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () => _showHomeMenu(allItems),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSharedCategoriesListener() async {
    try {
      await _sharedCategoriesSubscription?.cancel();
      _sharedCategoriesSubscription = null;

      final repository = ref.read(categoryRepositoryProvider);

      await repository.syncCategoriesFromFirestore();

      _sharedCategoriesSubscription = repository
          .watchSharedListCategories()
          .listen(
            (_) {},
            onError: (error, stackTrace) async {
              debugPrint('SHARED_CATEGORIES_LISTENER_ERROR: $error');

              await _sharedCategoriesSubscription?.cancel();
              _sharedCategoriesSubscription = null;
              _scheduleSyncRetry();
            },
          );
    } catch (error, stackTrace) {
      debugPrint('START_SHARED_CATEGORIES_LISTENER_ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _scheduleSyncRetry() {
    if (_syncRetryScheduled || !mounted) return;
    _syncRetryScheduled = true;

    Future<void>.delayed(const Duration(seconds: 3), () async {
      _syncRetryScheduled = false;
      if (!mounted) return;
      await _startSharedCategoriesListener();
      await _startSharedItemsListener();
    });
  }

  Widget _buildSyncStatusBanner() {
    final statusAsync = ref.watch(sharedItemsSyncStatusProvider);
    final status =
        statusAsync.value ??
        (statusAsync.hasError ? SyncStatus.error : SyncStatus.syncing);

    if (status == SyncStatus.synced) return const SizedBox.shrink();

    final color = switch (status) {
      SyncStatus.syncing => const Color(0xFF7B61A8),
      SyncStatus.offline => const Color(0xFFE08A24),
      SyncStatus.error => const Color(0xFFC44747),
      SyncStatus.synced => const Color(0xFF3D9C68),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: status == SyncStatus.error
              ? () async {
                  ref.invalidate(sharedItemsSyncStatusProvider);
                  await _startSharedCategoriesListener();
                  await _startSharedItemsListener();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                if (status == SyncStatus.syncing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                else
                  Icon(
                    status == SyncStatus.offline
                        ? Icons.cloud_off_rounded
                        : Icons.sync_problem_rounded,
                    size: 18,
                    color: color,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(List<Item> items) {
    final membersAsync = ref.watch(membersProvider);
    final notificationsAsync = ref.watch(sharedNotificationsProvider);

    final total = items.length;

    final purchased = items.where((e) => e.isPurchased).length;

    final remaining = total - purchased;

    final totalExpense = items
        .where((e) => e.isPurchased)
        .fold<double>(0, (sum, item) => sum + (item.purchasedPrice ?? 0));

    final upcomingItems = items.where((item) {
      if (item.isPurchased || item.estimatedPurchaseDate == null) {
        return false;
      }

      final today = DateTime.now();

      final targetDate = DateTime.fromMillisecondsSinceEpoch(
        item.estimatedPurchaseDate!,
      );

      return targetDate.year == today.year &&
          targetDate.month == today.month &&
          targetDate.day == today.day;
    }).toList();

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

        membersAsync.when(
          data: (members) {
            if (members.length <= 1) {
              return const SizedBox.shrink();
            }

            return notificationsAsync.when(
              data: (notifications) {
                final currentUid = FirebaseAuth.instance.currentUser?.uid;

                final myMember = members
                    .where((m) => m.uid == currentUid)
                    .cast<SharedMember?>()
                    .firstOrNull;

                final joinedAtMs = myMember?.joinedAtMs ?? 0;

                final otherNotifications = notifications
                    .where((n) => n.createdBy != currentUid)
                    .where((n) => n.createdAt >= joinedAtMs)
                    .toList();

                if (otherNotifications.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    const SizedBox(height: 14),
                    _buildSharedActivityCard(otherNotifications),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

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
            child: SingleChildScrollView(
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
                    icon: Icons.savings_outlined,
                    title: 'Bütçe Planı',
                    subtitle: 'Bütçe, harcama ve kalan tutarı izle',
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BudgetScreen()),
                      );
                    },
                  ),

                  _buildHomeMenuTile(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Akıllı Öneriler',
                    subtitle: 'Eksikleri, öncelikleri ve bütçe riskini gör',
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SmartInsightsScreen(),
                        ),
                      );
                    },
                  ),

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
                    subtitle: 'Davet kodu ile ortak liste oluştur',
                    onTap: () async {
                      Navigator.of(bottomSheetContext).pop();

                      final result = await showModalBottomSheet<bool>(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        enableDrag: true,
                        isDismissible: true,
                        builder: (_) => ShareListBottomSheet(
                          onBeforeLeaveList: _stopSharedListeners,
                        ),
                      );

                      if (result == true && mounted) {
                        await _startSharedItemsListener();
                        await _startSharedCategoriesListener();

                        ref.invalidate(activeListIdProvider);

                        ref.invalidate(inviteCodeProvider);

                        ref.invalidate(membersProvider);

                        ref.invalidate(notificationRepositoryProvider);

                        ref.invalidate(sharedNotificationsProvider);

                        ref.invalidate(categoriesProvider);
                      }
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
                    icon: Icons.picture_as_pdf_rounded,
                    title: 'PDF Raporu Oluştur',
                    subtitle: 'İlerleme ve harcama raporunu paylaş',
                    onTap: () async {
                      Navigator.of(bottomSheetContext).pop();
                      try {
                        final categories =
                            ref.read(categoriesProvider).value ?? <Category>[];
                        final budget = await ref.read(budgetProvider.future);
                        await PdfReportService.createAndShare(
                          items: allItems,
                          categories: categories,
                          budget: budget,
                        );
                      } catch (error) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('PDF oluşturulamadı: $error'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
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

                  _buildHomeMenuTile(
                    icon: Icons.settings_outlined,
                    title: 'Ayarlar ve Hakkında',
                    subtitle: 'Yenilikler, geri bildirim ve uygulama sürümü',
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _stopSharedListeners() async {
    await _sharedItemsSubscription?.cancel();
    _sharedItemsSubscription = null;

    await _sharedCategoriesSubscription?.cancel();
    _sharedCategoriesSubscription = null;
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
        color: _surfaceSoft,
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: _primaryText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: _secondaryText),
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
          color: _surface,
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
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${firstItem.name} • ${firstItem.estimatedPurchaseDate.toShortDateText()}',
                    style: TextStyle(
                      color: _secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _secondaryText),
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
    final cardColor = _isDark
        ? Color.alphaBlend(color.withValues(alpha: .15), _surface)
        : color.withValues(alpha: .14);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: _isDark ? color.withValues(alpha: .45) : Colors.white,
            ),
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
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: _primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: _secondaryText,
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
        color: isSelected ? null : _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? Colors.transparent : _outline),
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
          color: isSelected ? Colors.white : _primaryText,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFD6EA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD9EB), Color(0xFFFFF1F8)],
              ),
            ),
            child: const Center(
              child: Text('🎁', style: TextStyle(fontSize: 40)),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Çeyiz listen hazır değil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2C1E26),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'İlk ürününü ekleyerek çeyiz planlamana başlayabilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8A6B79),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const TemplatePreviewScreen(title: 'Hazır Çeyiz Şablonu'),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Color(0xFFD96BA7),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Hazır şablonları kullan',
                    style: TextStyle(
                      color: Color(0xFFD96BA7),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedActivityCard(List<SharedNotification> notifications) {
    final latest = notifications.first;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SharedNotificationsScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE7D6FF)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.groups_rounded, color: Color(0xFF8B5CF6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${notifications.length} ortak liste hareketi',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    latest.message,
                    style: TextStyle(
                      color: _secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _secondaryText),
          ],
        ),
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
    final isCollapsed = _collapsedCategoryIds.contains(category.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _outline, width: 1.1),
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
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              isCollapsed
                  ? _collapsedCategoryIds.remove(category.id)
                  : _collapsedCategoryIds.add(category.id);
            }),
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _primaryText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${items.length} ürün',
                        style: TextStyle(
                          fontSize: 12,
                          color: _secondaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isCollapsed ? 0 : .5,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (!isCollapsed) ...[
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    _openCategoryDetail(category, items, currentFilter),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('Kategori detayı'),
              ),
            ),
          ],
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
          color: color.withValues(alpha: _isDark ? 0.22 : 0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _secondaryText,
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
            color: color.withValues(
              alpha: _isDark
                  ? (onTap == null ? 0.12 : 0.22)
                  : (onTap == null ? 0.07 : 0.14),
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _secondaryText,
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
          color: _surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _outline),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Son Alınanlar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Son 7 günde aldığın ürünleri görüntüle',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push<Map<String, int>>(
          MaterialPageRoute(
            builder: (_) =>
                const TemplatePreviewScreen(title: 'Hazır Çeyiz Şablonu'),
          ),
        );

        if (result == null) {
          return;
        }

        final addedCount = result['addedCount'] ?? 0;
        final skippedCount = result['skippedCount'] ?? 0;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          ref.invalidate(allItemsProvider);
        });

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$addedCount ürün eklendi. $skippedCount ürün zaten vardı.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _outline),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hazır Çeyiz Şablonu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hazır Liste İle Hemen Başla',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _secondaryText),
          ],
        ),
      ),
    );
  }
}
