import 'package:flutter_test/flutter_test.dart';
import 'package:splashup/l10n/app_localizations_en.dart';
import 'package:splashup/models/chrono_model.dart';

// Helper: builds a Chrono with sensible defaults, overriding only what
// each test cares about.
Chrono buildChrono({String finalTime = '00:00.00', int? finalTimeMs}) {
  return Chrono(
    id: 'test-id',
    date: DateTime(2026, 1, 1),
    poolLength: 50,
    distance: 100,
    style: 'Freestyle',
    finalTime: finalTime,
    finalTimeMs: finalTimeMs,
    notes: '',
    type: 'Training',
  );
}

void main() {
  group('Chrono.parseTimeToMilliseconds', () {
    test('parses full MM:SS.cc format', () {
      expect(Chrono.parseTimeToMilliseconds('01:23.45'), 83450);
    });

    test('parses minutes greater than 59 (65:00.00)', () {
      expect(Chrono.parseTimeToMilliseconds('65:00.00'), 3900000);
    });

    test('parses SS.cc format', () {
      expect(Chrono.parseTimeToMilliseconds('32.50'), 32500);
    });

    test('treats "32.5" as SS.cc (5 centiseconds, not half a second)', () {
      // '32.5' splits on [:.] into 2 parts, so it takes the SS.cc branch:
      // 32 seconds + 5 centiseconds = 32050 ms (NOT 32500).
      expect(Chrono.parseTimeToMilliseconds('32.5'), 32050);
    });

    test('parses plain seconds without separators', () {
      expect(Chrono.parseTimeToMilliseconds('32'), 32000);
    });

    test('returns null for empty string', () {
      expect(Chrono.parseTimeToMilliseconds(''), isNull);
    });

    test('returns null for garbage input', () {
      expect(Chrono.parseTimeToMilliseconds('abc'), isNull);
    });

    test('returns null for non-numeric parts in time format', () {
      expect(Chrono.parseTimeToMilliseconds('aa:bb.cc'), isNull);
    });
  });

  group('Chrono.formatMillisecondsToTime', () {
    test('formats zero', () {
      expect(Chrono.formatMillisecondsToTime(0), '00:00.00');
    });

    test('formats negative values as 00:00.00', () {
      expect(Chrono.formatMillisecondsToTime(-500), '00:00.00');
    });

    test('formats 65 minutes without wrapping', () {
      expect(Chrono.formatMillisecondsToTime(3900000), '65:00.00');
    });

    test('floors sub-centisecond milliseconds', () {
      // 83459 ms -> 45.9 centiseconds -> floored to 45.
      expect(Chrono.formatMillisecondsToTime(83459), '01:23.45');
      // 5 ms -> 0.5 centiseconds -> floored to 0.
      expect(Chrono.formatMillisecondsToTime(65005), '01:05.00');
    });

    test('round-trips with parseTimeToMilliseconds for centisecond values', () {
      for (final ms in [0, 450, 32050, 83450, 3599990, 3900000]) {
        final formatted = Chrono.formatMillisecondsToTime(ms);
        expect(Chrono.parseTimeToMilliseconds(formatted), ms,
            reason: 'round-trip failed for $ms ms ("$formatted")');
      }
    });
  });

  group('Chrono.displayTime', () {
    test('normalizes a "00:65.00" string when finalTimeMs is 65000', () {
      final chrono = buildChrono(finalTime: '00:65.00', finalTimeMs: 65000);
      expect(chrono.displayTime, '01:05.00');
    });

    test('finalTimeMs takes precedence over the finalTime string', () {
      final chrono = buildChrono(finalTime: '00:10.00', finalTimeMs: 90000);
      expect(chrono.displayTime, '01:30.00');
    });

    test('falls back to parsing the string when finalTimeMs is null', () {
      final chrono = buildChrono(finalTime: '00:65.00', finalTimeMs: null);
      expect(chrono.displayTime, '01:05.00');
    });

    test('returns unparseable string as-is when finalTimeMs is null', () {
      final chrono = buildChrono(finalTime: 'not a time', finalTimeMs: null);
      expect(chrono.displayTime, 'not a time');
    });
  });

  group('Chrono.validateSplits', () {
    final l10n = AppLocalizationsEn();

    test('returns null for an empty list', () {
      expect(
        Chrono.validateSplits(
          splits: [],
          totalDistance: 100,
          poolLength: 50,
          l10n: l10n,
        ),
        isNull,
      );
    });

    test('returns null for a valid list', () {
      final splits = [
        ChronoSplit(distance: 50, time: 30000),
        ChronoSplit(distance: 100, time: 62000),
      ];
      expect(
        Chrono.validateSplits(
          splits: splits,
          totalDistance: 100,
          poolLength: 50,
          l10n: l10n,
        ),
        isNull,
      );
    });

    test('returns an error for a split time <= 0', () {
      final splits = [ChronoSplit(distance: 50, time: 0)];
      expect(
        Chrono.validateSplits(
          splits: splits,
          totalDistance: 100,
          poolLength: 50,
          l10n: l10n,
        ),
        isNotNull,
      );
    });

    test('returns an error when distance is not a multiple of pool length',
        () {
      final splits = [ChronoSplit(distance: 30, time: 20000)];
      expect(
        Chrono.validateSplits(
          splits: splits,
          totalDistance: 100,
          poolLength: 50,
          l10n: l10n,
        ),
        isNotNull,
      );
    });

    test('returns an error when distance exceeds the total distance', () {
      final splits = [ChronoSplit(distance: 150, time: 20000)];
      expect(
        Chrono.validateSplits(
          splits: splits,
          totalDistance: 100,
          poolLength: 50,
          l10n: l10n,
        ),
        isNotNull,
      );
    });

    test('returns an error for non-increasing distances', () {
      final splits = [
        ChronoSplit(distance: 50, time: 30000),
        ChronoSplit(distance: 50, time: 60000),
      ];
      expect(
        Chrono.validateSplits(
          splits: splits,
          totalDistance: 100,
          poolLength: 50,
          l10n: l10n,
        ),
        isNotNull,
      );
    });

    test('returns an error for non-increasing times', () {
      final splits = [
        ChronoSplit(distance: 50, time: 30000),
        ChronoSplit(distance: 100, time: 30000),
      ];
      expect(
        Chrono.validateSplits(
          splits: splits,
          totalDistance: 100,
          poolLength: 50,
          l10n: l10n,
        ),
        isNotNull,
      );
    });

    test('skips time checks for splits with null time', () {
      final splits = [
        ChronoSplit(distance: 50, time: null),
        ChronoSplit(distance: 100, time: 60000),
      ];
      expect(
        Chrono.validateSplits(
          splits: splits,
          totalDistance: 100,
          poolLength: 50,
          l10n: l10n,
        ),
        isNull,
      );
    });
  });
}
