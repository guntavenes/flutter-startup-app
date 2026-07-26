import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../shared_lists/data/shared_list_repository.dart';
import '../models/shared_notification.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SharedListRepository _sharedListRepository;

  NotificationRepository(
    this._firestore,
    this._auth,
    this._sharedListRepository,
  );

  Future<void> addItemPurchasedNotification({
    required int itemId,
    required String itemName,
  }) async {
    try {
      final user = await _waitForAuthenticatedUser();

      final listRef = await _sharedListRepository.getActiveListRef();

      final displayName = (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!
          : 'Bir kullanıcı';

      await listRef.collection('notifications').add({
        'type': 'item_purchased',
        'itemId': itemId,
        'itemName': itemName,
        'message': '$displayName, $itemName ürününü aldı.',
        'createdBy': user.uid,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'serverCreatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      debugPrint('ADD_ITEM_PURCHASED_NOTIFICATION_ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Stream<List<SharedNotification>> watchNotifications() async* {
    await _waitForAuthenticatedUser();

    final listRef = await _sharedListRepository.getActiveListRef();

    yield* listRef
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();

            return SharedNotification(
              id: doc.id,
              type: data['type'] as String? ?? '',
              message: data['message'] as String? ?? '',
              createdBy: data['createdBy'] as String? ?? '',
              createdAt: (data['createdAt'] as num?)?.toInt() ?? 0,
              itemId: (data['itemId'] as num?)?.toInt(),
              itemName: data['itemName'] as String?,
            );
          }).toList();
        });
  }

  Future<User> _waitForAuthenticatedUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return currentUser;
    }

    return (await _auth.authStateChanges().firstWhere((user) => user != null))!;
  }
}
