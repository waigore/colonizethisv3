part of 'capital_test.dart';

void _capital_and_gp_fall_reassignment_testTests() {
  group('applyCapitalReassignmentAfterCombat (Great Power)', () {
    test('reassigns capital to remaining owned province after loss', () {
      final game = _gpGame(
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

      final result = applyCapitalReassignmentAfterCombat(game, _emptyTopology);

      final p1 = result.players.firstWhere((p) => p.id == 'p1');
      expect(p1.capitalProvinceId, 'oldWorld|alt');
      expect(p1.capitalTile?.x, 3);
      expect(p1.capitalTile?.y, 4);
      final alt = result.worldState.tryGetProvince('oldWorld|alt');
      expect(alt?.townDevelopmentLevel, 4);
    });

    test('clears capital when no owned provinces remain in region', () {
      final game = _gpGame(
        provinces: const [
          Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p2'),
        ],
      );

      final result = applyCapitalReassignmentAfterCombat(game, _emptyTopology);

      expect(result.players.single.id, 'p1');
    });

    test('leaves capital untouched when player still owns it', () {
      final game = _gpGame(
        provinces: const [
          Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p1'),
        ],
      );

      final result = applyCapitalReassignmentAfterCombat(game, _emptyTopology);

      expect(
        result.players.single.capitalProvinceId,
        'oldWorld|cap',
      );
    });

    test('skips players without a capital', () {
      final game = Game(
        id: 'g-no-cap',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final result = applyCapitalReassignmentAfterCombat(game, _emptyTopology);

      expect(result.players.single.capitalProvinceId, isNull);
    });

    test('throws fatal error when candidate province has no townTileKey', () {
      final game = _gpGame(
        provinces: const [
          Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p2'),
          Province(id: 'oldWorld|alt', regionId: 'oldWorld', ownerId: 'p1'),
        ],
      );

      expect(
        () => applyCapitalReassignmentAfterCombat(game, _emptyTopology),
        throwsA(isA<CapitalReassignmentFatalError>()),
      );
    });

    test('throws fatal error when candidate townTileKey is malformed', () {
      final game = _gpGame(
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
        () => applyCapitalReassignmentAfterCombat(game, _emptyTopology),
        throwsA(isA<CapitalReassignmentFatalError>()),
      );
    });
  });

  group('applyFactionCapitalReassignmentAfterCombat (Minor/Tribe)', () {
    test('reassigns minor nation capital after loss', () {
      final game = Game(
        id: 'g-minor',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'p2'),
              Province(
                id: 'oldWorld|malt',
                regionId: 'oldWorld',
                ownerId: 'm1',
                townTileKey: 'oldWorld|malt|5|6',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        minorNations: [
          MinorNation(
            id: 'm1',
            capitalProvinceId: 'oldWorld|mcap',
            capitalTile: _tile('oldWorld|mcap', x: 0, y: 0),
          ),
        ],
      );

      final result = applyFactionCapitalReassignmentAfterCombat(
        game,
        _emptyTopology,
      );

      final m1 = result.minorNations.single;
      expect(m1.capitalProvinceId, 'oldWorld|malt');
      expect(m1.capitalTile?.x, 5);
    });

    test('clears minor nation capital when none remain in region', () {
      final game = Game(
        id: 'g-minor-clear',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'p2'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        minorNations: [
          MinorNation(
            id: 'm1',
            capitalProvinceId: 'oldWorld|mcap',
            capitalTile: _tile('oldWorld|mcap', x: 0, y: 0),
          ),
        ],
      );

      final result = applyFactionCapitalReassignmentAfterCombat(
        game,
        _emptyTopology,
      );

      expect(result.minorNations.single.capitalProvinceId, isNull);
    });

    test('reassigns tribe capital after loss', () {
      final game = Game(
        id: 'g-tribe',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(
            provinces: [
              Province(id: 'newWorld|tcap', regionId: 'newWorld', ownerId: 'p2'),
              Province(
                id: 'newWorld|talt',
                regionId: 'newWorld',
                ownerId: 't1',
                townTileKey: 'newWorld|talt|7|8',
              ),
            ],
          ),
        ),
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        tribes: [
          Tribe(
            id: 't1',
            capitalProvinceId: 'newWorld|tcap',
            capitalTile: _tile('newWorld|tcap', x: 0, y: 0),
          ),
        ],
      );

      final result = applyFactionCapitalReassignmentAfterCombat(
        game,
        _emptyTopology,
      );

      expect(result.tribes.single.capitalProvinceId, 'newWorld|talt');
    });

    test('clears tribe capital when none remain in region', () {
      final game = Game(
        id: 'g-tribe-clear',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(
            provinces: [
              Province(id: 'newWorld|tcap', regionId: 'newWorld', ownerId: 'p2'),
            ],
          ),
        ),
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        tribes: [
          Tribe(
            id: 't1',
            capitalProvinceId: 'newWorld|tcap',
            capitalTile: _tile('newWorld|tcap', x: 0, y: 0),
          ),
        ],
      );

      final result = applyFactionCapitalReassignmentAfterCombat(
        game,
        _emptyTopology,
      );

      expect(result.tribes.single.capitalProvinceId, isNull);
    });

    test('throws fatal error when minor candidate lacks townTileKey', () {
      final game = Game(
        id: 'g-minor-throw',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'p2'),
              Province(id: 'oldWorld|malt', regionId: 'oldWorld', ownerId: 'm1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        minorNations: [
          MinorNation(
            id: 'm1',
            capitalProvinceId: 'oldWorld|mcap',
            capitalTile: _tile('oldWorld|mcap', x: 0, y: 0),
          ),
        ],
      );

      expect(
        () =>
            applyFactionCapitalReassignmentAfterCombat(game, _emptyTopology),
        throwsA(isA<CapitalReassignmentFatalError>()),
      );
    });
  });
}
