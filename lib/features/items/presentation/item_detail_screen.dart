import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            const SizedBox(height: 20),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C1E26),
              ),
            ),
            const SizedBox(height: 10),
            _infoCard('Durum', item.isPurchased ? 'Alındı' : 'Alınmadı'),
            _infoCard('Marka', item.brand ?? '-'),
            _infoCard('Model', item.model ?? '-'),
            _infoCard(
              'Fiyat',
              item.purchasedPrice == null
                  ? '-'
                  : '${item.purchasedPrice!.toStringAsFixed(2)} ₺',
            ),
            _infoCard('Link', item.link ?? '-'),
            _infoCard('Not', item.note ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.file(
          File(item.imagePath!),
          width: double.infinity,
          height: 240,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC7E3), Color(0xFFFFEEF7)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        size: 64,
        color: Color(0xFFD96BA7),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8A6B79),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2C1E26),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
