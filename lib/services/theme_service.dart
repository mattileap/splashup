import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService with ChangeNotifier {
  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  ThemeService(this._prefs)
      : _themeMode = ThemeMode.values.byName(
          _prefs.getString('themeMode') ?? 'system',
        );

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setString('themeMode', mode.name);
    notifyListeners();
  }
}
