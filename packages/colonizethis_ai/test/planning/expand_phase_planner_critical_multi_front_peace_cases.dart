// Case bodies for criticalMultiFrontGpPeaceTargets pins in
// `expand_phase_planner_critical_peace_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_critical_peace_support.dart';

void registerExpandPhasePlannerCriticalMultiFrontPeaceCases() {
  group('criticalMultiFrontGpPeaceTargets — canonical outer guards', () {
    test(
      'returns const [] above the EXPAND band (ownOw > kObserverConquestMinOwProvincesPerGp)',
      () {
        // ownOw above quota → isObserverConquestExpansionPressure is
        // false AND isAtObserverConquestQuotaBand is false → outer
        // guard fires regardless of GP count.
        final game = buildCriticalExpandPeaceGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp + 2,
          gpRivalProvincesById: {
            criticalPeaceGpStronger: criticalPeaceRivalProvinces(
              criticalPeaceGpStronger,
              6,
            ),
            criticalPeaceGpThird: criticalPeaceRivalProvinces(
              criticalPeaceGpThird,
              6,
            ),
          },
          atWarFactionIds: const [criticalPeaceGpStronger, criticalPeaceGpThird],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp + 2,
          atWarWith: const [criticalPeaceGpStronger, criticalPeaceGpThird],
          invadableProvinceIdsSorted: const [],
        );
        expect(
          criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Above the quota band the quota-met deciders own the '
              'decision; the critical multi-front arm must short-circuit. '
              'A regression that flipped the OR to AND would silently '
              'engage the arm above quota and drop quota-met blockers.',
        );
      },
    );

    test('returns const [] with fewer than two at-war Great Powers', () {
      // Single GP foe inside the stalled band — the
      // multi-front shape does not hold; sole-non-blocker is handled
      // by multiFrontNonBlockerGpPeaceTargets directly (not via this
      // critical wrapper).
      final game = buildCriticalExpandPeaceGame(
        ownProvinces: kStalledOldWorldProvinceThreshold,
        gpRivalProvincesById: {
          criticalPeaceGpStronger: criticalPeaceRivalProvinces(
            criticalPeaceGpStronger,
            9,
          ),
        },
        atWarFactionIds: const [criticalPeaceGpStronger],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
        atWarWith: const [criticalPeaceGpStronger],
        invadableProvinceIdsSorted: const ['oldWorld|${criticalPeaceGpStronger}_1'],
      );
      expect(
        criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'With one GP foe the multi-front precondition does not hold; '
            'the wrapper must short-circuit even when '
            'multiFrontNonBlockerGpPeaceTargets would otherwise emit a '
            'sole-non-blocker peace. The wrapper specifically guards the '
            '"2+ GP fronts under EXPAND pressure" signal.',
      );
    });

    test('returns const [] when only minors/tribes are at war (no GPs)', () {
      final game = buildCriticalExpandPeaceGame(
        ownProvinces: kStalledOldWorldProvinceThreshold,
        minorIds: const [criticalPeaceMinor1],
        tribeIds: const [criticalPeaceTribe1],
        atWarFactionIds: const [criticalPeaceMinor1, criticalPeaceTribe1],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
        atWarWith: const [criticalPeaceMinor1, criticalPeaceTribe1],
      );
      expect(
        criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'After Game.playerById filtering no GPs remain; the GP-count '
            'guard must short-circuit. The minor/tribe peace decisions '
            'are owned by the companion stalled / below-quota collectors.',
      );
    });
  });

  group(
    'criticalMultiFrontGpPeaceTargets — canonical fire path delegates non-blocker selection',
    () {
      test(
        'peaces non-blocker GPs when 2+ GP fronts under EXPAND pressure',
        () {
          // ownOw = stalled threshold; gp_stronger owns the invadable
          // OW frontier (blocker); gp_third and gp_fourth are
          // non-blocker GP wars to drop. multiFrontNonBlockerGpPeaceTargets
          // keeps the blocker and peaces gp_third + gp_fourth sorted.
          const invadable = 'oldWorld|frontier_invadable';
          final game = buildCriticalExpandPeaceGame(
            ownProvinces: kStalledOldWorldProvinceThreshold,
            gpRivalProvincesById: {
              criticalPeaceGpStronger: [invadable],
              criticalPeaceGpThird: criticalPeaceRivalProvinces(
                criticalPeaceGpThird,
                5,
              ),
              criticalPeaceGpFourth: criticalPeaceRivalProvinces(
                criticalPeaceGpFourth,
                5,
              ),
            },
            atWarFactionIds: const [
              criticalPeaceGpStronger,
              criticalPeaceGpThird,
              criticalPeaceGpFourth,
            ],
          );
          final snapshot = ownSnapshot(
            oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
            atWarWith: const [
              criticalPeaceGpFourth,
              criticalPeaceGpStronger,
              criticalPeaceGpThird,
            ],
            invadableProvinceIdsSorted: const [invadable],
          );
          expect(
            criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot),
            const [criticalPeaceGpFourth, criticalPeaceGpThird],
            reason:
                'gp_stronger is the OW frontier blocker (owns the only '
                'invadable OW province) → keep at war. gp_third and '
                'gp_fourth are non-blocker GPs → peaced and sorted '
                'ascending by factionId.',
          );
        },
      );

      test('engages within the at-quota band (ownOw == quota)', () {
        // ownOw = exactly at the observer quota →
        // isAtObserverConquestQuotaBand is true; the outer guard
        // passes via the at-quota arm even though
        // isObserverConquestExpansionPressure is false.
        const invadable = 'oldWorld|frontier_invadable';
        final game = buildCriticalExpandPeaceGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          gpRivalProvincesById: {
            criticalPeaceGpStronger: [invadable],
            criticalPeaceGpThird: criticalPeaceRivalProvinces(
              criticalPeaceGpThird,
              5,
            ),
          },
          atWarFactionIds: const [criticalPeaceGpStronger, criticalPeaceGpThird],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const [criticalPeaceGpStronger, criticalPeaceGpThird],
          invadableProvinceIdsSorted: const [invadable],
        );
        expect(
          criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot),
          const [criticalPeaceGpThird],
          reason:
              'At ownOw == quota the at-quota arm of the outer guard '
              'engages; gp_stronger is the blocker, gp_third is the '
              'non-blocker GP and surfaces.',
        );
      });
    },
  );

  group('criticalMultiFrontGpPeaceTargets — stub delegation parity', () {
    test('stub returns the canonical list for the multi-front fire path', () {
      const invadable = 'oldWorld|frontier_invadable';
      final game = buildCriticalExpandPeaceGame(
        ownProvinces: kStalledOldWorldProvinceThreshold,
        gpRivalProvincesById: {
          criticalPeaceGpStronger: [invadable],
          criticalPeaceGpThird: criticalPeaceRivalProvinces(
            criticalPeaceGpThird,
            5,
          ),
          criticalPeaceGpFourth: criticalPeaceRivalProvinces(
            criticalPeaceGpFourth,
            5,
          ),
        },
        atWarFactionIds: const [
          criticalPeaceGpStronger,
          criticalPeaceGpThird,
          criticalPeaceGpFourth,
        ],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
        atWarWith: const [
          criticalPeaceGpStronger,
          criticalPeaceGpThird,
          criticalPeaceGpFourth,
        ],
        invadableProvinceIdsSorted: const [invadable],
      );
      final canonical = criticalMultiFrontGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final stub = diplomacy_planner_peace_targets
          .criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot);
      expect(
        stub,
        equals(canonical),
        reason:
            'The legacy stub must remain byte-equivalent to the canonical '
            'helper so the in-file _expandRatchetGreatPowerPeaceTargets / '
            'stalledOwExpansionNeedsPeacePass consumer chains continue to '
            'resolve to the same behavior.',
      );
    });

    test('stub returns const [] when the outer guard fires (above-quota)', () {
      final game = buildCriticalExpandPeaceGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp + 2,
        gpRivalProvincesById: {
          criticalPeaceGpStronger: criticalPeaceRivalProvinces(
            criticalPeaceGpStronger,
            5,
          ),
          criticalPeaceGpThird: criticalPeaceRivalProvinces(
            criticalPeaceGpThird,
            5,
          ),
        },
        atWarFactionIds: const [criticalPeaceGpStronger, criticalPeaceGpThird],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [criticalPeaceGpStronger, criticalPeaceGpThird],
      );
      final canonical = criticalMultiFrontGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final stub = diplomacy_planner_peace_targets
          .criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot);
      expect(canonical, isEmpty);
      expect(stub, isEmpty);
    });
  });

  group('criticalMultiFrontGpPeaceTargets — determinism', () {
    test(
      'two consecutive invocations return identical lists (Must-have #7)',
      () {
        const invadable = 'oldWorld|frontier_invadable';
        final game = buildCriticalExpandPeaceGame(
          ownProvinces: kStalledOldWorldProvinceThreshold,
          gpRivalProvincesById: {
            criticalPeaceGpStronger: [invadable],
            criticalPeaceGpThird: criticalPeaceRivalProvinces(
              criticalPeaceGpThird,
              5,
            ),
            criticalPeaceGpFourth: criticalPeaceRivalProvinces(
              criticalPeaceGpFourth,
              5,
            ),
          },
          atWarFactionIds: const [
            criticalPeaceGpStronger,
            criticalPeaceGpThird,
            criticalPeaceGpFourth,
          ],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold,
          atWarWith: const [
            criticalPeaceGpFourth,
            criticalPeaceGpStronger,
            criticalPeaceGpThird,
          ],
          invadableProvinceIdsSorted: const [invadable],
        );
        final first = criticalMultiFrontGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = criticalMultiFrontGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(first, equals(second));
        expect(first, const [criticalPeaceGpFourth, criticalPeaceGpThird]);
      },
    );
  });
}
