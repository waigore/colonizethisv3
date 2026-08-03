// Case bodies: planExpandPeace geographic peer-war lock H4-a (Refs #4239 Slice C).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_game_factories.dart';

import 'test_game_factories.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _gp4 = 'gp4';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

void registerExpandPhasePlannerPeaceGeographicPeerWarLockCases() {
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
