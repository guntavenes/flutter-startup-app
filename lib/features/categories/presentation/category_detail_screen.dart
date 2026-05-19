import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/features/items/data/item_providers.dart';
import 'package:flutter_startup_app/features/items/data/item_repository_provider.dart';
import 'package:flutter_startup_app/features/items/presentation/item_form_screen.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.items,
  });

  final Category category;
  final List<Item> items;

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allItemsAsync = ref.watch(allItemsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: const Color(0xFFFFF5FA),
        elevation: 0,
      ),
      body: allItemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Hata: $error')),
        data: (allItems) {
          final categoryItems = allItems
              .where((item) => item.categoryId == widget.category.id)
              .toList();

          final filteredItems = categoryItems.where((item) {
            final query = _searchText.toLowerCase();

            return item.name.toLowerCase().contains(query) ||
                (item.brand?.toLowerCase().contains(query) ?? false) ||
                (item.model?.toLowerCase().contains(query) ?? false);
          }).toList();

          return _buildBody(filteredItems, categoryItems);
        },
      ),
    );
  }

  Widget _buildBody(List<Item> filteredItems, List<Item> categoryItems) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF5FA), Color(0xFFFFF7F0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSummaryHeader(categoryItems),
            _buildSearchBar(),
            const SizedBox(height: 10),
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(
                      child: Text(
                        'Ürün bulunamadı',
                        style: TextStyle(
                          color: Color(0xFF8A6B79),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];

                        return Dismissible(
                          key: ValueKey(item.id),
                          background: _buildSwipeBackground(
                            color: const Color(0xFF7ACFA6),
                            icon: Icons.check_circle_rounded,
                            text: item.isPurchased
                                ? 'Alınmadı Yap'
                                : 'Alındı Yap',
                            alignment: Alignment.centerLeft,
                          ),
                          secondaryBackground: _buildSwipeBackground(
                            color: Colors.redAccent,
                            icon: Icons.delete_outline_rounded,
                            text: 'Sil',
                            alignment: Alignment.centerRight,
                          ),
                          confirmDismiss: (direction) async {
                            final repo = ref.read(itemRepositoryProvider);

                            if (direction == DismissDirection.startToEnd) {
                              await repo.togglePurchased(item);
                              ref.invalidate(allItemsProvider);
                              return false;
                            }

                            final shouldDelete = await _confirmDeleteItem();

                            if (shouldDelete == true) {
                              await repo.deleteItemById(item.id);
                              ref.invalidate(allItemsProvider);
                              return true;
                            }

                            return false;
                          },
                          child: GestureDetector(
                            onTap: () async {
                              final result = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ItemFormScreen(item: item),
                                    ),
                                  );

                              if (result == true) {
                                ref.invalidate(allItemsProvider);
                              }
                            },
                            child: _buildItemCard(item),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(List<Item> items) {
    final purchasedCount = items.where((e) => e.isPurchased).length;
    final remainingCount = items.length - purchasedCount;

    final totalExpense = items
        .where((e) => e.isPurchased && e.purchasedPrice != null)
        .fold<double>(0, (sum, item) => sum + item.purchasedPrice!);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8DBA), Color(0xFFD96BA7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.category.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${items.length} ürün • '
            '$purchasedCount alındı • '
            '$remainingCount kalan',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchText = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Ürün ara...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFFD96BA7),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
          ),
        ),
      ),
    );
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
            color: const Color(0xFFD96BA7).withValues(alpha: 0.12),
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
                  _buildSubtitle(item),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: item.isPurchased
                        ? const Color(0xFF2EAD5B)
                        : const Color(0xFF8A6B79),
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

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String text,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      alignment: alignment,
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDeleteItem() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ürünü sil'),
          content: const Text('Bu ürünü silmek istediğine emin misin?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Sil',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _buildSubtitle(Item item) {
    final status = item.isPurchased ? 'Alındı' : 'Alınmadı';

    if (item.purchasedPrice == null) {
      return status;
    }

    return '$status • ${item.purchasedPrice!.toStringAsFixed(2)} ₺';
  }
}
