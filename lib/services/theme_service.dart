import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Temi colore disponibili per la personalizzazione dell'app.
/// Ogni tema definisce il seed per il tema chiaro e per quello scuro.
/// "blue" è il default e replica l'aspetto storico dell'app
/// (blu in chiaro, blueGrey in scuro).
enum AppColorTheme {
  blue(Colors.blue, Colors.blueGrey),
  teal(Colors.teal, Colors.teal),
  green(Colors.green, Colors.green),
  coral(Colors.deepOrange, Colors.deepOrange),
  purple(Colors.deepPurple, Colors.deepPurple),
  pink(Colors.pink, Colors.pink);

  const AppColorTheme(this.lightSeed, this.darkSeed);
  final Color lightSeed;
  final Color darkSeed;
}

/// Font disponibili: standard (Roboto/Material) e OpenDyslexic
/// per gli utenti con dislessia.
enum AppFont {
  standard(null),
  openDyslexic('OpenDyslexic');

  const AppFont(this.family);
  final String? family;
}

/// Dimensione del testo (moltiplicatore applicato sopra la scala di sistema).
enum AppTextSize {
  small(0.9),
  normal(1.0),
  large(1.15);

  const AppTextSize(this.factor);
  final double factor;
}

class ThemeService with ChangeNotifier {
  static const _themeModeKey = 'themeMode';
  static const _colorThemeKey = 'colorTheme';
  static const _fontKey = 'appFont';
  static const _textSizeKey = 'textSize';

  final SharedPreferences _prefs;
  ThemeMode _themeMode;
  AppColorTheme _colorTheme;
  AppFont _font;
  AppTextSize _textSize;

  ThemeService(this._prefs)
      : _themeMode = _readEnum(
          ThemeMode.values, _prefs.getString(_themeModeKey), ThemeMode.system),
        _colorTheme = _readEnum(AppColorTheme.values,
            _prefs.getString(_colorThemeKey), AppColorTheme.blue),
        _font = _readEnum(
            AppFont.values, _prefs.getString(_fontKey), AppFont.standard),
        _textSize = _readEnum(AppTextSize.values,
            _prefs.getString(_textSizeKey), AppTextSize.normal);

  /// Lettura difensiva: se in futuro un valore salvato non esiste più
  /// (es. tema rimosso), si torna al default invece di crashare.
  static T _readEnum<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null) return fallback;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  ThemeMode get themeMode => _themeMode;
  AppColorTheme get colorTheme => _colorTheme;
  AppFont get font => _font;
  AppTextSize get textSize => _textSize;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setString(_themeModeKey, mode.name);
    notifyListeners();
  }

  void setColorTheme(AppColorTheme theme) {
    _colorTheme = theme;
    _prefs.setString(_colorThemeKey, theme.name);
    notifyListeners();
  }

  void setFont(AppFont font) {
    _font = font;
    _prefs.setString(_fontKey, font.name);
    notifyListeners();
  }

  void setTextSize(AppTextSize size) {
    _textSize = size;
    _prefs.setString(_textSizeKey, size.name);
    notifyListeners();
  }

  /// Costruisce il ThemeData chiaro in base alle preferenze correnti.
  ThemeData buildLightTheme() {
    // Caso speciale per il tema di default: mantiene l'AppBar blu storica.
    final scheme = ColorScheme.fromSeed(
      seedColor: _colorTheme.lightSeed,
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      fontFamily: _font.family,
      appBarTheme: AppBarTheme(
        backgroundColor: _colorTheme == AppColorTheme.blue
            ? Colors.blue.shade700
            : scheme.primary,
        foregroundColor: _colorTheme == AppColorTheme.blue
            ? Colors.white
            : scheme.onPrimary,
      ),
      useMaterial3: true,
    );
  }

  /// Costruisce il ThemeData scuro in base alle preferenze correnti.
  ThemeData buildDarkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _colorTheme.darkSeed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      colorScheme: scheme,
      fontFamily: _font.family,
      appBarTheme: AppBarTheme(
        backgroundColor: _colorTheme == AppColorTheme.blue
            ? Colors.blueGrey.shade800
            : scheme.surfaceContainerHigh,
        foregroundColor: _colorTheme == AppColorTheme.blue
            ? Colors.white
            : scheme.onSurface,
      ),
      useMaterial3: true,
    );
  }
}
