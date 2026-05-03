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
      body: itemsAsync.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Text('Bir hata oluştu: $error'),
          );
        },
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Henüz ürün eklenmedi'),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return ListTile(
                title: Text(item.name),
                subtitle: Text(
                  item.isPurchased ? 'Alındı' : 'Alınmadı',
                ),
              );
            },
          );
        },
      ),
    );
  }
}