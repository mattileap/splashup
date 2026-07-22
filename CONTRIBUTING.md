# Contribuire a SplashUp

🇮🇹 Italiano | [🇬🇧 English](CONTRIBUTING.en.md)

Grazie per l'interesse a contribuire! SplashUp è open source (licenza MIT, vedi [LICENSE](LICENSE)) e i contributi sono benvenuti: fix, nuove funzionalità, supporto a nuove piattaforme, traduzioni, ecc.

## Requisiti

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (vedi `environment.sdk` in `pubspec.yaml` per la versione minima).
- Un editor con supporto Dart/Flutter (VS Code o Android Studio consigliati).

## Come iniziare

1. Fai un fork del repository e clonalo in locale.
2. Installa le dipendenze:
   ```bash
   flutter pub get
   ```
3. Avvia l'app su un emulatore/dispositivo (o su desktop/web):
   ```bash
   flutter run
   ```
4. Crea un branch per la tua modifica:
   ```bash
   git checkout -b nome-branch-descrittivo
   ```

## Prima di aprire una Pull Request

- Esegui l'analisi statica e i test:
  ```bash
  flutter analyze
  flutter test
  ```
- Se aggiungi testi visibili nell'app, ricorda di aggiornare le chiavi di localizzazione in `lib/l10n/app_it.arb` e `lib/l10n/app_en.arb`.
- Se la modifica è visibile all'utente, aggiorna il [CHANGELOG.md](CHANGELOG.md).
- Descrivi nella PR cosa cambia e perché; per bug fix, indica come riprodurre il problema originale.

## Segnalare bug o proporre idee

Apri una [Issue](../../issues) descrivendo il problema (con passi per riprodurlo, se possibile) o l'idea proposta. Per nuove piattaforme o feature importanti, è utile aprire prima una Issue di discussione prima di iniziare a scrivere codice, per allinearsi sull'approccio.

## Nota sul brand

Il codice è MIT, ma il nome "SplashUp" e l'icona dell'app sono riservati alla versione ufficiale (vedi [LICENSE](LICENSE)). Se pubblichi un fork su uno store, usa un nome e un'icona diversi.
