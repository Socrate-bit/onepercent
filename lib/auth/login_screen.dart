import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../theme/app_theme.dart';
import 'auth_service.dart';

/// Full-screen gate shown until the user signs in with Apple.
///
/// On success the [AuthService.authState] stream fires and the bootstrap gate
/// in [main] swaps in the app — this screen never navigates itself.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.auth});

  final AuthService? auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _auth = widget.auth ?? AuthService();
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _auth.signInWithApple();
      // No navigation: the auth stream drives the transition.
    } on SignInWithAppleAuthorizationException catch (e) {
      // User backed out of the native sheet — not an error worth showing.
      if (e.code == AuthorizationErrorCode.canceled) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      _fail('Apple sign-in failed. Please try again.');
    } on FirebaseAuthException {
      _fail('Could not complete sign-in. Please try again.');
    } catch (_) {
      _fail('Something went wrong. Check your connection and try again.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Icon(
                Icons.local_fire_department,
                size: 72,
                color: AppColors.fire,
              ),
              const SizedBox(height: 24),
              const Text(
                'Discipline',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sign in to track your wins and keep your streak.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 4),
              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.loss),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                height: 52,
                child: _busy
                    ? const Center(child: CircularProgressIndicator())
                    : SignInWithAppleButton(
                        onPressed: _signIn,
                        style: SignInWithAppleButtonStyle.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
