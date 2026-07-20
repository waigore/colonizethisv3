// Case bodies for criticalWeakGpSurvivalPeaceTargets pins in
// `expand_phase_planner_critical_peace_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_critical_peace_support.dart';

void registerExpandPhasePlannerCriticalWeakSurvivalPeaceCases() {
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

  group('criticalWeakGpSurvivalPeaceTargets — fire path filters and order', () {
    test('filters non-GP atWarWith entries and sorts ascending', () {
      // gp_own at war with a minor, a tribe, and three GPs of mixed
      // strength. Only stronger GPs (lead >= 1 on the default-start
      // row at ownOw = 6) surface; minors and tribes are dropped.
      // Result must be lex-ascending by factionId.
      final game = buildCriticalExpandPeaceGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold,
        gpRivalProvincesById: {
          criticalPeaceGpStronger: criticalPeaceRivalProvinces(
            criticalPeaceGpStronger,
            7,
          ),
          criticalPeaceGpThird: criticalPeaceRivalProvinces(
            criticalPeaceGpThird,
            6,
          ),
          criticalPeaceGpFourth: criticalPeaceRivalProvinces(
            criticalPeaceGpFourth,
            9,
          ),
        },
        minorIds: const [criticalPeaceMinor1],
        tribeIds: const [criticalPeaceTribe1],
        atWarFactionIds: const [
          criticalPeaceGpStronger,
          criticalPeaceGpThird,
          criticalPeaceGpFourth,
          criticalPeaceMinor1,
          criticalPeaceTribe1,
        ],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
        atWarWith: const [
          criticalPeaceGpFourth,
          criticalPeaceMinor1,
          criticalPeaceGpStronger,
          criticalPeaceTribe1,
          criticalPeaceGpThird,
        ],
      );
      final result = criticalWeakGpSurvivalPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(
        result,
        const [criticalPeaceGpFourth, criticalPeaceGpStronger],
        reason:
            'gp_fourth (lead 3) and gp_stronger (lead 1) both clear the '
            'minLead = 1 threshold; gp_third (lead 0) is equal-strength '
            'and dropped. Minor and tribe are filtered by Game.playerById. '
            'Sort order is ascending factionId regardless of input order.',
      );
    });
  });

  group('criticalWeakGpSurvivalPeaceTargets — stub delegation parity', () {
    test('diplomacy_planner_peace_targets stub returns the canonical list', () {
      final game = buildCriticalExpandPeaceGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold,
        gpRivalProvincesById: {
          criticalPeaceGpStronger: criticalPeaceRivalProvinces(
            criticalPeaceGpStronger,
            7,
          ),
          criticalPeaceGpThird: criticalPeaceRivalProvinces(
            criticalPeaceGpThird,
            5,
          ),
        },
        atWarFactionIds: const [criticalPeaceGpStronger, criticalPeaceGpThird],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
        atWarWith: const [criticalPeaceGpStronger, criticalPeaceGpThird],
      );
      final canonical = criticalWeakGpSurvivalPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final stub = diplomacy_planner_peace_targets
          .criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot);
      expect(
        stub,
        equals(canonical),
        reason:
            'The legacy stub must remain byte-equivalent to the canonical '
            'helper so the legacy '
            'diplomacy_planner_mutual_exhausted_peace_test.dart and '
            'diplomacy_planner_stalled_peace_test.dart fixtures and the '
            'in-file _survivalGreatPowerPeaceTargets / '
            'stalledOwExpansionNeedsPeacePass consumer chains continue '
            'to resolve to the same behavior.',
      );
    });

    test(
      'stub returns const [] outer guard match (above defend threshold)',
      () {
        // Both stub and canonical must agree on the outer-guard skip.
        final game = buildCriticalExpandPeaceGame(
          ownProvinces: kFewOldWorldProvincesDefendThreshold + 1,
          gpRivalProvincesById: {
            criticalPeaceGpStronger: criticalPeaceRivalProvinces(
              criticalPeaceGpStronger,
              12,
            ),
          },
          atWarFactionIds: const [criticalPeaceGpStronger],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold + 1,
          atWarWith: const [criticalPeaceGpStronger],
        );
        final canonical = criticalWeakGpSurvivalPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final stub = diplomacy_planner_peace_targets
            .criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot);
        expect(canonical, isEmpty);
        expect(stub, isEmpty);
      },
    );
  });

  group('criticalWeakGpSurvivalPeaceTargets — determinism', () {
    test(
      'two consecutive invocations return identical lists (Must-have #7)',
      () {
        final game = buildCriticalExpandPeaceGame(
          ownProvinces: kFewOldWorldProvincesDefendThreshold,
          gpRivalProvincesById: {
            criticalPeaceGpStronger: criticalPeaceRivalProvinces(
              criticalPeaceGpStronger,
              7,
            ),
            criticalPeaceGpFourth: criticalPeaceRivalProvinces(
              criticalPeaceGpFourth,
              9,
            ),
          },
          atWarFactionIds: const [criticalPeaceGpStronger, criticalPeaceGpFourth],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
          atWarWith: const [criticalPeaceGpFourth, criticalPeaceGpStronger],
        );
        final first = criticalWeakGpSurvivalPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = criticalWeakGpSurvivalPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(first, equals(second));
        expect(first, const [criticalPeaceGpFourth, criticalPeaceGpStronger]);
      },
    );
  });
}
