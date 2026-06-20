import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show ProvinceOwnerCache;

void main() {
  group('getProvinceOwnerMap reads ProvinceOwnerCache (slice 6)', () {
    Game buildGame() {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      return Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|p1', regionId: ow, ownerId: 'gp1'),
              Province(id: 'oldWorld|p2', regionId: ow, ownerId: 'gp2'),
              Province(id: 'oldWorld|p3', regionId: ow),
            ],
            units: const [],
          ),
          newWorld: RegionData(
            provinces: const [
              Province(id: 'newWorld|n1', regionId: nw, ownerId: 'gp1'),
            ],
            units: const [],
          ),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
      );
    }

    test('matches the projection-derived owner map across both regions', () {
      final game = buildGame();
      final cache = ProvinceOwnerCache.of(game.worldState);
      final expected = <String, String>{
        for (final ownerId in cache.ownerIds)
          for (final p in cache.provincesOwnedBy(ownerId)) p.id: ownerId,
      };

      final map = getProvinceOwnerMap(game);

      expect(map, expected);
      expect(map, {
        'oldWorld|p1': 'gp1',
        'newWorld|n1': 'gp1',
        'oldWorld|p2': 'gp2',
      });
    });

    test('excludes unowned (null-owner) provinces', () {
      final map = getProvinceOwnerMap(buildGame());
      expect(map.containsKey('oldWorld|p3'), isFalse);
    });

    test('excludes empty-string owner provinces (isNotEmpty parity)', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|p1', regionId: ow, ownerId: 'gp1'),
              Province(id: 'oldWorld|p2', regionId: ow, ownerId: ''),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
        ],
      );

      final map = getProvinceOwnerMap(game);
      expect(map, {'oldWorld|p1': 'gp1'});
      expect(map.containsKey('oldWorld|p2'), isFalse);
    });
  });

  group('filterMoveOrdersByDiplomacy and getProvinceOwnerMap', () {
    test('getProvinceOwnerMap returns owner by full province id', () {
      const ow = 'oldWorld';
      final p1 = Province(id: 'p1', regionId: ow, ownerId: 'gp1');
      final p2 = Province(id: 'p2', regionId: ow, ownerId: 'gp2');
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1, p2], units: []),
        newWorld: const RegionData(),
      );
      final game = Game(
        id: 'g1',
        worldState: world,
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
      );
      final map = getProvinceOwnerMap(game);
      expect(map['oldWorld|p1'], 'gp1');
      expect(map['oldWorld|p2'], 'gp2');
    });

    test('getProvinceOwnerMap includes newWorld provinces', () {
      const nw = 'newWorld';
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: RegionData(
          provinces: [
            Province(id: 'newWorld|n1', regionId: nw, ownerId: 'gp1'),
            Province(id: 'newWorld|n2', regionId: nw, ownerId: 'gp2'),
          ],
          units: [],
        ),
      );
      final game = Game(
        id: 'g1',
        worldState: world,
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
      );
      final map = getProvinceOwnerMap(game);
      expect(map['newWorld|n1'], 'gp1');
      expect(map['newWorld|n2'], 'gp2');
    });

    test('filterMoveOrdersByDiplomacy does not drop civilian moves at peace', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'p1', regionId: ow, ownerId: 'gp1'),
              Province(id: 'p2', regionId: ow, ownerId: 'gp2'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 50,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = [
        MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p2|0|0'),
      ];
      final filtered = filterMoveOrdersByDiplomacy(game, 'gp1', orders);
      expect(filtered, orders);
    });

    test('filterMoveOrdersByDiplomacy keeps move to at-war faction', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'p1', regionId: ow, ownerId: 'gp1'),
              Province(id: 'p2', regionId: ow, ownerId: 'gp2'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 0,
            state: RelationState.atWar,
          ),
        ],
      );
      final orders = [
        MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p2|0|0'),
      ];
      final filtered = filterMoveOrdersByDiplomacy(game, 'gp1', orders);
      expect(filtered.length, 1);
      expect(filtered.first.destinationTileKey, 'oldWorld|p2|0|0');
    });
  });
}
