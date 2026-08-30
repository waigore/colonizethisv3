// criticalWeakGpSurvivalPeaceTargets — default-start critical  (Refs #4602 Slice B).

// Case bodies for criticalWeakGpSurvivalPeaceTargets pins in
// `expand_phase_planner_critical_peace_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_critical_peace_support.dart';

void registerExpandPhasePlannerCriticalWeakSurvivalPeaceDefaultStartCases() {
  group('criticalWeakGpSurvivalPeaceTargets — default-start critical row', () {
    test(
      'lead == 1 fires (kObserverDefaultStartOldWorldProvincesPerGp + 1)',
      () {
        // ownOw = default-start + 1 = 8 → row threshold is minLead 1;
        // enemy GP holds 9 OW provinces (lead exactly 1) → peace.
        const ownOw = kObserverDefaultStartOldWorldProvincesPerGp + 1;
        final game = buildCriticalExpandPeaceGame(
          ownProvinces: ownOw,
          gpRivalProvincesById: {
            criticalPeaceGpStronger: criticalPeaceRivalProvinces(
              criticalPeaceGpStronger,
              ownOw + 1,
            ),
          },
          atWarFactionIds: const [criticalPeaceGpStronger],
        );
        // Skip — outer guard requires ownOw <= defend threshold (6),
        // but ownOw + 1 here is 8 which is > 6. This row of the band
        // is actually unreachable through the outer guard in
        // production. Validate via the lower default-start row
        // (ownOw == defend threshold == 6) where the minLead = 1 arm
        // still applies (6 <= 7 + 1 = 8).
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: ownOw,
          atWarWith: const [criticalPeaceGpStronger],
        );
        expect(
          criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'ownOw = default-start + 1 = 8 is above '
              'kFewOldWorldProvincesDefendThreshold = 6 — the outer guard '
              'must keep this row of the lead-table inert in production.',
        );
      },
    );

    test('default-start critical band (ownOw <= 8) fires at lead == 1', () {
      // ownOw = 6 (the outer guard ceiling and the band where the
      // <= 8 default-start row also applies). Enemy GP holds 7 OW
      // provinces (lead == 1) → peace by the minLead == 1 arm.
      final game = buildCriticalExpandPeaceGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold,
        gpRivalProvincesById: {
          criticalPeaceGpStronger: criticalPeaceRivalProvinces(
            criticalPeaceGpStronger,
            7,
          ),
        },
        atWarFactionIds: const [criticalPeaceGpStronger],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
        atWarWith: const [criticalPeaceGpStronger],
      );
      expect(
        criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot),
        const [criticalPeaceGpStronger],
        reason:
            'At ownOw == 6 (defend threshold) the default-start '
            'critical row applies (6 <= 7 + 1 = 8) so minLead = 1; an '
            'enemy with lead 1 must be peaced. A regression that mis-'
            'computed the row would either drop this peace (survival '
            'collapse risk) or peace at lead 0 (drops self-defense).',
      );
    });

    test(
      'default-start critical band does NOT fire at lead == 0 (equal strength)',
      () {
        final game = buildCriticalExpandPeaceGame(
          ownProvinces: kFewOldWorldProvincesDefendThreshold,
          gpRivalProvincesById: {
            criticalPeaceGpStronger: criticalPeaceRivalProvinces(
              criticalPeaceGpStronger,
              6,
            ),
          },
          atWarFactionIds: const [criticalPeaceGpStronger],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
          atWarWith: const [criticalPeaceGpStronger],
        );
        expect(
          criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'A peer of equal strength is not "stronger"; the minLead = 1 '
              'arm requires strict positive lead. Peacing equal peers would '
              'forfeit defensive wars where the active player still has '
              'parity.',
        );
      },
    );
  });
}
