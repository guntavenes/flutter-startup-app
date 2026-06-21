import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/features/items/data/item_repository_provider.dart';

import '../../items/data/item_providers.dart';
import '../../items/presentation/item_detail_screen.dart';
import '../data/notification_providers.dart';

class SharedNotificationsScreen extends ConsumerWidget {
  const SharedNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(sharedNotificationsProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: const Text('Ortak Liste Hareketleri'),
        backgroundColor: const Color(0xFFFFF5FA),
        elevation: 0,
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Hareketler alınamadı: $error')),
        data: (notifications) {
          final otherNotifications = notifications
              .where((n) => n.createdBy != currentUid)
              .toList();

          if (otherNotifications.isEmpty) {
            return const Center(
              child: Text(
                'Henüz ortak liste hareketi yok.',
                style: TextStyle(
                  color: Color(0xFF8A6B79),
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: otherNotifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notification = otherNotifications[index];

              return InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: notification.itemId == null
                    ? null
                    : () async {
                        final item = await ref
                            .read(itemRepositoryProvider)
                            .getById(notification.itemId!);

                        if (!context.mounted) return;

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(item: item),
                          ),
                        );
                      },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE7D6FF)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EEFF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_rounded,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          notification.message,
                          style: const TextStyle(
                            color: Color(0xFF2C1E26),
                            fontWeight: FontWeight.w700,
                          ),
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
          );
        },
      ),
    );
  }
}
