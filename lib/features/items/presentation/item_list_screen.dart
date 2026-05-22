import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/features/items/presentation/item_form_screen.dart';
import 'package:flutter_startup_app/core/extensions/currency_extensions.dart';
import 'package:flutter_startup_app/core/extensions/date_extensions.dart';

class ItemListScreen extends StatelessWidget {
  const ItemListScreen({super.key, required this.title, required this.items});

  final String title;
  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)),
              );
            },
            child: Container(
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
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2C1E26),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _buildSubtitle(item),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: item.isPurchased
                                ? const Color(0xFF2EAD5B)
                                : const Color(0xFF8A6B79),
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
          );
        },
      ),
    );
  }

  String _buildSubtitle(Item item) {
    if (item.isPurchased) {
      final price = item.purchasedPrice ?? 0;

      return 'Alındı • ${item.purchaseDate.toShortDateText()} • ${price.toCurrency()}';
    }

    if (item.estimatedPurchaseDate != null) {
      return 'Alınmadı • Hedef: ${item.estimatedPurchaseDate.toShortDateText()}';
    }

    return 'Alınmadı';
  }
}
