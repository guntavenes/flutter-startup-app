import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared_lists/data/shared_list_providers.dart';
import 'notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    ref.watch(sharedListRepositoryProvider),
  );
});

final sharedNotificationsProvider = StreamProvider((ref) {
  return ref.watch(notificationRepositoryProvider).watchNotifications();
});
