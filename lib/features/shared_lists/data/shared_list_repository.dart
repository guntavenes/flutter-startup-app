import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_startup_app/features/shared_lists/models/shared_member.dart';

class SharedListRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getActiveListId() async {
    final user = await _requireCurrentUser();

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    return userDoc.data()?['activeListId'] as String?;
  }

  Future<String> ensureActiveList() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Kullanıcı bulunamadı.');
    }

    return ensureActiveListForUser(user);
  }

  Future<String> createList() async {
    final user = await _requireCurrentUser();

    final listRef = _firestore.collection('sharedLists').doc();
    final inviteCode = _generateInviteCode();

    await listRef.set({
      'name': '${user.displayName ?? 'Kullanıcı'} Çeyiz Listesi',
      'ownerId': user.uid,
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await listRef.collection('members').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(user.uid).set({
      'activeListId': listRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return listRef.id;
  }

  Future<String> joinListWithInviteCode(String inviteCode) async {
    final user = await _requireCurrentUser();

    final normalizedCode = inviteCode.trim().toUpperCase();

    final snapshot = await _firestore
        .collection('sharedLists')
        .where('inviteCode', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Davet kodu bulunamadı.');
    }

    final listDoc = snapshot.docs.first;
    final listId = listDoc.id;

    final activeListId = await getActiveListId();

    if (activeListId == listId) {
      throw Exception('Zaten bu listedesin.');
    }

    await listDoc.reference.collection('members').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'role': 'editor',
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore.collection('users').doc(user.uid).set({
      'activeListId': listId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return listId;
  }

  Future<List<SharedMember>> getMembers() async {
    final listRef = await getActiveListRef();

    final snapshot = await listRef.collection('members').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return SharedMember(
        uid: data['uid'] as String,
        email: data['email'] as String?,
        displayName: data['displayName'] as String?,
        role: data['role'] as String? ?? 'editor',
      );
    }).toList();
  }

  Future<String> ensureActiveListForUser(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    return _firestore.runTransaction<String>((transaction) async {
      final userSnapshot = await transaction.get(userRef);

      final existingListId = userSnapshot.data()?['activeListId'] as String?;

      if (existingListId != null && existingListId.isNotEmpty) {
        return existingListId;
      }

      final listRef = _firestore.collection('sharedLists').doc();
      final inviteCode = _generateInviteCode();

      transaction.set(listRef, {
        'name': '${user.displayName ?? 'Kullanıcı'} Çeyiz Listesi',
        'ownerId': user.uid,
        'inviteCode': inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(listRef.collection('members').doc(user.uid), {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'role': 'owner',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(userRef, {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'isAnonymous': user.isAnonymous,
        'activeListId': listRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return listRef.id;
    });
  }

  Future<String> createListForUser(User user) async {
    final listRef = _firestore.collection('sharedLists').doc();
    final inviteCode = _generateInviteCode();

    await listRef.set({
      'name': '${user.displayName ?? 'Kullanıcı'} Çeyiz Listesi',
      'ownerId': user.uid,
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await listRef.collection('members').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(user.uid).set({
      'activeListId': listRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return listRef.id;
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();

    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<String?> getInviteCode() async {
    final listId = await getActiveListId();

    if (listId == null || listId.isEmpty) {
      return null;
    }

    final doc = await _firestore.collection('sharedLists').doc(listId).get();

    return doc.data()?['inviteCode'] as String?;
  }

  Future<User> _requireCurrentUser() async {
    final existingUser = FirebaseAuth.instance.currentUser;

    if (existingUser != null) {
      return existingUser;
    }

    final user = await FirebaseAuth.instance.authStateChanges().firstWhere(
      (user) => user != null,
    );

    return user!;
  }

  Future<DocumentReference<Map<String, dynamic>>> getActiveListRef() async {
    final listId = await ensureActiveList();

    return _firestore.collection('sharedLists').doc(listId);
  }

  Future<void> updateCurrentUserDisplayName(String displayName) async {
    final user = await _requireCurrentUser();
    final trimmedName = displayName.trim();

    if (trimmedName.isEmpty) return;

    await user.updateDisplayName(trimmedName);

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'displayName': trimmedName,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final activeListId = await getActiveListId();

    if (activeListId != null && activeListId.isNotEmpty) {
      await _firestore
          .collection('sharedLists')
          .doc(activeListId)
          .collection('members')
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'email': user.email,
            'displayName': trimmedName,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
  }

  Future<String> leaveActiveSharedList() async {
    final user = await _requireCurrentUser();
    final activeListRef = await getActiveListRef();

    await activeListRef.collection('members').doc(user.uid).delete();

    final newListId = await createList();

    await _firestore.collection('users').doc(user.uid).set({
      'activeListId': newListId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return newListId;
  }

  Stream<List<SharedMember>> watchMembers() async* {
    final listRef = await getActiveListRef();

    yield* listRef.collection('members').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return SharedMember(
          uid: data['uid'] as String,
          email: data['email'] as String?,
          displayName: data['displayName'] as String?,
          role: data['role'] as String? ?? 'editor',
        );
      }).toList();
    });
  }
}
