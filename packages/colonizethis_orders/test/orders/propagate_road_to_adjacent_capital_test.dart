import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/orders_application_completed_work.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('propagateRoadToAdjacentCapitalOrPort', () {
    const ow = 'oldWorld';
    const provinceFull = 'oldWorld|P';

    test('returns unchanged when player is null', () {
      final ts = TileMapState();
      final ws = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final out = propagateRoadToAdjacentCapitalOrPort(
        tileKey: '$ow|P|0|0',
        nextLevel: 2,
        player: null,
        worldState: ws,
        tileMapByRegion: const {},
        tileState: ts,
      );
      expect(identical(out, ts), isTrue);
    });

    test('returns unchanged when tile key is malformed', () {
      final ts = TileMapState();
      final ws = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final player = Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalTile: const CapitalTile(
          regionId: ow,
          provinceId: provinceFull,
          x: 0,
          y: 0,
        ),
      );
      final out = propagateRoadToAdjacentCapitalOrPort(
        tileKey: 'not-a-tile-key',
        nextLevel: 2,
        player: player,
        worldState: ws,
        tileMapByRegion: const {},
        tileState: ts,
      );
      expect(identical(out, ts), isTrue);
    });

    test('propagates road level to adjacent capital tile when higher', () {
      const capitalKey = '$ow|P|0|0';
      const buildKey = '$ow|P|1|0';
      final tileMap = TileMapResult(
        width: 3,
        height: 3,
        grid: const [
          ['P', 'P', 'P'],
          ['P', 'P', 'P'],
          ['P', 'P', 'P'],
        ],
        terrainGrid: [
          [for (var i = 0; i < 3; i++) TerrainType.plains],
          [for (var i = 0; i < 3; i++) TerrainType.plains],
          [for (var i = 0; i < 3; i++) TerrainType.plains],
        ],
      );
      final tileState = TileMapState()
          .setRoadLevel(capitalKey, 1)
          .setRoadLevel(buildKey, 2);
      final ws = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final player = Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalTile: const CapitalTile(
          regionId: ow,
          provinceId: provinceFull,
          x: 0,
          y: 0,
        ),
      );
      const nextLevel = 3;

      final out = propagateRoadToAdjacentCapitalOrPort(
        tileKey: buildKey,
        nextLevel: nextLevel,
        player: player,
        worldState: ws,
        tileMapByRegion: {ow: tileMap},
        tileState: tileState,
      );

      expect(out.roadLevel(capitalKey), nextLevel);
    });

    test('propagates road level to adjacent port tile when higher', () {
      const portKey = '$ow|P|0|0';
      const buildKey = '$ow|P|1|0';
      final tileMap = TileMapResult(
        width: 3,
        height: 3,
        grid: const [
          ['P', 'P', 'P'],
          ['P', 'P', 'P'],
          ['P', 'P', 'P'],
        ],
        terrainGrid: [
          [for (var i = 0; i < 3; i++) TerrainType.plains],
          [for (var i = 0; i < 3; i++) TerrainType.plains],
          [for (var i = 0; i < 3; i++) TerrainType.plains],
        ],
      );
      final tileState = TileMapState()
          .setRoadLevel(portKey, 1)
          .setRoadLevel(buildKey, 2);
      final ws = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
        portsByProvinceSeaboard: {
          '$provinceFull|sz1': portKey,
        },
      );
      const player = Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
      );
      const nextLevel = 3;

      final out = propagateRoadToAdjacentCapitalOrPort(
        tileKey: buildKey,
        nextLevel: nextLevel,
        player: player,
        worldState: ws,
        tileMapByRegion: {ow: tileMap},
        tileState: tileState,
      );

      expect(out.roadLevel(portKey), nextLevel);
    });
  });
}
