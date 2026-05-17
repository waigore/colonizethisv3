// TurnTimeMapping. SPEC/game/turn-time-mapping.md.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('TurnTimeMapping', () {
    test('yearAtTurn turn 1 returns startYear', () {
      expect(TurnTimeMapping.gdd01.yearAtTurn(1), 1500);
    });

    test('yearAtTurn turn 100 returns year before cutoff', () {
      // 1500 + 99*2 = 1698
      expect(TurnTimeMapping.gdd01.yearAtTurn(100), 1698);
    });

    test('yearAtTurn turn 101 returns cutoffYear', () {
      expect(TurnTimeMapping.gdd01.yearAtTurn(101), 1700);
    });

    test('yearAtTurn turn 102 returns year after cutoff', () {
      expect(TurnTimeMapping.gdd01.yearAtTurn(102), 1701);
    });

    test('turnNumberForStartCalendarYear 1800 is turn 201', () {
      expect(
        TurnTimeMapping.gdd01.turnNumberForStartCalendarYear(1800),
        201,
      );
    });

    test('turnNumberForStartCalendarYear 1699 is unreachable (gap)', () {
      expect(TurnTimeMapping.gdd01.turnNumberForStartCalendarYear(1699), isNull);
    });

    test('yearAtTurn turn 0 (boundary, spec undefined)', () {
      // Turn 0 not defined by GDD; implementation yields startYear - yearsPerTurnBeforeCutoff.
      expect(TurnTimeMapping.gdd01.yearAtTurn(0), 1498);
    });
  });
}
