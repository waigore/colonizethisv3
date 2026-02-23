import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('acceptance criteria (SPEC/game/turn-time-mapping.md)', () {
    test('turn 1 → startYear (1500), turn 100 → 1698, 101 → 1700, 102 → 1701', () {
      expect(turnToYear(1, TurnTimeMapping.gdd01), 1500);
      expect(turnToYear(100, TurnTimeMapping.gdd01), 1698);
      expect(turnToYear(101, TurnTimeMapping.gdd01), 1700);
      expect(turnToYear(102, TurnTimeMapping.gdd01), 1701);
    });
    test('legacy saves (null mapping) behave as GDD 01', () {
      expect(turnToYear(1, null), 1500);
      expect(turnToYear(102, null), 1701);
    });
  });

  group('turnToYear', () {
    test('turn 1 returns 1500 with default mapping', () {
      expect(turnToYear(1, null), 1500);
    });

    test('turn 101 returns 1700 with default mapping', () {
      expect(turnToYear(101, null), 1700);
    });

    test('turn 103 returns 1702 with default mapping', () {
      expect(turnToYear(103, null), 1702);
    });

    test('turn 1 returns 1500 with GDD01', () {
      expect(turnToYear(1, TurnTimeMapping.gdd01), 1500);
    });

    test('turn 100 returns 1698 with GDD01 (last 2-year turn before cutoff)', () {
      expect(turnToYear(100, TurnTimeMapping.gdd01), 1698);
    });

    test('turn 101 returns 1700 with GDD01', () {
      expect(turnToYear(101, TurnTimeMapping.gdd01), 1700);
    });

    test('turn 102 returns 1701 with GDD01', () {
      expect(turnToYear(102, TurnTimeMapping.gdd01), 1701);
    });

    test('turn 47 returns 1592 with GDD01', () {
      expect(turnToYear(47, TurnTimeMapping.gdd01), 1592);
    });

    test('custom mapping works', () {
      const custom = TurnTimeMapping(
        startYear: 1600,
        cutoffYear: 1800,
        yearsPerTurnBeforeCutoff: 5,
        yearsPerTurnAfterCutoff: 2,
      );
      expect(turnToYear(1, custom), 1600);
      expect(turnToYear(2, custom), 1605);
      expect(turnToYear(41, custom), 1800); // (1800-1600)/5 = 40 turns
      expect(turnToYear(42, custom), 1802);
    });
  });

  group('TurnTimeMapping', () {
    test('serialization round-trip', () {
      const mapping = TurnTimeMapping.gdd01;
      final json = mapping.toJson();
      final restored = TurnTimeMapping.fromJson(json);
      expect(restored, mapping);
    });
  });
}
