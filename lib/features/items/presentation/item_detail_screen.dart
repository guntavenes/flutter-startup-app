import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/core/extensions/currency_extensions.dart';
import 'package:flutter_startup_app/core/extensions/date_extensions.dart';
import 'package:flutter_startup_app/features/items/presentation/item_form_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        backgroundColor: const Color(0xFFFFF5FA),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)),
              );

              if (result == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(context),
            const SizedBox(height: 18),
            _buildTitleCard(),
            const SizedBox(height: 14),
            _buildStatusCard(),
            const SizedBox(height: 14),
            _buildInfoCard(),
            if (item.link != null && item.link!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () => _openLink(item.link!),
                child: _buildTextCard(
                  title: 'Ürün Linki',
                  value: 'Dokunarak aç',
                  icon: Icons.link_rounded,
                ),
              ),
            ],
            if (item.note != null && item.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildTextCard(
                title: 'Not',
                value: item.note!,
                icon: Icons.notes_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (item.imagePath == null || item.imagePath!.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(
          Icons.shopping_bag_outlined,
          color: Color(0xFFD96BA7),
          size: 54,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullImage(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.file(
          File(item.imagePath!),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          cacheWidth: 800,
          cacheHeight: 500,
        ),
      ),
    );
  }

  Widget _buildTitleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8DBA), Color(0xFFD96BA7)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Text(
        item.name.trim().isEmpty ? 'İsimsiz Ürün' : item.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.isPurchased ? '🟢 Alındı' : '🟠 Planlanıyor',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (item.isPurchased) ...[
            Text(item.purchaseDate.toShortDateText()),
            const SizedBox(height: 4),
            Text(
              (item.purchasedPrice ?? 0).toCurrency(),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ] else
            Text(
              item.estimatedPurchaseDate == null
                  ? '-'
                  : item.estimatedPurchaseDate.toShortDateText(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          _infoRow('Marka', item.brand),
          _infoRow('Model', item.model),
          if (item.isPurchased) ...[
            _infoRow('Fiyat', (item.purchasedPrice ?? 0).toCurrency()),
            _infoRow('Alınma Tarihi', item.purchaseDate.toShortDateText()),
          ] else
            _infoRow(
              'Hedef Alınma Tarihi',
              item.estimatedPurchaseDate.toShortDateText(),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String? value) {
    final text = value == null || value.trim().isEmpty ? '-' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF8A6B79),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF2C1E26),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD96BA7)),
          const SizedBox(width: 10),
          Expanded(
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
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link);

    if (uri == null) {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showFullImage(BuildContext context) {
    if (item.imagePath == null || item.imagePath!.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(item.imagePath!), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
