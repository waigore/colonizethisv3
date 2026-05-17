import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Scenario matrix SC-06-SC-09 for GitHub #2082 / `selectFullAiCivilianWorkOrders`.
/// Split from monolith for #2288; see sibling file for SC-01-SC-05 and regressions.
void main() {
  const playerId = 'gp1';
  const ow = 'oldWorld';

  group('Full AI civilian work #2082 scenario matrix (SC-06-SC-09)', () {
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
            ow: {pAlpha: alphaTiles, pBeta: betaTiles},
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

    test(
      'SC-07b: equal P_score prospects → lexicographically smaller tile',
      () {
        const pOwn = '$ow|pOwn';
        const tkLo = '$ow|pOwn|0|0';
        const tkHi = '$ow|pOwn|1|0';
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [Province(id: pOwn, regionId: ow, ownerId: playerId)],
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
      },
    );

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
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M')],
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
}
