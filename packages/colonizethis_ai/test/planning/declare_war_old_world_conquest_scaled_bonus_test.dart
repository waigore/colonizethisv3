// Unit tests for `declareWarOldWorldConquestScaledBonus` — Phase 3
// diplomacy declare-war OW scoring (Refs #2847).

import 'package:colonizethis_ai/src/planning/phase_planner_diplomacy_filter.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('declareWarOldWorldConquestScaledBonus', () {
    test('weight 1.0 is identity-equal to base bonus', () {
      expect(
        declareWarOldWorldConquestScaledBonus(
          baseBonus: kDeclareWarStalledOwMinorPriorityBonus,
          oldWorldConquestWeight: 1.0,
        ),
        kDeclareWarStalledOwMinorPriorityBonus,
      );
      expect(
        declareWarOldWorldConquestScaledBonus(
          baseBonus: kDeclareWarAdjacentOwnerBonus,
          oldWorldConquestWeight: 1.0,
        ),
        kDeclareWarAdjacentOwnerBonus,
      );
    });

    test('weight <= 0.0 returns zero', () {
      expect(
        declareWarOldWorldConquestScaledBonus(
          baseBonus: kDeclareWarStalledOwMinorPriorityBonus,
          oldWorldConquestWeight: 0.0,
        ),
        0,
      );
      expect(
        declareWarOldWorldConquestScaledBonus(
          baseBonus: 100,
          oldWorldConquestWeight: -0.1,
        ),
        0,
      );
    });

    test('early-sprint default 0.95 retains 95% OW bias', () {
      expect(
        declareWarOldWorldConquestScaledBonus(
          baseBonus: 100,
          oldWorldConquestWeight: 0.95,
        ),
        95,
      );
    });

    test('OW=9 curve row 0.80 scales linearly', () {
      expect(
        declareWarOldWorldConquestScaledBonus(
          baseBonus: kDeclareWarAdjacentOwnerBonus,
          oldWorldConquestWeight: 0.80,
        ),
        (kDeclareWarAdjacentOwnerBonus * 0.80).round(),
      );
    });

    test('weights above 1.0 clamp to identity at 1.0', () {
      expect(
        declareWarOldWorldConquestScaledBonus(
          baseBonus: 50,
          oldWorldConquestWeight: 1.5,
        ),
        50,
      );
    });

    test('is deterministic for identical inputs (Refs #2509 Must-have #7)', () {
      final first = declareWarOldWorldConquestScaledBonus(
        baseBonus: 280,
        oldWorldConquestWeight: 0.80,
      );
      final second = declareWarOldWorldConquestScaledBonus(
        baseBonus: 280,
        oldWorldConquestWeight: 0.80,
      );
      expect(second, first);
    });
  });
}
