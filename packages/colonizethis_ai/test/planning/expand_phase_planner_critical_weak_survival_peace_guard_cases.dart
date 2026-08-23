// criticalWeakGpSurvivalPeaceTargets — canonical outer guards (Refs #4602 Slice B).

// Case bodies for criticalWeakGpSurvivalPeaceTargets pins in
// `expand_phase_planner_critical_peace_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_critical_peace_support.dart';

void registerExpandPhasePlannerCriticalWeakSurvivalPeaceGuardCases() {
  group('criticalWeakGpSurvivalPeaceTargets — canonical outer guards', () {
    test('returns const [] above kFewOldWorldProvincesDefendThreshold', () {
      // ownOw = defend threshold + 1 → outer guard fires; even a
      // dominant stronger GP must not be peaced (the broader
      // criticalOwHoldPeaceTargets and band-specific deciders own
      // this region of the band).
      final game = buildCriticalExpandPeaceGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold + 1,
        gpRivalProvincesById: {
          criticalPeaceGpStronger: criticalPeaceRivalProvinces(
            criticalPeaceGpStronger,
            14,
          ),
        },
        atWarFactionIds: const [criticalPeaceGpStronger],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold + 1,
        atWarWith: const [criticalPeaceGpStronger],
      );
      expect(
        criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Above kFewOldWorldProvincesDefendThreshold the critical-'
            'survival arm must short-circuit. A regression that flipped '
            '> to >= would silently engage the arm one province above '
            'the defend band and dump otherwise rebuildable wars.',
      );
    });

    test('returns const [] when no Great Powers are at war', () {
      // Only a minor and tribe in atWarWith; Game.playerById filters
      // them out and the lead loop has nothing to emit.
      final game = buildCriticalExpandPeaceGame(
        ownProvinces: 5,
        minorIds: const [criticalPeaceMinor1],
        tribeIds: const [criticalPeaceTribe1],
        atWarFactionIds: const [criticalPeaceMinor1, criticalPeaceTribe1],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 5,
        atWarWith: const [criticalPeaceMinor1, criticalPeaceTribe1],
      );
      expect(
        criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Minors and tribes are not Great Powers; the critical-survival '
            'arm operates only on GP factions. The companion minor/tribe '
            'peace deciders own those rows of the band.',
      );
    });
  });
}
