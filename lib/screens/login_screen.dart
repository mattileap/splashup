import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/app_localizations.dart';
import 'teams_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recuperiamo le traduzioni
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TUA ICONA ORIGINALE
              SvgPicture.asset(
                'assets/images/SplashUp_Icon.svg',
                height: 120, // Leggermente più grande per la copertina
                width: 120,
                // Manteniamo il tuo filtro colore originale
                colorFilter: const ColorFilter.mode(Colors.blue, BlendMode.srcIn),
              ),
              const SizedBox(height: 32),
              
              // TITOLO APP
              Text(
                'SplashUp',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              
              const SizedBox(height: 8), // Piccolo spazio tra titolo e slogan
              
              // NUOVO SLOGAN
              Text(
                l10n.appSlogan, // "Dive in. Stand out. SplashUp"
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade600, // Un po' più chiaro del titolo
                  fontStyle: FontStyle.italic, // Opzionale: corsivo per lo slogan
                ),
              ),

              const SizedBox(height: 24), // Spazio maggiore prima della descrizione
              
              // DESCRIZIONE / SOTTOTITOLO (LOCALIZZATO)
              Text(
                l10n.welcomeSubtitle, // "Il tuo compagno di nuoto..."
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              
              const SizedBox(height: 64),

              // TASTO "TUFFATI!"
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigazione diretta alla schermata Squadre (senza login)
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const TeamsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    l10n.diveInButton, // "Tuffati!"
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}