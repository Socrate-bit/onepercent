import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Firebase Auth wrapper backed by Sign in with Apple.
///
/// The app is hard-gated: [main] shows the login screen until [authState]
/// emits a signed-in [User]. There is no anonymous fallback.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The current user's uid, or null when signed out.
  String? get uid => _auth.currentUser?.uid;

  /// Emits the current [User] whenever auth state changes.
  Stream<User?> get authState => _auth.authStateChanges();

  /// Runs the native Sign in with Apple flow and signs into Firebase.
  ///
  /// Uses a nonce to protect against replay attacks: the SHA-256 hash is sent
  /// to Apple, and the raw value is handed to Firebase to verify the returned
  /// ID token. Throws [SignInWithAppleAuthorizationException] on cancel/error.
  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = appleCredential.identityToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'apple-missing-id-token',
        message: 'Apple did not return an identity token.',
      );
    }

    // Apple only returns the name on the very first authorization; forward it
    // so Firebase can populate displayName when available (fields are null on
    // subsequent sign-ins).
    final credential = AppleAuthProvider.credentialWithIDToken(
      idToken,
      rawNonce,
      AppleFullPersonName(
        givenName: appleCredential.givenName,
        familyName: appleCredential.familyName,
      ),
    );

    final userCredential = await _auth.signInWithCredential(credential);
    debugPrint('[AuthService] Signed in with Apple: ${userCredential.user?.uid}');
    return userCredential;
  }

  /// Signs the current user out, returning the app to the login screen.
  Future<void> signOut() => _auth.signOut();

  /// Cryptographically secure random string for the Apple sign-in nonce.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}
