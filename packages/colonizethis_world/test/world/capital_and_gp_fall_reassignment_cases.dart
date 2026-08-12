import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';

import '../world_test_support/world_test_support.dart';

/// Outcome / throw case rows for capital reassignment densify (Refs #4330).
typedef CapitalReassignmentOutcomeCase = ({
  String description,
  Game game,
  void Function(Game result) verify,
});

typedef CapitalReassignmentThrowCase = ({String description, Game game});

/// Great-Power outcome pins for [applyCapitalReassignmentAfterCombat].
final List<CapitalReassignmentOutcomeCase> gpCapitalReassignmentOutcomeCases = [
  (
    description: 'reassigns capital to remaining owned province after loss',
    game: gpCapitalReassignmentGame(
      provinces: const [
        Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p2'),
        Province(
          id: 'oldWorld|alt',
          regionId: 'oldWorld',
          ownerId: 'p1',
          townTileKey: 'oldWorld|alt|3|4',
        ),
      ],
    ),
    verify: (result) {
      final p1 = result.players.firstWhere((p) => p.id == 'p1');
      expect(p1.capitalProvinceId, 'oldWorld|alt');
      expect(p1.capitalTile?.x, 3);
      expect(p1.capitalTile?.y, 4);
      expect(
        result.worldState.tryGetProvince('oldWorld|alt')?.townDevelopmentLevel,
        4,
      );
    },
  ),
  (
    description: 'clears capital when no owned provinces remain in region',
    game: gpCapitalReassignmentGame(
      provinces: const [
        Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p2'),
      ],
    ),
    verify: (result) => expect(result.players.single.id, 'p1'),
  ),
  (
    description: 'leaves capital untouched when player still owns it',
    game: gpCapitalReassignmentGame(
      provinces: const [
        Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p1'),
      ],
    ),
    verify: (result) =>
        expect(result.players.single.capitalProvinceId, 'oldWorld|cap'),
  ),
  (
    description: 'skips players without a capital',
    game: capitalLossGame(
      id: 'g-no-cap',
      players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
    ),
    verify: (result) => expect(result.players.single.capitalProvinceId, isNull),
  ),
];

/// Great-Power throw pins for [applyCapitalReassignmentAfterCombat].
final List<CapitalReassignmentThrowCase> gpCapitalReassignmentThrowCases = [
  (
    description:
        'throws fatal error when candidate province has no townTileKey',
    game: gpCapitalReassignmentGame(
      provinces: const [
        Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p2'),
        Province(id: 'oldWorld|alt', regionId: 'oldWorld', ownerId: 'p1'),
      ],
    ),
  ),
  (
    description: 'throws fatal error when candidate townTileKey is malformed',
    game: gpCapitalReassignmentGame(
      provinces: const [
        Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p2'),
        Province(
          id: 'oldWorld|alt',
          regionId: 'oldWorld',
          ownerId: 'p1',
          townTileKey: 'not-a-valid-key',
        ),
      ],
    ),
  ),
];

/// Minor/tribe outcome pins for [applyFactionCapitalReassignmentAfterCombat].
final List<CapitalReassignmentOutcomeCase>
factionCapitalReassignmentOutcomeCases = [
  (
    description: 'reassigns minor nation capital after loss',
    game: factionCapitalReassignmentGame(
      id: 'g-minor',
      oldWorldProvinces: const [
        Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'p2'),
        Province(
          id: 'oldWorld|malt',
          regionId: 'oldWorld',
          ownerId: 'm1',
          townTileKey: 'oldWorld|malt|5|6',
        ),
      ],
      players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
      minorNations: [
        MinorNation(
          id: 'm1',
          capitalProvinceId: 'oldWorld|mcap',
          capitalTile: capitalTileFor('oldWorld|mcap'),
        ),
      ],
    ),
    verify: (result) {
      final m1 = result.minorNations.single;
      expect(m1.capitalProvinceId, 'oldWorld|malt');
      expect(m1.capitalTile?.x, 5);
    },
  ),
  (
    description: 'clears minor nation capital when none remain in region',
    game: factionCapitalReassignmentGame(
      id: 'g-minor-clear',
      oldWorldProvinces: const [
        Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'p2'),
      ],
      players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
      minorNations: [
        MinorNation(
          id: 'm1',
          capitalProvinceId: 'oldWorld|mcap',
          capitalTile: capitalTileFor('oldWorld|mcap'),
        ),
      ],
    ),
    verify: (result) =>
        expect(result.minorNations.single.capitalProvinceId, isNull),
  ),
  (
    description: 'reassigns tribe capital after loss',
    game: factionCapitalReassignmentGame(
      id: 'g-tribe',
      newWorldProvinces: const [
        Province(id: 'newWorld|tcap', regionId: 'newWorld', ownerId: 'p2'),
        Province(
          id: 'newWorld|talt',
          regionId: 'newWorld',
          ownerId: 't1',
          townTileKey: 'newWorld|talt|7|8',
        ),
      ],
      players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
      tribes: [
        Tribe(
          id: 't1',
          capitalProvinceId: 'newWorld|tcap',
          capitalTile: capitalTileFor('newWorld|tcap'),
        ),
      ],
    ),
    verify: (result) =>
        expect(result.tribes.single.capitalProvinceId, 'newWorld|talt'),
  ),
  (
    description: 'clears tribe capital when none remain in region',
    game: factionCapitalReassignmentGame(
      id: 'g-tribe-clear',
      newWorldProvinces: const [
        Province(id: 'newWorld|tcap', regionId: 'newWorld', ownerId: 'p2'),
      ],
      players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
      tribes: [
        Tribe(
          id: 't1',
          capitalProvinceId: 'newWorld|tcap',
          capitalTile: capitalTileFor('newWorld|tcap'),
        ),
      ],
    ),
    verify: (result) => expect(result.tribes.single.capitalProvinceId, isNull),
  ),
];

/// Minor/tribe throw pins for [applyFactionCapitalReassignmentAfterCombat].
final List<CapitalReassignmentThrowCase>
factionCapitalReassignmentThrowCases = [
  (
    description: 'throws fatal error when minor candidate lacks townTileKey',
    game: factionCapitalReassignmentGame(
      id: 'g-minor-throw',
      oldWorldProvinces: const [
        Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'p2'),
        Province(id: 'oldWorld|malt', regionId: 'oldWorld', ownerId: 'm1'),
      ],
      players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
      minorNations: [
        MinorNation(
          id: 'm1',
          capitalProvinceId: 'oldWorld|mcap',
          capitalTile: capitalTileFor('oldWorld|mcap'),
        ),
      ],
    ),
  ),
  (
    description: 'throws fatal error when tribe candidate lacks townTileKey',
    game: factionCapitalReassignmentGame(
      id: 'g-tribe-throw',
      newWorldProvinces: const [
        Province(id: 'newWorld|tcap', regionId: 'newWorld', ownerId: 'p2'),
        Province(id: 'newWorld|talt', regionId: 'newWorld', ownerId: 't1'),
      ],
      players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
      tribes: [
        Tribe(
          id: 't1',
          capitalProvinceId: 'newWorld|tcap',
          capitalTile: capitalTileFor('newWorld|tcap'),
        ),
      ],
    ),
  ),
];
