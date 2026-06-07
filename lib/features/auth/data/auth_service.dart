import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static bool _isGoogleSignInInitialized = false;

  static Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;

    await GoogleSignIn.instance.initialize();
    _isGoogleSignInInitialized = true;
  }

  static Future<UserCredential?> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      await _createOrUpdateUserDocument(userCredential.user);

      return userCredential;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  static Future<UserCredential> signInAnonymously() async {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();

    await _createOrUpdateUserDocument(userCredential.user);

    return userCredential;
  }

  static Future<void> _createOrUpdateUserDocument(User? user) async {
    if (user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    await userRef.set({
      'uid': user.uid,
      'displayName': user.displayName,
      'email': user.email,
      'isAnonymous': user.isAnonymous,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> signOut() async {
    await _ensureGoogleSignInInitialized();

    await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
