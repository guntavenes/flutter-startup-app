import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SharedListRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getActiveListId() async {
    final user = await _requireCurrentUser();

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    return userDoc.data()?['activeListId'] as String?;
  }

  Future<String> ensureActiveList() async {
    final existingListId = await getActiveListId();

    if (existingListId != null && existingListId.isNotEmpty) {
      return existingListId;
    }

    return createList();
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

  Future<String> ensureActiveListForUser(User user) async {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    final existingListId = userDoc.data()?['activeListId'] as String?;

    if (existingListId != null && existingListId.isNotEmpty) {
      return existingListId;
    }

    return createListForUser(user);
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
}
