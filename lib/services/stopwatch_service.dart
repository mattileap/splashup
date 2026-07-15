import 'dart:async';
import 'package:flutter/foundation.dart';

/// A service that manages the state and logic of a stopwatch.
class StopwatchService extends ChangeNotifier {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  Duration _elapsed = Duration.zero;
  List<Duration> _laps = [];

  Duration get elapsed => _elapsed;
  List<Duration> get laps => _laps;
  bool get isRunning => _stopwatch.isRunning;

  // Starts or resumes the stopwatch.
  void start() {
    if (isRunning) return;
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      _elapsed = _stopwatch.elapsed;
      notifyListeners();
    });
  }

  // Pauses the stopwatch.
  void stop() {
    _stopwatch.stop();
    // Cattura il tempo esatto al momento dello stop: il timer aggiorna
    // _elapsed solo ogni 10ms, senza questa riga il tempo salvato poteva
    // essere fino a 10ms più vecchio del momento reale di stop.
    _elapsed = _stopwatch.elapsed;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  // Records a lap time.
  void lap() {
    if (!isRunning) return;
    _laps.add(_stopwatch.elapsed);
    notifyListeners();
  }

  // Resets the stopwatch and clears all laps.
  void reset() {
    _stopwatch.reset();
    _elapsed = Duration.zero;
    _laps = [];
    if (!isRunning) {
      notifyListeners();
    }
  }

  // Helper to format Duration into a MM:SS.ss string.
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    // REMOVED: The unused 'threeDigits' function has been removed.
    // Niente remainder(60): se il cronometro resta attivo oltre un'ora la
    // stringa andava in wrap (65' → "05:00.00") mentre i millisecondi
    // salvati restavano corretti → dato incoerente nel DB.
    String twoDigitMinutes = twoDigits(duration.inMinutes);
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String twoDigitHundredths = (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return "$twoDigitMinutes:$twoDigitSeconds.$twoDigitHundredths";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
