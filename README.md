<p align="center">
  <img src="assets/images/SplashUp_Icon.png" alt="SplashUp" width="120">
</p>

<h1 align="center">SplashUp</h1>

<p align="center">
  🇮🇹 Italiano | <a href="README.en.md">🇬🇧 English</a>
</p>

<p align="center">
  L'app semplice per allenatori di nuoto 🏊
</p>

SplashUp è un'app Flutter pensata per allenatori di nuoto che vogliono cronometrare gli atleti in vasca e tenere traccia dei loro progressi, senza bisogno di connessione internet: tutti i dati restano sul dispositivo.

## Funzionalità principali

- **Gestione squadre e atleti**: crea squadre, aggiungi atleti, spostali tra squadre o disattivali/eliminali quando non sono più attivi.
- **Cronometro con parziali**: avvia, ferma e prendi i tempi di passaggio ("giri") con feedback aptico e sonoro configurabili, e schermo sempre acceso durante l'uso.
- **Analisi dei parziali**: grafici dedicati per visualizzare l'andamento dei tempi nel corso di allenamenti e gare.
- **Funziona offline**: i dati sono salvati in un database locale (Sembast), nessuna connessione richiesta.
- **Personalizzazione ed accessibilità**: tema chiaro/scuro/automatico, 6 palette colore, dimensione del testo regolabile e font OpenDyslexic per utenti con dislessia.
- **Multilingua**: interfaccia disponibile in italiano e inglese, con possibilità di seguire la lingua di sistema o sceglierla manualmente.

## Screenshot

<p align="center">
  <img src="assets/screenshots/Squadre.jpg" alt="Squadre" width="18%">
  <img src="assets/screenshots/Modifica.jpg" alt="Modifica" width="18%">
  <img src="assets/screenshots/Crono.jpg" alt="Crono" width="18%">
  <img src="assets/screenshots/Impostazioni.jpg" alt="Impostazioni" width="18%">
  <img src="assets/screenshots/Personalizzazione.jpg" alt="Personalizzazione" width="18%">
</p>

## Stack tecnologico

- [Flutter](https://flutter.dev) / Dart
- [Provider](https://pub.dev/packages/provider) per la gestione dello stato
- [Sembast](https://pub.dev/packages/sembast) come database locale
- [fl_chart](https://pub.dev/packages/fl_chart) per i grafici
- [shared_preferences](https://pub.dev/packages/shared_preferences) per le impostazioni utente

## Per iniziare

Requisiti: [Flutter SDK](https://docs.flutter.dev/get-started/install) (vedi `environment.sdk` in `pubspec.yaml` per la versione minima).

```bash
flutter pub get
flutter run
```

## Struttura del progetto

```
lib/
├── models/       # Modelli dati (atleta, squadra, cronometraggio)
├── repositories/ # Accesso al database locale
├── screens/      # Schermate dell'app
├── services/     # Servizi (tema, lingua, impostazioni cronometro)
├── l10n/         # File di localizzazione (it/en)
└── utils/        # Utility varie
```

## Changelog

Le modifiche di ogni versione sono documentate in [CHANGELOG.md](CHANGELOG.md).
