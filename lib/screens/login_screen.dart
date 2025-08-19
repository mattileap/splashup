import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Import the auth service

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pool, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'Welcome to SplashUp',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: Image.asset('assets/google_logo.png', height: 24.0), // We'll add this asset next
              label: const Text('Sign in with Google'),
              onPressed: () async {
                await authService.signInWithGoogle();
                // The stream will automatically navigate to the home screen
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
