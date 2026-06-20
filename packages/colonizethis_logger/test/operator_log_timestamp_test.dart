import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('formatOperatorLogTimestamp', () {
    final shape = RegExp(
      r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(Z|[+-]\d{2}:\d{2})$',
    );

    test('includes .000 when milliseconds are zero', () {
      final t = DateTime(2026, 5, 10, 14, 32, 5, 0);
      final s = formatOperatorLogTimestamp(t);
      expect(s, contains('.000'));
      expect(shape.hasMatch(s), isTrue);
    });

    test('includes non-zero milliseconds with three digits', () {
      final t = DateTime(2026, 5, 10, 14, 32, 5, 23);
      final s = formatOperatorLogTimestamp(t);
      expect(s, contains('.023'));
      expect(shape.hasMatch(s), isTrue);
    });
  });
}
