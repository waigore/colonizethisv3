import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/features/game/utils/commodity_ui_helpers.dart';
import 'package:colonizethis_app/features/game/utils/tech_ui_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('eraRoman', () {
    test('returns roman numerals for the first four eras', () {
      expect(eraRoman(1), 'I');
      expect(eraRoman(2), 'II');
      expect(eraRoman(3), 'III');
      expect(eraRoman(4), 'IV');
    });

    test('falls back to numeric string outside supported range', () {
      expect(eraRoman(0), '0');
      expect(eraRoman(5), '5');
    });
  });

  group('commodityDisplayName', () {
    test('returns catalog display name for known commodity', () {
      expect(commodityDisplayName('castIron'), 'Cast iron');
    });

    test('returns input id for unknown commodity', () {
      expect(commodityDisplayName('unknown_commodity'), 'unknown_commodity');
    });
  });
}
