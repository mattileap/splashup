import 'package:flutter_test/flutter_test.dart';
import 'package:splashup/services/stopwatch_service.dart';

void main() {
  group('StopwatchService.formatDuration', () {
    test('formats zero duration', () {
      expect(StopwatchService.formatDuration(Duration.zero), '00:00.00');
    });

    test('formats 65 minutes without wrapping', () {
      expect(
        StopwatchService.formatDuration(const Duration(minutes: 65)),
        '65:00.00',
      );
    });

    test('formats minutes, seconds and hundredths', () {
      expect(
        StopwatchService.formatDuration(const Duration(milliseconds: 83450)),
        '01:23.45',
      );
    });

    test('truncates sub-hundredth milliseconds', () {
      expect(
        StopwatchService.formatDuration(const Duration(milliseconds: 999)),
        '00:00.99',
      );
      expect(
        StopwatchService.formatDuration(const Duration(milliseconds: 1005)),
        '00:01.00',
      );
    });
  });

  group('StopwatchService state', () {
    test('initial state is zeroed and not running', () {
      final service = StopwatchService();
      expect(service.isRunning, isFalse);
      expect(service.elapsed, Duration.zero);
      expect(service.laps, isEmpty);
      service.dispose();
    });

    test('lap() when not running is a no-op', () {
      final service = StopwatchService();
      service.lap();
      service.lap();
      expect(service.laps, isEmpty);
      service.dispose();
    });

    test('reset() clears laps and elapsed', () {
      final service = StopwatchService();

      // Start records real time; lap() reads the stopwatch directly, so it
      // works synchronously without waiting for any timer tick.
      service.start();
      expect(service.isRunning, isTrue);
      service.lap();
      expect(service.laps.length, 1);

      service.stop();
      expect(service.isRunning, isFalse);

      service.reset();
      expect(service.elapsed, Duration.zero);
      expect(service.laps, isEmpty);
      expect(service.isRunning, isFalse);

      service.dispose();
    });

    test('reset() on a fresh service leaves state zeroed', () {
      final service = StopwatchService();
      service.reset();
      expect(service.elapsed, Duration.zero);
      expect(service.laps, isEmpty);
      service.dispose();
    });
  });
}
