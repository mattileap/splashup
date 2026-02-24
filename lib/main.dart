import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'screens/login_screen.dart'; // Che ora contiene la WelcomeScreen
import 'services/theme_service.dart';

// NUOVI IMPORT PER IL DATABASE
import 'repositories/database_repository.dart';
import 'repositories/sembast_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  final prefs = await SharedPreferences.getInstance();

  // Inizializziamo il Database Locale (Sembast)
  final databaseRepository = SembastRepository();
  await databaseRepository.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeService(prefs)),
        // NUOVO: Iniettiamo il Repository del Database in tutta l'app
        Provider<DatabaseRepository>.value(value: databaseRepository),
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
          // Manteniamo la tua configurazione di localizzazione originale
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          
          // Manteniamo il tuo tema originale
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

          // Home: Parte dalla nuova schermata di benvenuto con l'icona SVG
          home: const WelcomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}