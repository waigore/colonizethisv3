// Unit tests for `planExpandPeace` and the Refs #2847 § H4-a geographic
// peer-war lock carve-out in `expand_phase_planner.dart` (Refs #2509 S2 / S10).
//
// Predicate-level pins for `expandIsGeographicPeerWarLock` and
// `expandRecentlyPeacedWithGreatPower` live in
// `expand_phase_planner_peace_predicates_test.dart`.

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

void main() {
  group('planExpandPeace', () {
    test('empty atWarWith -> empty', () {
      // No live wars -> the GP filter loop body never runs and the
      // function short-circuits before the blocker scan. A regression
      // that always emitted the at-peace GP roster would emit
      // `offerPeace` toward neutral powers and break the "peace ALL
      // at-war GPs" wording (we have nothing to peace).
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
      );
      final snapshot = buildExpandSnapshot(atWarWith: const []);
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'No GPs are at war so the planner has no peace targets to '
            'emit; the blocker scan should not run at all.',
      );
    });

    test('only tribes/minors in atWarWith -> empty', () {
      // EXPAND peace contract is GP-only: minor / tribe wars are pursued
      // through other diplomacy paths. The `game.playerById` filter
      // drops every non-GP id, so even with a tribe and a minor in
      // `atWarWith` the planner returns empty. A regression that left
      // non-GP ids in the output would emit `offerPeace` toward non-GP
      // factions and fail downstream order validation.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(atWarWith: const [_tribe1, _minor1]);
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Non-GP factions are filtered out via `game.playerById`. '
            'With only non-GP wars present the planner must return empty.',
      );
    });

    test('multi-GP, no invadable OW -> peace ALL GPs sorted ascending', () {
      // No invadable OW means the blocker scan returns null -> the
      // "no exception applies" arm. Every at-war GP must be peaced
      // (sorted ascending). Input order shuffled to `[gp3, gp2]` so a
      // regression that dropped the trailing `..sort()` would surface
      // here.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp3, _gp2],
        invadableOw: const [],
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        const [_gp2, _gp3],
        reason:
            'Null blocker -> "Peace ALL at-war Great Powers" with no '
            'exception. Returned list is ascending-sorted regardless of '
            'input order (Refs #2509 Must-have #7).',
      );
    });

    test('multi-GP, blocker is a non-at-war GP -> peace ALL gpWars', () {
      // Blocker = gp4 (owns invadable OW), but gp4 is NOT in `atWarWith`.
      // The `!gpWars.contains(blocker)` guard skips the blocker-exclusion
      // branch, so all live war fronts (gp2, gp3) must be peaced. A
      // regression that filtered by blocker without the membership guard
      // would silently leave a non-blocker war open.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp4_a', regionId: 'oldWorld', ownerId: _gp4),
          Province(id: 'oldWorld|gp4_b', regionId: 'oldWorld', ownerId: _gp4),
        ],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableOw: const ['oldWorld|gp4_a', 'oldWorld|gp4_b'],
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        const [_gp2, _gp3],
        reason:
            'Blocker is gp4 (owns the invadable OW) but gp4 is not in '
            '`gpWars` -- peace ALL live war fronts (the membership guard '
            'forces fall-through to the "peace all" arm).',
      );
    });

    test('multi-GP, blocker among gpWars -> peace all except blocker', () {
      // Canonical EXPAND happy path: gp2 owns the invadable OW (blocker),
      // gp3 + gp4 are non-blocker fronts -> peace gp3 and gp4 sorted
      // ascending; keep fighting gp2.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          Province(id: 'oldWorld|gp2_b', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2, _gp3, _gp4],
        invadableOw: const ['oldWorld|gp2_a', 'oldWorld|gp2_b'],
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        const [_gp3, _gp4],
        reason:
            'Blocker gp2 is preserved (keep fighting); non-blocker GPs '
            'gp3 + gp4 are peaced in ascending sort.',
      );
    });

    test('3 GPs at war (input order shuffled) -> ascending sort', () {
      // Determinism pin (Must-have #7). Three GP fronts (gp4, gp3, gp2)
      // with gp2 as blocker -> peace gp3 + gp4 in ascending order
      // regardless of input order.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
        ],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp4, _gp3, _gp2],
        invadableOw: const ['oldWorld|gp2_a'],
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        const [_gp3, _gp4],
        reason:
            'Trailing `..sort()` restores ascending order regardless of '
            'input order. A regression that returned input-order would '
            'surface here as `[gp4, gp3]`.',
      );
    });

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

  // Refs #2847 § H4-a geographic peer-war lock carve-out: peace the sole
  // at-war Great Power foe even when uninvaded OW minors remain, provided
  // those minors are not adjacent to the active player's territory and
  // the foe is the sole adjacent OW owner. Pins the new arm and its
  // bounding conditions so a future regression can be diagnosed by name.
  group('planExpandPeace geographic peer-war lock (Refs #2847 H4-a)', () {
    test('sole peer GP is only adjacent OW owner, mutual-plateau, minors '
        'remain on map but not adjacent -> peace the lone GP', () {
      // Seed-42 turn-99 shape for gp3: own=gp1, blocker=peer gp2, both at
      // 8 OW (mutual-plateau below quota of 10). minor1 owns an OW
      // province somewhere on the map (`hasUninvadedOldWorldMinor` is
      // true) but minor1 does NOT own any province adjacent to gp1, so
      // `adjacentOwnerFactionIdsSorted == [gp2]`. Without the H4-a arm
      // the legacy `!hasUninvadedOldWorldMinor` gate blocks peace and
      // the default arm returns empty; the new arm must fire and peace
      // gp2 so the lock can break.
      final owProvinces = <Province>[
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp1_$i', regionId: 'oldWorld', ownerId: _gp1),
        for (var i = 0; i < 8; i++)
          Province(id: 'oldWorld|gp2_$i', regionId: 'oldWorld', ownerId: _gp2),
        const Province(
          id: 'oldWorld|m1_far',
          regionId: 'oldWorld',
          ownerId: _minor1,
        ),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        oldWorldProvinces: owProvinces,
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2],
        invadableOw: const ['oldWorld|gp2_0'],
        // adjacency collapses to the sole at-war peer GP — minor1's
        // distant tile is on the map but unreachable from gp1's anchors.
        adjacentOwners: const [_gp2],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        const [_gp2],
        reason:
            'Geographic peer-war lock: gp2 is the sole at-war GP foe '
            'AND the only OW adjacent owner. Mutual-plateau holds. '
            'Even though minor1 still owns OW provinces somewhere '
            '(`hasUninvadedOldWorldMinor` is true), minor1 is not '
            'adjacent so the minor pivot is unreachable -> peace gp2 '
            '(Refs #2847 § H4-a).',
      );
    });

    test('sole peer GP is only adjacent OW owner, mutual-plateau, no minors '
        'on the map -> peace the lone GP (both arms agree)', () {
      // The original mutual-plateau carve-out and the new H4-a arm both
      // qualify here. Pinning the overlapping case guards against a
      // regression where the new arm shadows the legacy arm to the
      // wrong outcome.
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
        adjacentOwners: const [_gp2],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        const [_gp2],
        reason:
            'Overlapping carve-out case: both the legacy '
            '(`gpOnlyFrontier && !hasUninvadedOldWorldMinor`) arm and '
            'the new H4-a (`adjacentOwners == [blocker]`) arm fire. '
            'Output must still be `[gp2]` (peace the lone blocker).',
      );
    });

    test('sole peer GP is adjacent OW owner BUT a minor is also adjacent '
        '-> empty (H4-a does not fire; minor pivot remains reachable)', () {
      // adjacentOwnerFactionIdsSorted == [_gp2, _minor1] -> the active
      // player has another OW neighbor. Even if gp2 is the at-war
      // blocker, the minor is reachable and may still hold a pivot
      // path. The new H4-a arm must NOT fire (adjacency length != 1).
      // The legacy arm also must NOT fire (the minor-owned tile in
      // the invadable list breaks `gpOnlyFrontier`). Default arm
      // returns empty (keep fighting the lone blocker).
      final owProvinces = <Province>[
        Province(id: 'oldWorld|gp2_0', regionId: 'oldWorld', ownerId: _gp2),
        Province(id: 'oldWorld|m1_adj', regionId: 'oldWorld', ownerId: _minor1),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        oldWorldProvinces: owProvinces,
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2],
        invadableOw: const ['oldWorld|gp2_0', 'oldWorld|m1_adj'],
        adjacentOwners: const [_gp2, _minor1],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'adjacentOwnerFactionIdsSorted has 2 entries (gp2 + minor1) '
            '-> H4-a arm rejects (length != 1). Minor1 is reachable so '
            'the lock is not "geographic peer-war"; default arm keeps '
            'fighting the lone blocker.',
      );
    });

    test('sole peer GP is adjacent OW owner but partner at quota '
        '-> empty (no mutual-plateau, both carve-outs rejected)', () {
      // partnerOw = 10 (at quota). mutualPlateau guard rejects -> the
      // H4-a arm must not fire even with the geographic lock signal
      // present. Default arm returns empty (keep fighting the lone
      // blocker; the partner is winning).
      final owProvinces = <Province>[
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
        adjacentOwners: const [_gp2],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Partner GP at quota (10) -> isMutualBelowQuotaPlateauPeer '
            'is false; the H4-a arm requires the mutual-plateau guard '
            'so it does not fire. Default arm keeps fighting the lone '
            'blocker.',
      );
    });

    test('sole peer GP is adjacent OW owner, mutual-plateau, but two GP '
        'wars -> default "peace all except blocker" arm fires', () {
      // gpWars.length == 2 (gp2 + gp3). The H4-a arm requires
      // gpWars.length == 1 so it does not fire even with the
      // geographic-lock signal in `adjacentOwners`. The default arm
      // peaces gp3 (non-blocker) and keeps fighting gp2 (the blocker).
      final owProvinces = <Province>[
        Province(id: 'oldWorld|gp2_0', regionId: 'oldWorld', ownerId: _gp2),
      ];
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-peace',
        defaultFourGpPlayers: true,
        oldWorldProvinces: owProvinces,
      );
      final snapshot = buildExpandSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableOw: const ['oldWorld|gp2_0'],
        adjacentOwners: const [_gp2],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        const [_gp3],
        reason:
            'Two GPs at war -> H4-a arm rejects (gpWars.length != 1). '
            'Default arm peaces the non-blocker (gp3); keep fighting '
            'the blocker (gp2).',
      );
    });

    test('adjacency is empty -> H4-a does not fire (legacy carve-out path '
        'is the only one that may still match)', () {
      // adjacentOwnerFactionIdsSorted == []. Mutual-plateau holds (both
      // sides at 8 OW), `gpOnlyFrontier` holds, and no minors are on
      // the map -> the legacy mutual-plateau carve-out fires. The H4-a
      // arm must NOT fire (length != 1). This pin guards against a
      // regression where the H4-a arm accidentally accepts the
      // empty-adjacency case (which would still emit `[gp2]` here, but
      // by the wrong path). Final output is `[gp2]`, but the carve-out
      // attribution belongs to the legacy arm. The
      // [expandIsGeographicPeerWarLock] predicate-level test below
      // covers the H4-a rejection signal independently.
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
        adjacentOwners: const [],
        oldWorldProvincesOwned: 8,
      );
      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        const [_gp2],
        reason:
            'Empty adjacency -> H4-a arm cannot fire (length != 1). '
            'Legacy arm still applies (no minors on map; GP-only '
            'invadable frontier) so the lone blocker is peaced via '
            'the legacy carve-out. The expandIsGeographicPeerWarLock '
            'predicate-level test pins the H4-a-only rejection signal '
            'separately.',
      );
    });
  });
}
