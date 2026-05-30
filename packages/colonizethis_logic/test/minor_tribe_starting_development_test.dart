// SPEC/game/factions.md § Starting developed resources (Minor Nations and Tribes).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('selectMinorTribeStartingDevelopmentTileKeys', () {
    test('orders by Manhattan distance then y asc then x asc', () {
      // 4x3 grid all in province p1; resource on every non-capital land tile.
      final tileMap = TileMapResult(
        width: 4,
        height: 3,
        grid: const [
          ['p1', 'p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1', 'p1'],
        ],
        terrainGrid: List.generate(
          3,
          (_) => List<TerrainType?>.filled(4, TerrainType.plains),
        ),
        resourceGrid: List.generate(
          3,
          (_) => List<Resource?>.filled(4, Resource.grain),
        ),
      );
      final capital = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 2,
        y: 1,
      );
      final capitalKey = CapitalTile.tileKey(
        capital.regionId,
        capital.provinceId,
        capital.x,
        capital.y,
      );
      final picks = selectMinorTribeStartingDevelopmentTileKeys(
        map: tileMap,
        capital: capital,
        tileState: TileMapState(),
        forbiddenTileKeys: {capitalKey},
        maxTiles: 4,
      );
      // Distance-1 tiles around (2,1) sorted by y asc then x asc:
      //   (2,0) d=1, (1,1) d=1, (3,1) d=1, (2,2) d=1.
      expect(picks, [
        'oldWorld|p1|2|0',
        'oldWorld|p1|1|1',
        'oldWorld|p1|3|1',
        'oldWorld|p1|2|2',
      ]);
    });

    test('excludes capital and town tiles, tiles without resource or terrain, '
        'and already-developed tiles', () {
      final tileMap = TileMapResult(
        width: 3,
        height: 2,
        grid: const [
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
        ],
        terrainGrid: const [
          [
            TerrainType.plains,
            null, // tile (1,0) has no terrain
            TerrainType.plains,
          ],
          [
            TerrainType.plains,
            TerrainType.plains,
            TerrainType.plains,
          ],
        ],
        resourceGrid: const [
          [
            Resource.grain, // capital — excluded by forbidden
            null, // no terrain anyway
            Resource.timber, // town — excluded by forbidden
          ],
          [
            Resource.grain, // already developed
            null, // no resource on this tile
            Resource.iron, // eligible
          ],
        ],
      );
      final capital = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      final capitalKey = CapitalTile.tileKey(
        capital.regionId,
        capital.provinceId,
        capital.x,
        capital.y,
      );
      final townKey = CapitalTile.tileKey(
        capital.regionId,
        capital.provinceId,
        2,
        0,
      );
      final tileState = TileMapState().setImprovement('oldWorld|p1|0|1', 1);
      final picks = selectMinorTribeStartingDevelopmentTileKeys(
        map: tileMap,
        capital: capital,
        tileState: tileState,
        forbiddenTileKeys: {capitalKey, townKey},
        maxTiles: 4,
      );
      expect(picks, ['oldWorld|p1|2|1']);
    });

    test('returns empty list when terrain or resource grid is missing', () {
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: const [
          ['p1', 'p1'],
          ['p1', 'p1'],
        ],
      );
      final capital = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      expect(
        selectMinorTribeStartingDevelopmentTileKeys(
          map: tileMap,
          capital: capital,
          tileState: TileMapState(),
          forbiddenTileKeys: const {},
          maxTiles: 2,
        ),
        isEmpty,
      );
    });

    test('skips tiles outside the capital province', () {
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: const [
          ['p1', 'p2'],
          ['p2', 'p1'],
        ],
        terrainGrid: List.generate(
          2,
          (_) => List<TerrainType?>.filled(2, TerrainType.plains),
        ),
        resourceGrid: List.generate(
          2,
          (_) => List<Resource?>.filled(2, Resource.timber),
        ),
      );
      final capital = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      final capitalKey = CapitalTile.tileKey(
        capital.regionId,
        capital.provinceId,
        0,
        0,
      );
      final picks = selectMinorTribeStartingDevelopmentTileKeys(
        map: tileMap,
        capital: capital,
        tileState: TileMapState(),
        forbiddenTileKeys: {capitalKey},
        maxTiles: 4,
      );
      // Only (1,1) belongs to p1 and is eligible — (1,0) and (0,1) belong to p2.
      expect(picks, ['oldWorld|p1|1|1']);
    });

    test('returns empty list when maxTiles is zero', () {
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['oldWorld|p1'],
        ],
        terrainGrid: const [
          [TerrainType.plains],
        ],
        resourceGrid: const [
          [Resource.grain],
        ],
      );
      final capital = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      expect(
        selectMinorTribeStartingDevelopmentTileKeys(
          map: tileMap,
          capital: capital,
          tileState: TileMapState(),
          forbiddenTileKeys: const {},
          maxTiles: 0,
        ),
        isEmpty,
      );
    });
  });

  group('applyMinorTribeStartingDevelopment', () {
    Game buildGame({
      required CapitalTile? minorCapital,
      required CapitalTile? tribeCapital,
    }) {
      final owProvinces = <Province>[
        Province(
          id: 'oldWorld|p_minor',
          regionId: 'oldWorld',
          ownerId: 'minor_1',
        ),
      ];
      final nwProvinces = <Province>[
        Province(
          id: 'newWorld|p_tribe',
          regionId: 'newWorld',
          ownerId: 'tribe_1',
        ),
      ];
      return Game(
        id: 'g_minor_tribe_dev',
        worldState: WorldState(
          turnState: const TurnState(
            turnNumber: 0,
            phase: TurnPhase.orders,
          ),
          oldWorld: RegionData(provinces: owProvinces),
          newWorld: RegionData(provinces: nwProvinces),
        ),
        players: const <Player>[
          Player(id: 'gp1', displayName: 'Power 1', isHuman: true),
        ],
        minorNations: <MinorNation>[
          MinorNation(
            id: 'minor_1',
            displayName: 'Minor',
            capitalProvinceId:
                minorCapital == null ? null : 'oldWorld|p_minor',
            capitalTile: minorCapital,
          ),
        ],
        tribes: <Tribe>[
          Tribe(
            id: 'tribe_1',
            displayName: 'Tribe',
            capitalProvinceId:
                tribeCapital == null ? null : 'newWorld|p_tribe',
            capitalTile: tribeCapital,
          ),
        ],
      );
    }

    TileMapResult resourceGrid({
      required int width,
      required int height,
      required String localId,
      required String regionId,
    }) {
      return TileMapResult(
        width: width,
        height: height,
        grid: List.generate(
          height,
          (_) => List<String>.filled(width, localId),
        ),
        terrainGrid: List.generate(
          height,
          (_) => List<TerrainType?>.filled(width, TerrainType.plains),
        ),
        resourceGrid: List.generate(
          height,
          (_) => List<Resource?>.filled(width, Resource.grain),
        ),
      );
    }

    test('develops K tiles for minor and tribe with eligible provinces', () {
      final minorCap = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p_minor',
        x: 1,
        y: 1,
      );
      final tribeCap = CapitalTile(
        regionId: 'newWorld',
        provinceId: 'newWorld|p_tribe',
        x: 0,
        y: 0,
      );
      final game = buildGame(
        minorCapital: minorCap,
        tribeCapital: tribeCap,
      );
      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': resourceGrid(
          width: 3,
          height: 3,
          localId: 'p_minor',
          regionId: 'oldWorld',
        ),
        'newWorld': resourceGrid(
          width: 2,
          height: 2,
          localId: 'p_tribe',
          regionId: 'newWorld',
        ),
      };

      final out = applyMinorTribeStartingDevelopment(
        game: game,
        tileMapByRegion: tileMapByRegion,
      );

      // Each faction picked 2 tiles by default.
      expect(out.developedTileKeysByFactionId.keys.toSet(), {
        'minor_1',
        'tribe_1',
      });
      expect(out.developedTileKeysByFactionId['minor_1']!.length, 2);
      expect(out.developedTileKeysByFactionId['tribe_1']!.length, 2);

      // Each developed tile has improvement level 1; capital tile remains 0.
      final ts = out.game.worldState.tileState;
      for (final keys in out.developedTileKeysByFactionId.values) {
        for (final k in keys) {
          expect(ts.improvementLevel(k), 1, reason: 'developed tile $k');
        }
      }
      expect(ts.improvementLevel(minorCap.toTileKey()), 0);
      expect(ts.improvementLevel(tribeCap.toTileKey()), 0);

      // None of the developed tiles is a capital tile (negative invariant).
      final capitalKeys = <String>{
        minorCap.toTileKey(),
        tribeCap.toTileKey(),
      };
      for (final keys in out.developedTileKeysByFactionId.values) {
        for (final k in keys) {
          expect(capitalKeys.contains(k), isFalse);
        }
      }

      // Terrain and resource on each developed tile are unchanged (regression
      // guard: rule must not mutate terrain or resource ids).
      final owMap = tileMapByRegion['oldWorld']!;
      for (final k in out.developedTileKeysByFactionId['minor_1']!) {
        final parts = k.split('|');
        final x = int.parse(parts[2]);
        final y = int.parse(parts[3]);
        expect(owMap.resourceAt(x, y), Resource.grain);
        expect(owMap.terrainAt(x, y), TerrainType.plains);
      }
    });

    test('zero K is a no-op (does not raise, does not mutate)', () {
      final minorCap = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p_minor',
        x: 0,
        y: 0,
      );
      final game = buildGame(minorCapital: minorCap, tribeCapital: null);
      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': resourceGrid(
          width: 2,
          height: 2,
          localId: 'p_minor',
          regionId: 'oldWorld',
        ),
      };
      final out = applyMinorTribeStartingDevelopment(
        game: game,
        tileMapByRegion: tileMapByRegion,
        maxTilesPerCapital: 0,
      );
      expect(out.developedTileKeysByFactionId, isEmpty);
      // No improvement raised anywhere.
      expect(out.game.worldState.tileState.improvementLevel('oldWorld|p_minor|0|0'), 0);
      expect(out.game.worldState.tileState.improvementLevel('oldWorld|p_minor|1|0'), 0);
      expect(out.game.worldState.tileState.improvementLevel('oldWorld|p_minor|0|1'), 0);
      expect(out.game.worldState.tileState.improvementLevel('oldWorld|p_minor|1|1'), 0);
    });

    test('factions without capital tiles are silently skipped', () {
      final game = buildGame(minorCapital: null, tribeCapital: null);
      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': resourceGrid(
          width: 2,
          height: 2,
          localId: 'p_minor',
          regionId: 'oldWorld',
        ),
        'newWorld': resourceGrid(
          width: 2,
          height: 2,
          localId: 'p_tribe',
          regionId: 'newWorld',
        ),
      };
      final out = applyMinorTribeStartingDevelopment(
        game: game,
        tileMapByRegion: tileMapByRegion,
      );
      expect(out.developedTileKeysByFactionId, isEmpty);
      expect(out.game.worldState.tileState, game.worldState.tileState);
    });

    test('develops every eligible tile when fewer than K are available', () {
      // Province has only 1 non-capital land tile available (2x1 grid, capital at (0,0)).
      final minorCap = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p_minor',
        x: 0,
        y: 0,
      );
      final game = buildGame(minorCapital: minorCap, tribeCapital: null);
      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': resourceGrid(
          width: 2,
          height: 1,
          localId: 'p_minor',
          regionId: 'oldWorld',
        ),
      };
      final out = applyMinorTribeStartingDevelopment(
        game: game,
        tileMapByRegion: tileMapByRegion,
      );
      expect(out.developedTileKeysByFactionId['minor_1'], ['oldWorld|p_minor|1|0']);
      expect(
        out.game.worldState.tileState.improvementLevel('oldWorld|p_minor|1|0'),
        1,
      );
      expect(
        out.game.worldState.tileState.improvementLevel('oldWorld|p_minor|0|0'),
        0,
      );
    });

    test('throws when maxTilesPerCapital is negative', () {
      final game = buildGame(minorCapital: null, tribeCapital: null);
      expect(
        () => applyMinorTribeStartingDevelopment(
          game: game,
          tileMapByRegion: const {},
          maxTilesPerCapital: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('mismatched capital region for a minor is skipped without mutating '
        'worldState', () {
      // Minor capital sits in newWorld (wrong region for minors); rule skips it.
      final minorCap = CapitalTile(
        regionId: 'newWorld',
        provinceId: 'newWorld|p_minor',
        x: 0,
        y: 0,
      );
      final game = buildGame(minorCapital: minorCap, tribeCapital: null);
      final tileMapByRegion = <String, TileMapResult>{
        'newWorld': resourceGrid(
          width: 2,
          height: 2,
          localId: 'p_minor',
          regionId: 'newWorld',
        ),
      };
      final out = applyMinorTribeStartingDevelopment(
        game: game,
        tileMapByRegion: tileMapByRegion,
      );
      expect(out.developedTileKeysByFactionId, isEmpty);
      expect(out.game.worldState.tileState, game.worldState.tileState);
    });
  });
}
