// Topic-split case module (Refs #4602 Slice B).

// Case bodies: planExpandPeace core pins (Refs #4239 Slice C).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_game_factories.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _gp4 = 'gp4';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

void registerExpandPhasePlannerPeaceCoreSoleGpCarveoutCases() {
  group('planExpandPeace', () {
    test('sole GP blocker, mutual-plateau, GP-only frontier, no minors -> '
        'peace the lone GP (carve-out fires)', () {
      // Carve-out happy path: exactly one GP at war, that GP is the
      // blocker, both sides are in the stalled below-quota plateau
      // band (own=8, partner=8 -- both <=9 and within 1), the
      // invadable OW frontier is held only by GPs (no minor owner of
      // an invadable province), and no uninvaded OW minors remain on
      // the map. Per the spec, peace the lone GP "to exit stalemate".
      //
      // World state setup: gp2 owns 8 OW provinces (one is invadable),
      // total OW = 16 (gp1 + gp2 only) so no minor in OW. No minors
      // in the roster either.
      final owProvinces = <Province>[
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp2_$i', regionId: 'oldWorld', ownerId: _gp2),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        oldWorldProvinces: owProvinces,
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2],
        invadableOw: const ['oldWorld|gp2_0'],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        const [_gp2],
        reason:
            'Sole GP blocker mutual-plateau carve-out: own=8, partner=8, '
            'GP-only invadable frontier, no minors -- peace the lone '
            'blocker so the GP can exit the stalemate (Refs #2509 spec '
            '"peace to exit stalemate").',
      );
    });

    test('sole GP blocker, mutual-plateau, GP-only frontier, minors remain '
        '-> empty (carve-out blocked by minor pivot)', () {
      // Minor pivot still available -> the carve-out must NOT fire
      // (we should hold the GP war while expanding against minors).
      // Minor mounted on the map but NOT in `atWarWith` (uninvaded).
      final owProvinces = <Province>[
        Province(id: 'oldWorld|gp1_0', regionId: 'oldWorld', ownerId: _gp1),
        Province(id: 'oldWorld|gp2_0', regionId: 'oldWorld', ownerId: _gp2),
        Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        oldWorldProvinces: owProvinces,
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      // Invadable list contains only GP-owned tiles (frontier is
      // GP-only), but a minor is still on the OW map and uninvaded
      // -> `_hasUninvadedOldWorldMinor` is true.
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2],
        invadableOw: const ['oldWorld|gp2_0'],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Uninvaded OW minor remains -> carve-out condition fails, '
            'fall through to the default arm which keeps fighting the '
            'sole GP blocker (returns empty: nothing to peace).',
      );
    });

    test('sole GP blocker, mutual-plateau, but minor owns invadable OW '
        '-> empty (frontier is not GP-only)', () {
      // Frontier mixes a GP-owned and a minor-owned invadable OW
      // province. `_isOldWorldGpOnlyInvadableFrontier` returns false
      // when any minor owns an invadable OW. Carve-out must NOT fire;
      // default arm keeps fighting the lone GP blocker.
      //
      // Plurality scan must still pick gp2 as the blocker (GP-owned
      // invadable count = 1 > 0 GP non-blockers; minor owners are
      // skipped).
      final owProvinces = <Province>[
        Province(id: 'oldWorld|gp2_0', regionId: 'oldWorld', ownerId: _gp2),
        Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        oldWorldProvinces: owProvinces,
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2],
        invadableOw: const ['oldWorld|gp2_0', 'oldWorld|m1_a'],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Minor-owned invadable OW disqualifies the GP-only-frontier '
            'guard -> carve-out cannot fire, default arm keeps fighting '
            'the lone blocker.',
      );
    });

    test('sole GP blocker, NOT mutual-plateau (partner=10, at quota) '
        '-> empty (default arm keeps fighting the lone blocker)', () {
      // partner OW = 10 (at quota) -> `isBelowObserverConquestQuota`
      // false on partner -> mutual-plateau guard fails. The default
      // arm keeps fighting the sole GP blocker so the function
      // returns an empty peace list.
      final owProvinces = <Province>[
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
        for (var i = 0; i < 10; i++)
          Province(id: 'oldWorld|gp2_$i', regionId: 'oldWorld', ownerId: _gp2),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        oldWorldProvinces: owProvinces,
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2],
        invadableOw: const ['oldWorld|gp2_0'],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Partner GP at quota (10) -> `isBelowObserverConquestQuota` '
            'is false on partner -> mutual-plateau check fails. Default '
            'arm: keep fighting the sole blocker; planner emits no '
            'peace targets.',
      );
    });

    test(
      'mixed GP + non-GP atWarWith with blocker -> only GPs minus blocker',
      () {
        // Composite filter pin: tribe / minor ids in `atWarWith` must drop
        // before the blocker filter. With gp2 as blocker, gp3 is the only
        // GP that should be peaced; tribe1 and minor1 are filtered out.
        final game = buildExpandGame(
          gameIdLabel: 'expand-phase-planner-peace',
          defaultFourGpPlayers: true,
          oldWorldProvinces: const [
            Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          ],
          tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = buildExpandSnapshot(
          atWarWith: const [_gp3, _tribe1, _gp2, _minor1],
          invadableOw: const ['oldWorld|gp2_a'],
        );
        expect(
          planExpandPeace(game: game, snapshot: snapshot),
          const [_gp3],
          reason:
              'Non-GP ids dropped by the playerById filter; blocker gp2 '
              'preserved; only gp3 remains in the peace list.',
        );
      },
    );

    test('determinism: identical inputs yield identical lists', () {
      // Pins Must-have #7 (determinism). Mixed-input fixture exercises
      // the GP filter, blocker scan, and the trailing sort, so
      // repeating the call must yield the same list.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          Province(id: 'oldWorld|gp2_b', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp4, _gp3, _gp2],
        invadableOw: const ['oldWorld|gp2_a', 'oldWorld|gp2_b'],
      );
      final first = planExpandPeace(game: game, snapshot: snapshot);
      final second = planExpandPeace(game: game, snapshot: snapshot);
      expect(second, first);
    });
  });
}
