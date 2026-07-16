import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/world_test_support.dart';

void main() {
  _capital_and_gp_fall_reassignment_testTests();
}

void _capital_and_gp_fall_reassignment_testTests() {
  group('applyCapitalReassignmentAfterCombat (Great Power)', () {
    test('reassigns capital to remaining owned province after loss', () {
      final game = gpCapitalReassignmentGame(
        provinces: const [
          Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p2'),
          Province(
            id: 'oldWorld|alt',
            regionId: 'oldWorld',
            ownerId: 'p1',
            townTileKey: 'oldWorld|alt|3|4',
          ),
        ],
      );

      final result = applyCapitalReassignmentAfterCombat(
        game,
        kEmptyMapTopology,
      );

      final p1 = result.players.firstWhere((p) => p.id == 'p1');
      expect(p1.capitalProvinceId, 'oldWorld|alt');
      expect(p1.capitalTile?.x, 3);
      expect(p1.capitalTile?.y, 4);
      final alt = result.worldState.tryGetProvince('oldWorld|alt');
      expect(alt?.townDevelopmentLevel, 4);
    });

    test('clears capital when no owned provinces remain in region', () {
      final game = gpCapitalReassignmentGame(
        provinces: const [
          Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p2'),
        ],
      );

      final result = applyCapitalReassignmentAfterCombat(
        game,
        kEmptyMapTopology,
      );

      expect(result.players.single.id, 'p1');
    });

    test('leaves capital untouched when player still owns it', () {
      final game = gpCapitalReassignmentGame(
        provinces: const [
          Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p1'),
        ],
      );

      final result = applyCapitalReassignmentAfterCombat(
        game,
        kEmptyMapTopology,
      );

      expect(result.players.single.capitalProvinceId, 'oldWorld|cap');
    });

    test('skips players without a capital', () {
      final game = capitalLossGame(
        id: 'g-no-cap',
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final result = applyCapitalReassignmentAfterCombat(
        game,
        kEmptyMapTopology,
      );

      expect(result.players.single.capitalProvinceId, isNull);
    });

    test('throws fatal error when candidate province has no townTileKey', () {
      final game = gpCapitalReassignmentGame(
        provinces: const [
          Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p2'),
          Province(id: 'oldWorld|alt', regionId: 'oldWorld', ownerId: 'p1'),
        ],
      );

      expect(
        () => applyCapitalReassignmentAfterCombat(game, kEmptyMapTopology),
        throwsA(isA<CapitalReassignmentFatalError>()),
      );
    });

    test('throws fatal error when candidate townTileKey is malformed', () {
      final game = gpCapitalReassignmentGame(
        provinces: const [
          Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p2'),
          Province(
            id: 'oldWorld|alt',
            regionId: 'oldWorld',
            ownerId: 'p1',
            townTileKey: 'not-a-valid-key',
          ),
        ],
      );

      expect(
        () => applyCapitalReassignmentAfterCombat(game, kEmptyMapTopology),
        throwsA(isA<CapitalReassignmentFatalError>()),
      );
    });
  });

  group('applyFactionCapitalReassignmentAfterCombat (Minor/Tribe)', () {
    for (final case_ in _minorTribeReassignOrClearCases) {
      test(case_.description, () {
        final result = applyFactionCapitalReassignmentAfterCombat(
          case_.game,
          kEmptyMapTopology,
        );
        case_.verify(result);
      });
    }

    for (final case_ in _minorTribeThrowCases) {
      test(case_.description, () {
        expect(
          () => applyFactionCapitalReassignmentAfterCombat(
            case_.game,
            kEmptyMapTopology,
          ),
          throwsA(isA<CapitalReassignmentFatalError>()),
        );
      });
    }

    test('leaves minor capital untouched when minor still owns it', () {
      final game = factionCapitalReassignmentGame(
        id: 'g-minor-owns',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'm1'),
        ],
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        minorNations: [
          MinorNation(
            id: 'm1',
            capitalProvinceId: 'oldWorld|mcap',
            capitalTile: capitalTileFor('oldWorld|mcap'),
          ),
        ],
      );

      final result = applyFactionCapitalReassignmentAfterCombat(
        game,
        kEmptyMapTopology,
      );

      expect(result.minorNations.single.capitalProvinceId, 'oldWorld|mcap');
    });

    test('reassigns both minor and tribe in a single pass', () {
      final game = factionCapitalReassignmentGame(
        id: 'g-minor-and-tribe',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'p2'),
          Province(
            id: 'oldWorld|malt',
            regionId: 'oldWorld',
            ownerId: 'm1',
            townTileKey: 'oldWorld|malt|5|6',
          ),
        ],
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
        minorNations: [
          MinorNation(
            id: 'm1',
            capitalProvinceId: 'oldWorld|mcap',
            capitalTile: capitalTileFor('oldWorld|mcap'),
          ),
        ],
        tribes: [
          Tribe(
            id: 't1',
            capitalProvinceId: 'newWorld|tcap',
            capitalTile: capitalTileFor('newWorld|tcap'),
          ),
        ],
      );

      final result = applyFactionCapitalReassignmentAfterCombat(
        game,
        kEmptyMapTopology,
      );

      expect(result.minorNations.single.capitalProvinceId, 'oldWorld|malt');
      expect(result.tribes.single.capitalProvinceId, 'newWorld|talt');
    });
  });
}

typedef _FactionCapitalOutcomeCase = ({
  String description,
  Game game,
  void Function(Game result) verify,
});

typedef _FactionCapitalThrowCase = ({
  String description,
  Game game,
});

final List<_FactionCapitalOutcomeCase> _minorTribeReassignOrClearCases = [
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
    verify: (result) {
      expect(result.minorNations.single.capitalProvinceId, isNull);
    },
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
    verify: (result) {
      expect(result.tribes.single.capitalProvinceId, 'newWorld|talt');
    },
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
    verify: (result) {
      expect(result.tribes.single.capitalProvinceId, isNull);
    },
  ),
];

final List<_FactionCapitalThrowCase> _minorTribeThrowCases = [
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

