// Unit tests for `planning_weight_scale.dart` (Refs #3941 topic split).
// Pins `scaleWeightedBonus` and `clampPhaseWeightUpperUnit`.
// `colonialPressureScaleFromWeight` / `planningListEquals` remain in
// `ai_dedup_phase1_helpers_test.dart`.

import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_test/test.dart';
void main() {
  group('scaleWeightedBonus', () {
    test('returns 0 when weight <= 0.0', () {
      expect(scaleWeightedBonus(0.0, 45), 0);
      expect(scaleWeightedBonus(-0.5, 45), 0);
    });

    test('returns baseConstant exactly when weight == 1.0', () {
      expect(scaleWeightedBonus(1.0, 45), 45);
      expect(scaleWeightedBonus(1.0, 360), 360);
    });

    test('clamps weight > 1.0 to 1.0', () {
      expect(scaleWeightedBonus(1.5, 45), 45);
      expect(scaleWeightedBonus(2.0, 100), 100);
    });

    test('rounds intermediate weights', () {
      expect(scaleWeightedBonus(0.05, 45), 2);
      expect(scaleWeightedBonus(0.6, 50), 30);
    });
  });

  group('clampPhaseWeightUpperUnit (Refs #3717)', () {
    test('caps weights above the unit ceiling to 1.0', () {
      expect(clampPhaseWeightUpperUnit(1.5), 1.0);
      expect(clampPhaseWeightUpperUnit(2.0), 1.0);
      expect(clampPhaseWeightUpperUnit(100.0), 1.0);
    });

    test('returns the boundary weight 1.0 unchanged (strict > ceiling)', () {
      expect(clampPhaseWeightUpperUnit(1.0), 1.0);
    });

    test('passes through in-range weights below the ceiling unchanged', () {
      expect(clampPhaseWeightUpperUnit(0.0), 0.0);
      expect(clampPhaseWeightUpperUnit(0.05), 0.05);
      expect(clampPhaseWeightUpperUnit(0.6), 0.6);
      expect(clampPhaseWeightUpperUnit(0.999), 0.999);
    });

    test(
      'does not lower-clamp — negative inputs pass through (callers guard '
      '<= 0.0 themselves)',
      () {
        expect(clampPhaseWeightUpperUnit(-0.5), -0.5);
      },
    );

    test('matches the inline ternary it replaces for representative weights', () {
      for (final w in <double>[-1.0, 0.0, 0.05, 0.5, 1.0, 1.0001, 3.0]) {
        expect(clampPhaseWeightUpperUnit(w), w > 1.0 ? 1.0 : w);
      }
    });
  });
}
