import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splashup/screens/add_edit_chrono_screen.dart';

// Helper: builds a TextEditingValue with the cursor at the end, mimicking
// what the framework passes to an input formatter.
TextEditingValue value(String text) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

void main() {
  late TimeInputFormatter formatter;

  setUp(() {
    formatter = TimeInputFormatter();
  });

  group('TimeInputFormatter.formatEditUpdate', () {
    test('typing a digit into an empty field yields 00:00.0d', () {
      final result = formatter.formatEditUpdate(value(''), value('5'));
      expect(result.text, '00:00.05');
      expect(result.selection.baseOffset, result.text.length);
    });

    test('typing consecutive digits shifts left', () {
      var current = formatter.formatEditUpdate(value(''), value('5'));
      expect(current.text, '00:00.05');
      current =
          formatter.formatEditUpdate(current, value('${current.text}3'));
      expect(current.text, '00:00.53');
    });

    test('typing a digit into a pre-filled field shifts digits left', () {
      final result =
          formatter.formatEditUpdate(value('01:23.45'), value('01:23.456'));
      expect(result.text, '12:34.56');
    });

    test('backspace shifts digits right', () {
      final result =
          formatter.formatEditUpdate(value('01:23.45'), value('01:23.4'));
      expect(result.text, '00:12.34');
    });

    test('typing a decimal point is ignored (value unchanged)', () {
      final result =
          formatter.formatEditUpdate(value('01:23.45'), value('01:23.45.'));
      expect(result.text, '01:23.45');
    });

    test('typing a letter is ignored (value unchanged)', () {
      final result =
          formatter.formatEditUpdate(value('01:23.45'), value('01:23.45a'));
      expect(result.text, '01:23.45');
    });

    test('clearing the field resets to 00:00.00', () {
      final result = formatter.formatEditUpdate(value('01:23.45'), value(''));
      expect(result.text, '00:00.00');
    });

    test('pre-filled 3-digit minutes stay editable, length preserved', () {
      // Typing a digit into "100:23.45" keeps the 3-digit minutes layout.
      final result =
          formatter.formatEditUpdate(value('100:23.45'), value('100:23.456'));
      expect(result.text, '002:34.56');
      expect(result.text.length, '100:23.45'.length);
    });

    test('backspace on 3-digit minutes shifts right, length preserved', () {
      final result =
          formatter.formatEditUpdate(value('100:23.45'), value('100:23.4'));
      expect(result.text, '010:02.34');
      expect(result.text.length, '100:23.45'.length);
    });

    test('cursor is always placed at the end of the result', () {
      final result =
          formatter.formatEditUpdate(value('01:23.45'), value('01:23.456'));
      expect(result.selection.baseOffset, result.text.length);
    });
  });
}
