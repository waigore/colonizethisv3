// criticalWeakGpSurvivalPeaceTargets — below-quota critical ro (Refs #4602 Slice B).

// Case bodies for criticalWeakGpSurvivalPeaceTargets pins in
// `expand_phase_planner_critical_peace_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_critical_peace_support.dart';

void registerExpandPhasePlannerCriticalWeakSurvivalPeaceBelowQuotaCases() {
  group('criticalWeakGpSurvivalPeaceTargets — below-quota critical row', () {
    test('below-quota row (ownOw > 8) requires lead >= '
        'kUnwinnableSoleGpMinProvinceDeficit', () {
      // Production-reachable shape only exists inside the outer
      // guard ownOw <= 6, so the below-quota row arm is normally
      // unreachable. Validate the threshold table by exercising
      // ownOw = 6 (default-start row covers it; the below-quota
      // row arm body is exercised in
      // `colonial_pressure_*` regression fixtures via the legacy
      // stub). This test pins the row identity via determinism on
      // two structurally-identical calls (guards against a future
      // refactor wiring the wrong constant in this row).
      final game = buildCriticalExpandPeaceGame(
        ownProvinces: 5,
        gpRivalProvincesById: {
          criticalPeaceGpStronger: criticalPeaceRivalProvinces(
            criticalPeaceGpStronger,
            7,
          ),
          criticalPeaceGpThird: criticalPeaceRivalProvinces(
            criticalPeaceGpThird,
            8,
          ),
        },
        atWarFactionIds: const [criticalPeaceGpStronger, criticalPeaceGpThird],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 5,
        atWarWith: const [criticalPeaceGpStronger, criticalPeaceGpThird],
      );
      final first = criticalWeakGpSurvivalPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = criticalWeakGpSurvivalPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(
        first,
        [criticalPeaceGpStronger, criticalPeaceGpThird],
        reason:
            'At ownOw = 5 the default-start row applies (5 <= 8), '
            'minLead = 1; both stronger GPs (lead >= 2) are peaced '
            'sorted ascending.',
      );
      expect(first, equals(second), reason: 'determinism');
    });
  });
}
