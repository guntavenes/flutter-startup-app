import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../items/data/item_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Çeyiz Takip')),
      body: itemsAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return Center(child: Text('Bir hata oluştu: $error'));
        },
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Henüz ürün eklenmedi'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return ListTile(
                title: Text(item.name),
                subtitle: Text(item.isPurchased ? 'Alındı' : 'Alınmadı'),
              );
            },
          );
        },
      ),
    );
  }
}
