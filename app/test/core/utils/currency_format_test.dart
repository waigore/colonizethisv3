// Tests for currency / number formatting helpers.
// SPEC/ui/train-civilians-dialog.md, SPEC/ui/train-military-dialog.md.

import 'package:colonizethis_app/core/utils/currency_format.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('formatThousands', () {
    test('groups thousands with commas', () {
      expect(formatThousands(0), '0');
      expect(formatThousands(12), '12');
      expect(formatThousands(1000), '1,000');
      expect(formatThousands(5000), '5,000');
      expect(formatThousands(1234567), '1,234,567');
    });

    test('preserves the minus sign for negative values', () {
      expect(formatThousands(-1240), '-1,240');
    });
  });

  group('formatTreasuryCurrency', () {
    test('prepends £ and groups thousands', () {
      expect(formatTreasuryCurrency(5000), '£5,000');
      expect(formatTreasuryCurrency(1000), '£1,000');
      expect(formatTreasuryCurrency(10000), '£10,000');
    });

    test('does not abbreviate with k', () {
      expect(formatTreasuryCurrency(5000).contains('k'), isFalse);
    });
  });
}
