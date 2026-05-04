import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/features/items/data/item_providers.dart';
import 'package:flutter_startup_app/features/items/data/item_repository_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çeyiz Takip'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final repository = ref.read(itemRepositoryProvider);

          final now = DateTime.now().millisecondsSinceEpoch;

          await repository.addItem(
            ItemsCompanion.insert(
              categoryId: 1,
              name: 'Deneme Ürün',
              createdAt: now,
              updateAt: now,
            ),
          );

          ref.invalidate(itemsProvider);
        },
        child: const Icon(Icons.add),
      ),
body: Padding(
  padding: const EdgeInsets.all(16),
  child: itemsAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) => Center(child: Text('Hata: $error')),
    data: (items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hoş geldin 💖',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          _buildSummary(items),

          const SizedBox(height: 16),

          _buildFilters(),

          const SizedBox(height: 16),

          Expanded(
            child: _buildItemList(items),
          ),
        ],
      );
    },
  ),
),
    );
  }
}

Widget _buildSummary(List<Item> items) {
  final total = items.length;
  final purchased = items.where((e) => e.isPurchased).length;
  final remaining = total - purchased;

  return Row(
    children: [
      _summaryCard('Toplam', total),
      const SizedBox(width: 8),
      _summaryCard('Alınan', purchased),
      const SizedBox(width: 8),
      _summaryCard('Kalan', remaining),
    ],
  );
}

Widget _summaryCard(String title, int value) {
  return Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    ),
  );
}

Widget _buildFilters() {
  return Row(
    children: [
      _filterChip('Tümü'),
      const SizedBox(width: 8),
      _filterChip('Kalan'),
      const SizedBox(width: 8),
      _filterChip('Alınan'),
    ],
  );
}

Widget _filterChip(String text) {
  return Chip(
    label: Text(text),
  );
}

Widget _buildItemList(List<Item> items) {
  if (items.isEmpty) {
    return const Center(
      child: Text('Henüz ürün eklenmedi'),
    );
  }

  return ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          title: Text(item.name),
          subtitle: Text(
            item.isPurchased ? 'Alındı' : 'Alınmadı',
          ),
          trailing: Icon(
            item.isPurchased
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: item.isPurchased ? Colors.green : Colors.grey,
          ),
        ),
      );
    },
  );
}