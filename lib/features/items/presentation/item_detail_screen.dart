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
        backgroundColor: const Color(0xFFFFF5FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          item.name.trim().isEmpty ? 'İsimsiz Ürün' : item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: Color(0xFF2C1E26),
          ),
        ),
        actions: [
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFEEF7), Color(0xFFFFD6EA)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD96BA7).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF6D4C5B)),
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)),
                );

                if (result == true && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 28),
        child: Column(
          children: [
            _buildMainCard(context),
            if (item.link != null && item.link!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _openLink(item.link!),
                child: _buildTextCard(
                  title: 'Ürün Linki',
                  value: 'Dokunarak aç',
                  icon: Icons.link_rounded,
                ),
              ),
            ],
            if (item.note != null && item.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
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

  Widget _buildMainCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFFF7FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFE3F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.13),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildImage(context),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_buildStatusChip()],
          ),
          const SizedBox(height: 12),
          _buildCompactInfoGrid(),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (item.imagePath == null || item.imagePath!.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFEEF7), Color(0xFFFFF7FB)],
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: const Icon(
          Icons.shopping_bag_outlined,
          color: Color(0xFFD96BA7),
          size: 44,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullImage(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 220,
            width: double.infinity,
            color: const Color(0xFFFFEEF7),
            child: Image.file(
              File(item.imagePath!),
              fit: BoxFit.contain,
              cacheWidth: 1200,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final isPurchased = item.isPurchased;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPurchased ? const Color(0xFFEAF8F0) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPurchased ? Icons.check_circle_rounded : Icons.event_note_rounded,
            size: 16,
            color: isPurchased
                ? const Color(0xFF2EAD5B)
                : const Color(0xFFFF9800),
          ),
          const SizedBox(width: 5),
          Text(
            isPurchased ? 'Alındı' : 'Planlanıyor',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isPurchased
                  ? const Color(0xFF2EAD5B)
                  : const Color(0xFFFF9800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoGrid() {
    final dateTitle = item.isPurchased ? 'Alınma Tarihi' : 'Hedef Tarih';
    final dateValue = item.isPurchased
        ? item.purchaseDate.toShortDateText()
        : item.estimatedPurchaseDate.toShortDateText();

    final priceValue = item.isPurchased
        ? (item.purchasedPrice ?? 0).toCurrency()
        : '-';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                title: 'Marka',
                value: item.brand,
                icon: Icons.sell_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInfoTile(
                title: 'Model',
                value: item.model,
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                title: dateTitle,
                value: dateValue,
                icon: Icons.event_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInfoTile(
                title: 'Fiyat',
                value: priceValue,
                icon: Icons.payments_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String? value,
    required IconData icon,
  }) {
    final text = value == null || value.trim().isEmpty ? '-' : value;

    return Container(
      height: 92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE3F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFD96BA7)),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.2,
              color: Color(0xFF9A7285),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.1,
              color: Color(0xFF241821),
              fontWeight: FontWeight.w900,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD6EA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD96BA7)),
          const SizedBox(width: 18),
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
                const SizedBox(height: 5),
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

    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showFullImage(BuildContext context) {
    if (item.imagePath == null || item.imagePath!.isEmpty) return;

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
