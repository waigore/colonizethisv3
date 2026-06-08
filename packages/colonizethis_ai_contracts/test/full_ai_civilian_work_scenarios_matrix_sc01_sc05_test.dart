import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Scenario matrix SC-01-SC-05 for GitHub #2082 / `selectFullAiCivilianWorkOrders`.
/// Split from monolith for #2288; see sibling files for SC-06-SC-09 and regressions.
void main() {
  const playerId = 'gp1';
  const ow = 'oldWorld';

  group('Full AI civilian work #2082 scenario matrix (SC-01-SC-05)', () {
    test('SC-01: only explore in C(e) → explore (E_score=118)', () {
      const p = '$ow|pExp';
      final tiles = List.generate(7, (i) => '$ow|pExp|$i|0');
      final vis = <String, VisibilityLevel>{
        for (var i = 0; i < 6; i++) tiles[i]: VisibilityLevel.unknown,
        tiles[6]: VisibilityLevel.fogged,
      };
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: p, regionId: ow, ownerId: 'tribe1')],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {p: tiles},
          },
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T')],
      );
      final view = PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {
          'e1': Unit(
            id: 'e1',
            type: kUnitTypeExplorer,
            ownerId: playerId,
            locationProvinceId: p,
            tileKey: tiles[0],
          ),
        },
        provincesById: const {},
        visibilityByTile: vis,
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetExplore,
            targetTileKey: tiles[0],
          ),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetExplore);
      expect(r.workOrders.single.targetTileKey, tiles[0]);
      expect(r.idleEvents, isEmpty);
    });

    test('SC-02: only prospect in C(e) → prospect (P_score=57)', () {
      const p = '$ow|pOwn';
      const tk = '$ow|pOwn|0|0';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [Province(id: p, regionId: ow, ownerId: playerId)],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              p: [tk],
            },
          },
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
      );
      final view = PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {
          'e1': Unit(
            id: 'e1',
            type: kUnitTypeExplorer,
            ownerId: playerId,
            locationProvinceId: p,
            tileKey: tk,
          ),
        },
        provincesById: const {},
        visibilityByTile: const {tk: VisibilityLevel.fullyVisible},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetProspect,
            targetTileKey: tk,
          ),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetProspect);
      expect(r.workOrders.single.targetTileKey, tk);
    });

    test('SC-03: explore beats weaker prospect (118 > 57)', () {
      const pExp = '$ow|pExp';
      const pOwn = '$ow|pOwn';
      final expTiles = List.generate(7, (i) => '$ow|pExp|$i|0');
      const ownTk = '$ow|pOwn|0|0';
      final vis = <String, VisibilityLevel>{
        for (var i = 0; i < 6; i++) expTiles[i]: VisibilityLevel.unknown,
        expTiles[6]: VisibilityLevel.fogged,
        ownTk: VisibilityLevel.fullyVisible,
      };
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: pExp, regionId: ow, ownerId: 'tribe1'),
              Province(id: pOwn, regionId: ow, ownerId: playerId),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              pExp: expTiles,
              pOwn: [ownTk],
            },
          },
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T')],
      );
      final view = PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {
          'e1': Unit(
            id: 'e1',
            type: kUnitTypeExplorer,
            ownerId: playerId,
            locationProvinceId: pExp,
            tileKey: expTiles[0],
          ),
        },
        provincesById: const {},
        visibilityByTile: vis,
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetExplore,
            targetTileKey: expTiles[0],
          ),
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetProspect,
            targetTileKey: ownTk,
          ),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetExplore);
    });

    test('SC-04: strong prospect beats explore (152 > 100)', () {
      const pExp = '$ow|pExp';
      const pOwn = '$ow|pOwn';
      const expTk = '$ow|pExp|0|0';
      const ownTk = '$ow|pOwn|0|0';
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['pOwn'],
        ],
        terrainGrid: const [
          [TerrainType.hills],
        ],
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: pExp, regionId: ow, ownerId: 'tribe1'),
              Province(id: pOwn, regionId: ow, ownerId: playerId),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              pExp: [expTk],
              pOwn: [ownTk],
            },
          },
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T')],
      );
      final view = PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {
          'e1': Unit(
            id: 'e1',
            type: kUnitTypeExplorer,
            ownerId: playerId,
            locationProvinceId: pExp,
            tileKey: expTk,
          ),
        },
        provincesById: const {},
        visibilityByTile: const {
          expTk: VisibilityLevel.fullyVisible,
          ownTk: VisibilityLevel.fullyVisible,
        },
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetExplore,
            targetTileKey: expTk,
          ),
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetProspect,
            targetTileKey: ownTk,
          ),
        ],
        view: view,
        game: game,
        tileMapByRegion: {ow: tileMap},
      );
      expect(r.workOrders.single.target, kWorkTargetProspect);
      expect(r.workOrders.single.targetTileKey, ownTk);
    });

    test('SC-05: two prospect rows — pick higher P (tile B, 140)', () {
      const pExp = '$ow|pExp';
      const pA = '$ow|pA';
      const pB = '$ow|pB';
      final expTiles = List.generate(7, (i) => '$ow|pExp|$i|0');
      const tileA = '$ow|pA|0|0';
      const tileB = '$ow|pB|1|0';
      final vis = <String, VisibilityLevel>{
        for (var i = 0; i < 6; i++) expTiles[i]: VisibilityLevel.unknown,
        expTiles[6]: VisibilityLevel.fogged,
        tileA: VisibilityLevel.fullyVisible,
        tileB: VisibilityLevel.fullyVisible,
      };
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: pExp, regionId: ow, ownerId: 'tribe1'),
              Province(id: pA, regionId: ow, ownerId: playerId),
              Province(id: pB, regionId: ow, ownerId: 'minor1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          purchasedTilesByTileKey: {tileB: playerId},
          tileKeysByRegionAndProvince: {
            ow: {
              pExp: expTiles,
              pA: [tileA],
              pB: [tileB],
            },
          },
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T')],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M')],
      );
      final tileMap = TileMapResult(
        width: 2,
        height: 1,
        grid: const [
          ['pA', 'pB'],
        ],
        terrainGrid: const [
          [TerrainType.plains, TerrainType.hills],
        ],
      );
      final view = PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {
          'e1': Unit(
            id: 'e1',
            type: kUnitTypeExplorer,
            ownerId: playerId,
            locationProvinceId: pExp,
            tileKey: expTiles[0],
          ),
        },
        provincesById: const {},
        visibilityByTile: vis,
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetExplore,
            targetTileKey: expTiles[0],
          ),
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetProspect,
            targetTileKey: tileA,
          ),
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetProspect,
            targetTileKey: tileB,
          ),
        ],
        view: view,
        game: game,
        tileMapByRegion: {ow: tileMap},
      );
      expect(r.workOrders.single.target, kWorkTargetProspect);
      expect(r.workOrders.single.targetTileKey, tileB);
    });
  });
}
