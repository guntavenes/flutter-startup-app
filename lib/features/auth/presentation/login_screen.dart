import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_startup_app/features/auth/data/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎁', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 18),
                const Text(
                  'Çeyiz Takip',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C1E26),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Listenizi güvenle saklamak ve cihazlar arasında kullanmak için giriş yapın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8A6B79),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final result = await AuthService.signInWithGoogle();

                        debugPrint('Google Login Result: $result');
                      } catch (e) {
                        debugPrint('Google Login Error: $e');

                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                        }
                      }
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Google ile Devam Et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD96BA7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AuthService.signInAnonymously();
                    },
                    icon: const Icon(Icons.person_outline_rounded),
                    label: const Text('Misafir Olarak Devam Et'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD96BA7),
                      side: const BorderSide(
                        color: Color(0xFFD96BA7),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
