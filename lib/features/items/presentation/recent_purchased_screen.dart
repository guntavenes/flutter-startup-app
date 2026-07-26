import 'dart:io';

import 'package:ceyizim_plus/core/database/app_database.dart';
import 'package:ceyizim_plus/core/extensions/currency_extensions.dart';
import 'package:ceyizim_plus/core/extensions/date_extensions.dart';
import 'package:ceyizim_plus/features/items/data/item_providers.dart';
import 'package:ceyizim_plus/features/items/presentation/item_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecentPurchasedScreen extends ConsumerWidget {
  const RecentPurchasedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentItemsAsync = ref.watch(recentPurchasedItemsProvider);
    final itemCount = recentItemsAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: const Text('Son Alınanlar'),
        backgroundColor: Colors.transparent,
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
        child: SafeArea(
          child: recentItemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Hata: $error')),
            data: (items) {
              final totalExpense = items
                  .where((e) => e.purchasedPrice != null)
                  .fold<double>(0, (sum, item) => sum + item.purchasedPrice!);

              return Column(
                children: [
                  _buildExpenseHeader(totalExpense, itemCount),
                  const SizedBox(height: 14),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(
                            child: Text(
                              'Son 7 günde alınan ürün yok',
                              style: TextStyle(
                                color: Color(0xFF8A6B79),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];

                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ItemDetailScreen(item: item),
                                    ),
                                  );
                                },
                                child: _buildItemCard(item),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseHeader(double totalExpense, int itemCount) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD96BA7), Color(0xFFFF8DBA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.shopping_cart_checkout_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Son 7 Gün • $itemCount ürün',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: totalExpense),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      value.toCurrency(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    final priceText = (item.purchasedPrice ?? 0).toCurrency();
    final dateText = item.purchaseDate == null
        ? 'Tarih yok'
        : item.purchaseDate!.toShortDateText();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFD6EA)),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: item.imagePath != null && item.imagePath!.isNotEmpty
                ? Image.file(
                    File(item.imagePath!),
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFC7E3), Color(0xFFFFEEF7)],
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
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C1E26),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  priceText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD96BA7),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A7A89),
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
