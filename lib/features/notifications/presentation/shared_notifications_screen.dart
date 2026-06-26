import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ceyizim_plus/features/shared_lists/data/shared_list_providers.dart';

import '../../items/data/item_repository_provider.dart';
import '../../items/presentation/item_detail_screen.dart';
import '../data/notification_providers.dart';
import '../models/shared_notification.dart';

class SharedNotificationsScreen extends ConsumerWidget {
  const SharedNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(sharedNotificationsProvider);
    final membersAsync = ref.watch(membersProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: const Text(
          'Ortak Liste Hareketleri',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF2C1E26),
          ),
        ),
        backgroundColor: const Color(0xFFFFF5FA),
        elevation: 0,
        foregroundColor: const Color(0xFF2C1E26),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Üyeler alınamadı: $error', textAlign: TextAlign.center),
        ),
        data: (members) {
          int joinedAtMs = 0;

          for (final member in members) {
            if (member.uid == currentUid) {
              joinedAtMs = member.joinedAtMs;
              break;
            }
          }

          return notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Hareketler alınamadı: $error',
                textAlign: TextAlign.center,
              ),
            ),
            data: (notifications) {
              final otherNotifications = notifications
                  .where((n) => n.createdBy != currentUid)
                  .where((n) => n.createdAt >= joinedAtMs)
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

                  return _NotificationCard(
                    notification: notification,
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
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final SharedNotification notification;
  final VoidCallback? onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTime(notification.createdAt);
    final itemName =
        notification.itemName ?? _extractItemName(notification.message);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEFF),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    style: const TextStyle(
                      color: Color(0xFF2C1E26),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Color(0xFF8A6B79),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeText,
                    style: const TextStyle(
                      color: Color(0xFFD96BA7),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A6B79)),
          ],
        ),
      ),
    );
  }

  static String _extractItemName(String message) {
    final parts = message.split(',');
    if (parts.length < 2) return 'Ürün hareketi';

    return parts.last
        .replaceAll('ürününü aldı.', '')
        .replaceAll('ürününü aldı', '')
        .trim();
  }

  static String _formatTime(int createdAt) {
    final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    }

    if (difference.inDays == 1) {
      return 'Dün';
    }

    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
