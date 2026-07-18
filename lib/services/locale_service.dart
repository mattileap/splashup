import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestisce la lingua dell'app.
/// `null` = segui la lingua di sistema (default, comportamento storico).
class LocaleService with ChangeNotifier {
  static const _localeKey = 'appLocale';

  /// Codici lingua supportati dall'app (devono combaciare con
  /// AppLocalizations.supportedLocales).
  static const supportedLanguageCodes = ['en', 'it'];

  final SharedPreferences _prefs;
  Locale? _locale;

  LocaleService(this._prefs) : _locale = _readLocale(_prefs);

  static Locale? _readLocale(SharedPreferences prefs) {
    final code = prefs.getString(_localeKey);
    if (code == null || !supportedLanguageCodes.contains(code)) return null;
    return Locale(code);
  }

  /// La lingua scelta dall'utente, o null per "Sistema".
  Locale? get locale => _locale;

  /// Imposta la lingua. Passare null per tornare a "Sistema".
  void setLocale(Locale? locale) {
    _locale = locale;
    if (locale == null) {
      _prefs.remove(_localeKey);
    } else {
      _prefs.setString(_localeKey, locale.languageCode);
    }
    notifyListeners();
  }
}
