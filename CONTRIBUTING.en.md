# Contributing to SplashUp

[🇮🇹 Italiano](CONTRIBUTING.md) | 🇬🇧 English

Thanks for your interest in contributing! SplashUp is open source (MIT license, see [LICENSE](LICENSE)) and contributions are welcome: bug fixes, new features, support for new platforms, translations, and more.

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (see `environment.sdk` in `pubspec.yaml` for the minimum version).
- An editor with Dart/Flutter support (VS Code or Android Studio recommended).

## Getting started

1. Fork the repository and clone it locally.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app on an emulator/device (or desktop/web):
   ```bash
   flutter run
   ```
4. Create a branch for your change:
   ```bash
   git checkout -b descriptive-branch-name
   ```

## Before opening a Pull Request

- Run static analysis and tests:
  ```bash
  flutter analyze
  flutter test
  ```
- If you add user-facing text, remember to update the localization keys in `lib/l10n/app_it.arb` and `lib/l10n/app_en.arb`.
- If the change is user-facing, update [CHANGELOG.md](CHANGELOG.md).
- Describe what changes and why in the PR; for bug fixes, explain how to reproduce the original issue.

## Reporting bugs or proposing ideas

Open an [Issue](../../issues) describing the problem (with reproduction steps, if possible) or the proposed idea. For new platforms or major features, it's best to open a discussion Issue before writing code, to align on the approach first.

## Note on branding

The code is MIT licensed, but the "SplashUp" name and app icon are reserved for the official release (see [LICENSE](LICENSE)). If you publish a fork on a store, use a different name and icon.
