import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/core/extensions/currency_extensions.dart';
import 'package:flutter_startup_app/features/items/data/item_providers.dart';
import 'package:flutter_startup_app/features/items/data/item_repository_provider.dart';
import 'package:flutter_startup_app/features/items/presentation/item_form_screen.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.item});

  final Item item;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late Item _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        backgroundColor: const Color(0xFFFFF5FA),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              const SizedBox(height: 20),
              Text(
                _currentItem.name.trim().isEmpty
                    ? 'İsimsiz Ürün'
                    : _currentItem.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2C1E26),
                ),
              ),
              const SizedBox(height: 14),
              _buildPurchaseButton(context),
              const SizedBox(height: 10),
              _buildEditButton(context),
              const SizedBox(height: 14),
              _infoCard(
                'Durum',
                _currentItem.isPurchased ? 'Alındı' : 'Alınmadı',
              ),
              _infoCard('Marka', _currentItem.brand ?? '-'),
              _infoCard('Model', _currentItem.model ?? '-'),
              _infoCard(
                'Fiyat',
                _currentItem.purchasedPrice == null
                    ? '-'
                    : (_currentItem.purchasedPrice ?? 0).toCurrency(),
              ),
              _infoCard('Link', _currentItem.link ?? '-'),
              _infoCard('Not', _currentItem.note ?? '-'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ItemFormScreen(item: _currentItem),
            ),
          );

          if (result == true && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Ürünü Düzenle'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD96BA7),
          side: const BorderSide(color: Color(0xFFD96BA7), width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () async {
          final repo = ref.read(itemRepositoryProvider);
          final now = DateTime.now().millisecondsSinceEpoch;

          await repo.togglePurchased(_currentItem);

          setState(() {
            _currentItem = _currentItem.copyWith(
              isPurchased: !_currentItem.isPurchased,
              updateAt: now,
            );
          });

          ref.invalidate(allItemsProvider);
        },
        icon: Icon(
          _currentItem.isPurchased
              ? Icons.radio_button_unchecked
              : Icons.check_circle_rounded,
        ),
        label: Text(
          _currentItem.isPurchased ? 'Alınmadı Yap' : 'Alındı Olarak İşaretle',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _currentItem.isPurchased
              ? const Color(0xFFFFB74D)
              : const Color(0xFFD96BA7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_currentItem.imagePath != null && _currentItem.imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.file(
          File(_currentItem.imagePath!),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
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
            value.trim().isEmpty ? '-' : value,
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
