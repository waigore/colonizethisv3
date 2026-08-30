// Topic-split cases from `expand_phase_planner_focus_minor_target_early_cases` (Refs #4669 Slice B).
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import '../support/expand_phase_planner_focus_minor_target_test_support.dart';

void registerExpandPhasePlannerFocusMinorTargetEarlyFireCases() {
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
        atWarWith: const [
          kFocusMinorMinorAlpha,
          kFocusMinorTribeOne,
          kFocusMinorGpRival,
        ],
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

}
