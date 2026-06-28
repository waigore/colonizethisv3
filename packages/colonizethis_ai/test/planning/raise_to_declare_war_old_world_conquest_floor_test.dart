// Unit tests for `raiseToDeclareWarOldWorldConquestFloor` — the declare-war
// OW-conquest scoring-skeleton dedup helper (Refs #3717). It is the single
// source of truth for the repeated "raise the running declare-war score to at
// least this OW-conquest-scaled floor, never lowering it" pattern previously
// inlined as `math.max(s, declareWarOldWorldConquestScaledBonus(...))` across
// `diplomatic_candidate_scoring_declare_war_bonuses.dart`.

import 'dart:math' as math;

import 'package:colonizethis_ai/src/planning/phase_planner_diplomacy_filter.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('raiseToDeclareWarOldWorldConquestFloor', () {
    test('raises score up to the scaled floor when below it', () {
      // weight 1.0 → floor identity (200); current 50 < 200 → raised to 200.
      expect(
        raiseToDeclareWarOldWorldConquestFloor(
          currentScore: 50,
          floorBonus: 200,
          oldWorldConquestWeight: 1.0,
        ),
        200,
      );
    });

    test('leaves score unchanged when already at or above the scaled floor', () {
      // current 250 >= scaled floor 200 → unchanged (never lowers).
      expect(
        raiseToDeclareWarOldWorldConquestFloor(
          currentScore: 250,
          floorBonus: 200,
          oldWorldConquestWeight: 1.0,
        ),
        250,
      );
      // Exact-equality boundary: current == scaled floor → unchanged.
      expect(
        raiseToDeclareWarOldWorldConquestFloor(
          currentScore: 200,
          floorBonus: 200,
          oldWorldConquestWeight: 1.0,
        ),
        200,
      );
    });

    test('weight <= 0.0 collapses the floor to zero (cannot lower score)', () {
      // scaled floor → 0, so max(currentScore, 0) keeps a positive score.
      expect(
        raiseToDeclareWarOldWorldConquestFloor(
          currentScore: 37,
          floorBonus: 500,
          oldWorldConquestWeight: 0.0,
        ),
        37,
      );
    });

    test('floor is scaled by the soft-phase OW-conquest weight curve', () {
      // current 0 < scaled floor round(100 * 0.80) = 80 → raised to 80.
      expect(
        raiseToDeclareWarOldWorldConquestFloor(
          currentScore: 0,
          floorBonus: 100,
          oldWorldConquestWeight: 0.80,
        ),
        80,
      );
    });

    test('is byte-identical to the inlined max-of-scaled-bonus form', () {
      const cases = [
        (10, 200, 1.0),
        (300, 200, 1.0),
        (50, 360, 0.05),
        (0, 100, 0.80),
        (37, 500, 0.0),
        (120, 280, 0.95),
      ];
      for (final (current, floor, weight) in cases) {
        expect(
          raiseToDeclareWarOldWorldConquestFloor(
            currentScore: current,
            floorBonus: floor,
            oldWorldConquestWeight: weight,
          ),
          math.max(
            current,
            declareWarOldWorldConquestScaledBonus(
              baseBonus: floor,
              oldWorldConquestWeight: weight,
            ),
          ),
        );
      }
    });

    test('is deterministic for identical inputs (Refs #2509 Must-have #7)', () {
      final first = raiseToDeclareWarOldWorldConquestFloor(
        currentScore: 60,
        floorBonus: 280,
        oldWorldConquestWeight: 0.80,
      );
      final second = raiseToDeclareWarOldWorldConquestFloor(
        currentScore: 60,
        floorBonus: 280,
        oldWorldConquestWeight: 0.80,
      );
      expect(second, first);
    });
  });
}
