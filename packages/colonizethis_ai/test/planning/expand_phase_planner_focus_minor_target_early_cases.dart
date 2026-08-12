// Case bodies for expand_phase_planner_focus_minor_target_test (Refs #3997 Phase 8).
// Pins canonical homes for stalledFocusMinorTarget /
// belowQuotaActiveMinorWarTarget (Refs #2509 S1).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import '../support/expand_phase_planner_focus_minor_target_test_support.dart';

void registerExpandPhasePlannerFocusMinorTargetEarlyCases() {
  group('stalledFocusMinorTarget — canonical outer guards', () {
    test('returns null when no minor is at war', () {
      // Only a tribe and a rival GP are at war; the
      // Game.minorNations / RelationState.atWar filter rejects every
      // minor candidate before the invadable scan runs.
      final game = expandPhasePlannerFocusMinorTargetGame(
        ownProvinces: 7,
        minorOwnedInvadables: const {
          kFocusMinorMinorAlpha: ['oldWorld|alpha_1'],
        },
        peacefulMinors: const [kFocusMinorMinorAlpha],
        atWarTribes: const [kFocusMinorTribeOne],
        atWarRivalGps: const [kFocusMinorGpRival],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [kFocusMinorTribeOne, kFocusMinorGpRival],
        invadableProvinceIdsSorted: const ['oldWorld|alpha_1'],
      );
      expect(
        stalledFocusMinorTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'No at-war minor → the at-war filter rejects every '
            'Game.minorNations candidate before the invadable scan; '
            'tribes do not participate even though tribe_one owns '
            'an invadable province in a sibling fixture.',
      );
    });

    test(
      'returns null when at-war minors exist but own no invadable OW provinces',
      () {
        // Both minors are at war but own only non-invadable OW
        // provinces; the bestInvadableCount stays at 0 so the helper
        // returns null without picking an arbitrary minor.
        final game = expandPhasePlannerFocusMinorTargetGame(
          ownProvinces: 7,
          minorOwnedInvadables: const {
            kFocusMinorMinorAlpha: ['oldWorld|alpha_home'],
            kFocusMinorMinorBeta: ['oldWorld|beta_home'],
          },
          atWarMinors: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
          // None of the at-war minors' provinces appear in the
          // invadable frontier.
          invadableProvinceIdsSorted: const [],
        );
        expect(
          stalledFocusMinorTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              'Empty invadableProvinceIdsSorted → every minor scores '
              '0 → the strict-greater comparison never updates; '
              'returning null preserves the "no focused front" '
              'contract instead of arbitrarily picking one minor.',
        );
      },
    );
  });

  group('stalledFocusMinorTarget — fire path', () {
    test('returns the at-war minor with the most invadable OW provinces', () {
      // minor_alpha owns 1 invadable; minor_beta owns 2 invadables —
      // beta wins on the strict-greater comparison.
      final game = expandPhasePlannerFocusMinorTargetGame(
        ownProvinces: 7,
        minorOwnedInvadables: const {
          kFocusMinorMinorAlpha: ['oldWorld|alpha_1'],
          kFocusMinorMinorBeta: ['oldWorld|beta_1', 'oldWorld|beta_2'],
        },
        atWarMinors: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [kFocusMinorMinorAlpha, kFocusMinorMinorBeta],
        invadableProvinceIdsSorted: const [
          'oldWorld|alpha_1',
          'oldWorld|beta_1',
          'oldWorld|beta_2',
        ],
      );
      expect(
        stalledFocusMinorTarget(game: game, snapshot: snapshot),
        kFocusMinorMinorBeta,
        reason:
            'minor_beta owns 2 invadable provinces → strict-greater '
            'comparison vs minor_alpha (1) selects beta as the '
            'focused single-front minor.',
      );
    });

    test('preserves Game.minorNations iteration order on count ties', () {
      // minor_alpha and minor_gamma each own 1 invadable. Only
      // strict-greater updates win, so the first iterated minor to
      // reach bestInvadableCount keeps the lead. Game.minorNations
      // iterates in construction order (alpha registered before
      // gamma) → alpha wins.
      final game = expandPhasePlannerFocusMinorTargetGame(
        ownProvinces: 7,
        minorOwnedInvadables: const {
          kFocusMinorMinorAlpha: ['oldWorld|alpha_1'],
          kFocusMinorMinorGamma: ['oldWorld|gamma_1'],
        },
        atWarMinors: const [kFocusMinorMinorAlpha, kFocusMinorMinorGamma],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [kFocusMinorMinorGamma, kFocusMinorMinorAlpha],
        invadableProvinceIdsSorted: const [
          'oldWorld|alpha_1',
          'oldWorld|gamma_1',
        ],
      );
      expect(
        stalledFocusMinorTarget(game: game, snapshot: snapshot),
        kFocusMinorMinorAlpha,
        reason:
            'Tie at 1 invadable each → only the first iterated minor '
            'updates bestInvadableCount; later minors with equal '
            'counts cannot displace it (strict-greater). This pins '
            'the deterministic-order contract for Must-have #7.',
      );
    });

    test('ignores tribes and rival GPs holding invadable provinces', () {
      // tribe_one and gp_rival each own an invadable OW province but
      // neither participates in the focused-minor scan (the loop
      // iterates Game.minorNations only). minor_alpha — the only
      // at-war minor with an invadable — must win.
      final game = expandPhasePlannerFocusMinorTargetGame(
        ownProvinces: 7,
        minorOwnedInvadables: const {
          kFocusMinorMinorAlpha: ['oldWorld|alpha_1'],
        },
        atWarMinors: const [kFocusMinorMinorAlpha],
        atWarTribes: const [kFocusMinorTribeOne],
        atWarRivalGps: const [kFocusMinorGpRival],
      );
      // Tribe and GP owned invadables on the same frontier (added
      // out-of-band so the snapshot exposes them but minor_alpha
      // still wins the focused-minor scan).
      final gameWithTribeAndGpInvadables = Game(
        id: game.id,
        worldState: WorldState(
          turnState: game.worldState.turnState,
          oldWorld: RegionData(
            provinces: <Province>[
              ...game.worldState.oldWorld.provinces,
              const Province(
                id: 'oldWorld|tribe_invadable_1',
                regionId: 'oldWorld',
                ownerId: kFocusMinorTribeOne,
              ),
              const Province(
                id: 'oldWorld|gp_rival_invadable_1',
                regionId: 'oldWorld',
                ownerId: kFocusMinorGpRival,
              ),
            ],
          ),
          newWorld: game.worldState.newWorld,
        ),
        players: game.players,
        minorNations: game.minorNations,
        tribes: game.tribes,
        diplomacyRelations: game.diplomacyRelations,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 7,
        atWarWith: const [kFocusMinorMinorAlpha, kFocusMinorTribeOne, kFocusMinorGpRival],
        invadableProvinceIdsSorted: const [
          'oldWorld|alpha_1',
          'oldWorld|tribe_invadable_1',
          'oldWorld|gp_rival_invadable_1',
        ],
      );
      expect(
        stalledFocusMinorTarget(
          game: gameWithTribeAndGpInvadables,
          snapshot: snapshot,
        ),
        kFocusMinorMinorAlpha,
        reason:
            'The focused-minor scan iterates Game.minorNations only; '
            'tribe_one and gp_rival are never considered even when '
            'they own invadable provinces. minor_alpha (the only '
            'at-war minor with an invadable) wins.',
      );
    });
  });

  group('belowQuotaActiveMinorWarTarget — canonical outer guard', () {
    test(
      'returns null at quota even when a focused minor would fire below',
      () {
        // ownOw == quota → isBelowObserverConquestQuota is false →
        // outer guard fires before the inner stalledFocusMinorTarget
        // delegation. Even with minor_alpha clearly leading the
        // invadable count, the helper returns null at quota.
        final game = expandPhasePlannerFocusMinorTargetGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          minorOwnedInvadables: const {
            kFocusMinorMinorAlpha: ['oldWorld|alpha_1', 'oldWorld|alpha_2'],
          },
          atWarMinors: const [kFocusMinorMinorAlpha],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const [kFocusMinorMinorAlpha],
          invadableProvinceIdsSorted: const [
            'oldWorld|alpha_1',
            'oldWorld|alpha_2',
          ],
        );
        expect(
          belowQuotaActiveMinorWarTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              'At quota the quota-met / consolidate deciders own '
              'minor-front decisions. A regression that flipped the '
              'guard from `<` to `<=` would silently engage the '
              'helper at quota and force-hold a minor war the '
              'consolidate arm intended to peace.',
        );
        // Sanity-pin the same input through the canonical inner
        // helper to confirm the outer guard is the only difference
        // (would have returned minor_alpha otherwise).
        expect(
          stalledFocusMinorTarget(game: game, snapshot: snapshot),
          kFocusMinorMinorAlpha,
          reason:
              'Without the below-quota guard the focused-minor scan '
              'would pick minor_alpha; the outer guard is the only '
              'reason belowQuotaActiveMinorWarTarget returns null.',
        );
      },
    );
  });

}
