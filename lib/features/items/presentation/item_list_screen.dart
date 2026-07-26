import 'dart:io';

import 'package:ceyizim_plus/core/database/app_database.dart';
import 'package:ceyizim_plus/core/extensions/currency_extensions.dart';
import 'package:ceyizim_plus/core/extensions/date_extensions.dart';
import 'package:ceyizim_plus/features/items/data/item_providers.dart';
import 'package:ceyizim_plus/features/items/presentation/item_detail_screen.dart';
import 'package:flutter/material.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({
    super.key,
    required this.title,
    required this.items,
    required this.filter,
  });

  final String title;
  final List<Item> items;
  final ItemFilter filter;

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((item) {
      final query = _searchText.trim().toLowerCase();

      if (query.isEmpty) {
        return true;
      }

      return item.name.toLowerCase().contains(query) ||
          (item.brand?.toLowerCase().contains(query) ?? false) ||
          (item.model?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
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
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];

                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => ItemDetailScreen(item: item),
                            ),
                          );

                          if (result == true && context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                        child: _buildItemCard(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Ürün, marka veya model ara...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFD96BA7),
          ),
          suffixIcon: _searchText.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchText = '';
                    });
                  },
                ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.92),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    final subtitle = _buildSubtitle(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: item.imagePath != null && item.imagePath!.isNotEmpty
                ? Image.file(
                    File(item.imagePath!),
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    cacheWidth: 160,
                    cacheHeight: 160,
                  )
                : Container(
                    width: 54,
                    height: 54,
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
                  item.name.trim().isEmpty ? 'İsimsiz Ürün' : item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C1E26),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: item.isPurchased
                          ? const Color(0xFF2EAD5B)
                          : const Color(0xFF8A6B79),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A6B79)),
        ],
      ),
    );
  }

  String _buildSubtitle(Item item) {
    switch (widget.filter) {
      case ItemFilter.all:
        if (item.isPurchased) {
          return 'Alındı • ${item.purchaseDate.toShortDateText()}';
        }

        if (item.estimatedPurchaseDate != null) {
          return 'Alınmadı: ${item.estimatedPurchaseDate.toShortDateText()}';
        }

        return 'Alınmadı';

      case ItemFilter.purchased:
        final price = item.purchasedPrice ?? 0;

        return '${item.purchaseDate.toShortDateText()} • ${price.toCurrency()}';

      case ItemFilter.remaining:
        if (item.estimatedPurchaseDate == null) {
          return 'Alınmadı';
        }

        return item.estimatedPurchaseDate.toShortDateText();
    }
  }
}
