import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Scenario matrix SC-01…SC-09 and regression slices for GitHub #2082 /
/// `selectFullAiCivilianWorkOrders` (fixtures drive `C(e)` via suggestion-shaped
/// [WorkOrder] rows; scores use [PlayerView] + [Game] per issue).
void main() {
  const playerId = 'gp1';
  const ow = 'oldWorld';

  group('Full AI civilian work #2082 scenario matrix', () {
    test('SC-01: only explore in C(e) → explore (E_score=118)', () {
      const p = '$ow|pExp';
      final tiles = List.generate(
        7,
        (i) => '$ow|pExp|$i|0',
      );
      final vis = <String, VisibilityLevel>{
        for (var i = 0; i < 6; i++) tiles[i]: VisibilityLevel.unknown,
        tiles[6]: VisibilityLevel.fogged,
      };
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: p, regionId: ow, ownerId: 'tribe1'),
            ],
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
            provinces: [
              Province(id: p, regionId: ow, ownerId: playerId),
            ],
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
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'M'),
        ],
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

    test('SC-06: two explore rows — pick higher E (province β, 124)', () {
      const pAlpha = '$ow|pAlpha';
      const pBeta = '$ow|pBeta';
      final alphaTiles = List.generate(7, (i) => '$ow|pAlpha|$i|0');
      final betaTiles = List.generate(8, (i) => '$ow|pBeta|$i|0');
      final vis = <String, VisibilityLevel>{
        alphaTiles[0]: VisibilityLevel.unknown,
        alphaTiles[1]: VisibilityLevel.unknown,
        for (var i = 2; i < 7; i++) alphaTiles[i]: VisibilityLevel.fogged,
        for (final t in betaTiles) t: VisibilityLevel.unknown,
      };

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: pAlpha, regionId: ow, ownerId: 'tribe1'),
              Province(id: pBeta, regionId: ow, ownerId: 'tribe1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              pAlpha: alphaTiles,
              pBeta: betaTiles,
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
            locationProvinceId: pAlpha,
            tileKey: alphaTiles[0],
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
            targetTileKey: alphaTiles[0],
          ),
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetExplore,
            targetTileKey: betaTiles[0],
          ),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetExplore);
      expect(r.workOrders.single.targetTileKey, betaTiles[0]);
    });

    test('SC-07b: equal P_score prospects → lexicographically smaller tile', () {
      const pOwn = '$ow|pOwn';
      const tkLo = '$ow|pOwn|0|0';
      const tkHi = '$ow|pOwn|1|0';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: pOwn, regionId: ow, ownerId: playerId),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              pOwn: [tkLo, tkHi],
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
            locationProvinceId: pOwn,
            tileKey: tkLo,
          ),
        },
        provincesById: const {},
        visibilityByTile: const {
          tkLo: VisibilityLevel.fullyVisible,
          tkHi: VisibilityLevel.fullyVisible,
        },
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetProspect,
            targetTileKey: tkHi,
          ),
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetProspect,
            targetTileKey: tkLo,
          ),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.targetTileKey, tkLo);
    });

    test('SC-08: owned prospect beats minor (57 > 37)', () {
      const pOwn = '$ow|pOwn';
      const pMin = '$ow|pMin';
      const tkOwn = '$ow|pOwn|0|0';
      const tkMin = '$ow|pMin|0|0';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: pOwn, regionId: ow, ownerId: playerId),
              Province(id: pMin, regionId: ow, ownerId: 'minor1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              pOwn: [tkOwn],
              pMin: [tkMin],
            },
          },
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'M'),
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
            locationProvinceId: pOwn,
            tileKey: tkOwn,
          ),
        },
        provincesById: const {},
        visibilityByTile: const {
          tkOwn: VisibilityLevel.fullyVisible,
          tkMin: VisibilityLevel.fullyVisible,
        },
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetProspect,
            targetTileKey: tkMin,
          ),
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetProspect,
            targetTileKey: tkOwn,
          ),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.targetTileKey, tkOwn);
    });

    test('SC-09: urgent minor prospect beats explore-only (132 > 100)', () {
      const pOwn = '$ow|pOwn';
      const pTribe = '$ow|pTr';
      const tkExp = '$ow|pOwn|0|0';
      const tkPr = '$ow|pTr|0|0';
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['pTr'],
        ],
        terrainGrid: const [
          [TerrainType.swamp],
        ],
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: pOwn, regionId: ow, ownerId: playerId),
              Province(id: pTribe, regionId: ow, ownerId: 'tribe1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              pOwn: [tkExp],
              pTribe: [tkPr],
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
            locationProvinceId: pOwn,
            tileKey: tkExp,
          ),
        },
        provincesById: const {},
        visibilityByTile: const {
          tkExp: VisibilityLevel.fullyVisible,
          tkPr: VisibilityLevel.fullyVisible,
        },
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetExplore,
            targetTileKey: tkExp,
          ),
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetProspect,
            targetTileKey: tkPr,
          ),
        ],
        view: view,
        game: game,
        tileMapByRegion: {ow: tileMap},
      );
      expect(r.workOrders.single.target, kWorkTargetProspect);
      expect(r.workOrders.single.targetTileKey, tkPr);
    });
  });

  group('Full AI civilian work #2082 regression bundle', () {
    test('three Explorers with non-empty C(e) → three WorkOrders', () {
      const p = '$ow|p1';
      const tk = '$ow|p1|0|0';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: p, regionId: ow, ownerId: playerId),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {p: [tk]},
          },
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
      );
      Unit ex(String id) => Unit(
            id: id,
            type: kUnitTypeExplorer,
            ownerId: playerId,
            locationProvinceId: p,
            tileKey: tk,
          );
      final view = PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {
          'e1': ex('e1'),
          'e2': ex('e2'),
          'e3': ex('e3'),
        },
        provincesById: const {},
        visibilityByTile: const {tk: VisibilityLevel.fullyVisible},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          WorkOrder(unitId: 'e3', target: kWorkTargetExplore, targetTileKey: tk),
          WorkOrder(unitId: 'e1', target: kWorkTargetExplore, targetTileKey: tk),
          WorkOrder(unitId: 'e2', target: kWorkTargetExplore, targetTileKey: tk),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders, hasLength(3));
      expect(r.workOrders.map((w) => w.unitId).toSet(), {'e1', 'e2', 'e3'});
      expect(r.idleEvents, isEmpty);
    });

    test('deterministic: identical inputs twice → identical picks', () {
      const p = '$ow|p1';
      const tk = '$ow|p1|0|0';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: p, regionId: ow, ownerId: playerId),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {p: [tk]},
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
      const suggestions = [
        WorkOrder(unitId: 'e1', target: kWorkTargetExplore, targetTileKey: tk),
        WorkOrder(unitId: 'e1', target: kWorkTargetProspect, targetTileKey: tk),
      ];
      final a = selectFullAiCivilianWorkOrders(
        workSuggestions: suggestions,
        view: view,
        game: game,
      );
      final b = selectFullAiCivilianWorkOrders(
        workSuggestions: suggestions,
        view: view,
        game: game,
      );
      expect(a.workOrders, b.workOrders);
      expect(a.idleEvents, b.idleEvents);
    });

    test('E_unknown caps at 24 when U is large (min(24, 3×U))', () {
      const p = '$ow|pBig';
      final tiles = List.generate(12, (i) => '$ow|pBig|$i|0');
      final vis = <String, VisibilityLevel>{
        for (final t in tiles) t: VisibilityLevel.unknown,
      };
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: p, regionId: ow, ownerId: 'tribe1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {ow: {p: tiles}},
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
      const tkWeak = '$ow|pWeak|0|0';
      final game2 = Game(
        id: 'g2',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: p, regionId: ow, ownerId: 'tribe1'),
              Province(id: '$ow|pWeak', regionId: ow, ownerId: playerId),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              p: tiles,
              '$ow|pWeak': [tkWeak],
            },
          },
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T')],
      );
      final view2 = PlayerView(
        playerId: playerId,
        player: game2.players.single,
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
        visibilityByTile: {
          ...vis,
          tkWeak: VisibilityLevel.fullyVisible,
        },
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      // Big explore E=124; weak prospect on owned plains = 57 → explore wins.
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetExplore,
            targetTileKey: tiles[0],
          ),
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetProspect,
            targetTileKey: tkWeak,
          ),
        ],
        view: view2,
        game: game2,
      );
      expect(r.workOrders.single.target, kWorkTargetExplore);
    });

    test('non-Explorer idle with empty W(u) → no_suggestions', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
      );
      final view = PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {
          'b1': Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
            ownerId: playerId,
            locationProvinceId: '$ow|p1',
          ),
        },
        provincesById: const {},
        visibilityByTile: const {},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: const [],
        view: view,
        game: game,
      );
      expect(r.workOrders, isEmpty);
      expect(r.idleEvents.single.unitId, 'b1');
      expect(r.idleEvents.single.reason, 'no_suggestions');
    });
  });
}
