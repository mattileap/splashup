import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';
import 'services/auth_service.dart'; // Import the AuthService
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    // UPDATED: Use MultiProvider to provide both services.
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (context) => ThemeService(prefs)),
      ],
      child: const SplashUpApp(),
    ),
  );
}

class SplashUpApp extends StatelessWidget {
  const SplashUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'SplashUp',
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
             colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.dark),
             appBarTheme: AppBarTheme(
              backgroundColor: Colors.blueGrey.shade800,
              foregroundColor: Colors.white,
            ),
            useMaterial3: true,
          ),
          themeMode: themeService.themeMode,

          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
