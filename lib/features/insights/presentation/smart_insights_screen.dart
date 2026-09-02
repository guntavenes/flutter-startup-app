import 'package:ceyizim_plus/core/database/app_database.dart';
import 'package:ceyizim_plus/core/extensions/currency_extensions.dart';
import 'package:ceyizim_plus/features/budget/data/budget_providers.dart';
import 'package:ceyizim_plus/features/categories/data/category_providers.dart';
import 'package:ceyizim_plus/features/items/data/item_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SmartInsightsScreen extends ConsumerWidget {
  const SmartInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(allItemsProvider);
    final categories = ref.watch(categoriesProvider).value ?? <Category>[];
    final budget = ref.watch(budgetProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Akıllı Öneriler')),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Öneriler hazırlanamadı.')),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyInsights();
          }
          final insights = _buildInsights(items, categories, budget);
          final purchased = items.where((item) => item.isPurchased).length;
          final progress = purchased / items.length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Genel ilerleme',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '%${(progress * 100).round()} tamamlandı · ${items.length - purchased} ürün kaldı',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...insights.map(
                (insight) => Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: insight.color.withValues(alpha: .12),
                      child: Icon(insight.icon, color: insight.color),
                    ),
                    title: Text(
                      insight.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(insight.description),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_Insight> _buildInsights(
    List<Item> items,
    List<Category> categories,
    double? budget,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final pending = items.where((item) => !item.isPurchased).toList();
    final overdue = pending
        .where(
          (item) =>
              item.estimatedPurchaseDate != null &&
              item.estimatedPurchaseDate! < now,
        )
        .length;
    final missingPrice = pending
        .where((item) => item.plannedPrice == null || item.plannedPrice! <= 0)
        .length;
    final spent = items
        .where((item) => item.isPurchased)
        .fold<double>(0, (sum, item) => sum + (item.purchasedPrice ?? 0));
    final planned = pending.fold<double>(
      0,
      (sum, item) => sum + (item.plannedPrice ?? 0),
    );
    final normalized = <String, int>{};
    for (final item in items) {
      final key = item.name.trim().toLowerCase();
      normalized[key] = (normalized[key] ?? 0) + 1;
    }
    final duplicates = normalized.values.where((count) => count > 1).length;
    Category? slowest;
    double slowestRate = 2;
    for (final category in categories) {
      final categoryItems = items
          .where((item) => item.categoryId == category.id)
          .toList();
      if (categoryItems.isEmpty) continue;
      final rate =
          categoryItems.where((item) => item.isPurchased).length /
          categoryItems.length;
      if (rate < slowestRate) {
        slowestRate = rate;
        slowest = category;
      }
    }

    return [
      if (budget != null)
        _Insight(
          icon: spent + planned > budget
              ? Icons.warning_amber_rounded
              : Icons.savings_outlined,
          color: spent + planned > budget ? Colors.deepOrange : Colors.green,
          title: spent + planned > budget
              ? 'Bütçe riski var'
              : 'Bütçe planı dengeli',
          description: spent + planned > budget
              ? 'Mevcut harcama ve planlanan ürünler bütçeyi ${(spent + planned - budget).toCurrency()} aşabilir.'
              : 'Plan tamamlandığında yaklaşık ${(budget - spent - planned).toCurrency()} bütçe kalıyor.',
        ),
      if (overdue > 0)
        _Insight(
          icon: Icons.event_busy_outlined,
          color: Colors.redAccent,
          title: '$overdue ürünün hedef tarihi geçti',
          description:
              'Satın alma tarihlerini güncelleyerek planını gerçekçi tutabilirsin.',
        ),
      if (missingPrice > 0)
        _Insight(
          icon: Icons.sell_outlined,
          color: Colors.orange,
          title: '$missingPrice üründe fiyat eksik',
          description:
              'Tahmini fiyatları girersen bütçe öngörüsü daha doğru olur.',
        ),
      if (duplicates > 0)
        _Insight(
          icon: Icons.content_copy_outlined,
          color: Colors.purple,
          title: '$duplicates olası tekrar bulundu',
          description:
              'Aynı adla eklenen ürünleri kontrol ederek gereksiz alımları önleyebilirsin.',
        ),
      if (slowest != null)
        _Insight(
          icon: Icons.trending_up_rounded,
          color: Colors.blue,
          title: '${slowest.name} öncelik bekliyor',
          description:
              'Bu kategori %${(slowestRate * 100).round()} tamamlandı ve listenin en gerisinde.',
        ),
      if (overdue == 0 && missingPrice == 0 && duplicates == 0)
        const _Insight(
          icon: Icons.auto_awesome_rounded,
          color: Colors.green,
          title: 'Listen gayet düzenli',
          description:
              'Geciken, fiyatı eksik veya tekrarlanan bir ürün görünmüyor.',
        ),
    ];
  }
}

class _Insight {
  const _Insight({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String description;
}

class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        'Akıllı öneriler için önce listene birkaç ürün ekle.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
