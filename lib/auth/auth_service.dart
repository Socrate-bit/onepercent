import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around anonymous Firebase Auth.
///
/// The app has no login screen: on launch we silently sign the user in
/// anonymously so their battles sync to a stable per-device uid.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The current user's uid, or null when signed out.
  String? get uid => _auth.currentUser?.uid;

  /// Emits the current [User] whenever auth state changes.
  Stream<User?> get authState => _auth.authStateChanges();

  /// Ensures an anonymous session exists, returning the uid.
  Future<String?> ensureSignedIn() async {
    if (_auth.currentUser != null) return _auth.currentUser!.uid;
    try {
      final cred = await _auth.signInAnonymously();
      debugPrint('[AuthService] Signed in anonymously: ${cred.user?.uid}');
      return cred.user?.uid;
    } catch (e, st) {
      debugPrint('[AuthService] Anonymous sign-in failed: $e\n$st');
      rethrow;
    }
  }
}
