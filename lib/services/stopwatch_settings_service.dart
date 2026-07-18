import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Precisione di visualizzazione del tempo del cronometro.
/// Riguarda SOLO la visualizzazione: i millisecondi salvati nel DB
/// restano sempre alla precisione massima.
enum StopwatchPrecision { hundredths, tenths }

/// Preferenze del cronometro (feedback, schermo attivo, precisione).
class StopwatchSettingsService with ChangeNotifier {
  static const _hapticKey = 'swHapticFeedback';
  static const _soundKey = 'swSoundFeedback';
  static const _keepScreenOnKey = 'swKeepScreenOn';
  static const _precisionKey = 'swPrecision';

  final SharedPreferences _prefs;
  bool _hapticFeedback;
  bool _soundFeedback;
  bool _keepScreenOn;
  StopwatchPrecision _precision;

  StopwatchSettingsService(this._prefs)
      : _hapticFeedback = _prefs.getBool(_hapticKey) ?? true,
        _soundFeedback = _prefs.getBool(_soundKey) ?? false,
        _keepScreenOn = _prefs.getBool(_keepScreenOnKey) ?? true,
        _precision = _prefs.getString(_precisionKey) ==
                StopwatchPrecision.tenths.name
            ? StopwatchPrecision.tenths
            : StopwatchPrecision.hundredths;

  bool get hapticFeedback => _hapticFeedback;
  bool get soundFeedback => _soundFeedback;
  bool get keepScreenOn => _keepScreenOn;
  StopwatchPrecision get precision => _precision;

  void setHapticFeedback(bool value) {
    _hapticFeedback = value;
    _prefs.setBool(_hapticKey, value);
    notifyListeners();
  }

  void setSoundFeedback(bool value) {
    _soundFeedback = value;
    _prefs.setBool(_soundKey, value);
    notifyListeners();
  }

  void setKeepScreenOn(bool value) {
    _keepScreenOn = value;
    _prefs.setBool(_keepScreenOnKey, value);
    notifyListeners();
  }

  void setPrecision(StopwatchPrecision value) {
    _precision = value;
    _prefs.setString(_precisionKey, value.name);
    notifyListeners();
  }
}
