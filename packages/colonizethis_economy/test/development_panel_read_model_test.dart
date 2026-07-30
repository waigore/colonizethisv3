import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement, kUnitTypeBuilder;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

DevelopmentPanelModel _ownedGrainImprovableModel() {
  final map = tileMapFromGrids(
    grid: const [
      ['p1', 'p1'],
    ],
    resourceGrid: const [
      [Resource.grain, Resource.grain],
    ],
  );
  final keys = <String>[
    for (var y = 0; y < 1; y++)
      for (var x = 0; x < 2; x++) 'oldWorld|p1|$x|$y',
  ];
  final game = spainExtractorGame(
    tileState: const TileMapState(),
    oldWorld: RegionData(provinces: [owP1Province()]),
    tileKeysByRegionAndProvince: {'oldWorld': {'p1': keys}},
  );
  return buildDevelopmentPanelModel(
    game: game,
    playerId: 'pl1',
    tileMapByRegion: {'oldWorld': map},
    topology: MapTopology(),
    currentOrders: const Orders(),
    provinceDisplayNamesById: const {'oldWorld|p1': 'Avalon'},
    playerDisplayNamesById: const {'pl1': 'France'},
  );
}

DevelopmentPanelModel _modelWithPendingWorkOrders() {
  final game = resourceExtractorGame(tileState: const TileMapState());
  const orders = Orders(
    workOrdersByPlayerId: {
      'pl1': [
        WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: 'oldWorld|p1|0|0',
        ),
      ],
    },
  );
  return buildDevelopmentPanelModel(
    game: game,
    playerId: 'pl1',
    tileMapByRegion: const {},
    topology: MapTopology(),
    currentOrders: orders,
    provinceDisplayNamesById: const {},
    playerDisplayNamesById: const {},
  );
}

void main() {
  suppressLogsForTests();

  group('buildDevelopmentPanelModel (Refs #4175)', () {
    test('owned province lists improvable grain from Available parity', () {
      final ow = _ownedGrainImprovableModel().oldWorld;
      expect(ow.ownedScopes, hasLength(1));
      expect(ow.ownedScopes.first.displayName, 'Avalon');
      expect(ow.ownedScopes.first.improvableCommodities, hasLength(1));
      expect(
        ow.ownedScopes.first.improvableCommodities.first.commodityId,
        CommodityCatalog.grain.id,
      );
      expect(ow.ownedScopes.first.improvableCommodities.first.count, 2);
    });

    test('model builds with pending work orders without throwing', () {
      expect(
        _modelWithPendingWorkOrders().oldWorld.idleBuilderCount,
        greaterThanOrEqualTo(0),
      );
    });

    test('playerView filters unrevealed improvable tiles from counts', () {
      final map = tileMapFromGrids(
        grid: const [
          ['p1', 'p1'],
        ],
        resourceGrid: const [
          [Resource.grain, Resource.grain],
        ],
      );
      final keys = <String>[
        'oldWorld|p1|0|0',
        'oldWorld|p1|1|0',
      ];
      final game = spainExtractorGame(
        tileState: const TileMapState(),
        oldWorld: RegionData(provinces: [owP1Province()]),
        tileKeysByRegionAndProvince: {'oldWorld': {'p1': keys}},
      );
      final baseView = buildPlayerView(game, MapTopology(), 'pl1');
      final playerView = PlayerView(
        playerId: baseView.playerId,
        player: baseView.player,
        ownUnitsById: baseView.ownUnitsById,
        provincesById: baseView.provincesById,
        visibilityByTile: const {
          'oldWorld|p1|0|0': VisibilityLevel.fullyVisible,
          'oldWorld|p1|1|0': VisibilityLevel.unknown,
        },
        prospectedTiles: baseView.prospectedTiles,
        diplomacyByOtherId: baseView.diplomacyByOtherId,
      );
      final model = buildDevelopmentPanelModel(
        game: game,
        playerId: 'pl1',
        tileMapByRegion: {'oldWorld': map},
        topology: MapTopology(),
        currentOrders: const Orders(),
        provinceDisplayNamesById: const {'oldWorld|p1': 'Avalon'},
        playerDisplayNamesById: const {'pl1': 'France'},
        playerView: playerView,
      );
      final grain = model.oldWorld.ownedScopes.first.improvableCommodities
          .firstWhere((r) => r.commodityId == CommodityCatalog.grain.id);
      expect(grain.count, 1);
      expect(grain.tileKeys, ['oldWorld|p1|0|0']);
    });

    test('assigned civilians include pending builder in region', () {
      final unit = Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: 'pl1',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = TestFixtures.oldWorldGameWithUnit(unit: unit);
      const orders = Orders(
        workOrdersByPlayerId: {
          'pl1': [
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );
      final model = buildDevelopmentPanelModel(
        game: game,
        playerId: 'pl1',
        tileMapByRegion: const {},
        topology: MapTopology(),
        currentOrders: orders,
        provinceDisplayNamesById: const {},
        playerDisplayNamesById: const {},
      );
      expect(model.oldWorld.assignedCivilians, hasLength(1));
      expect(model.oldWorld.assignedCivilians.first.unitId, 'b1');
      expect(model.oldWorld.assignedCivilians.first.isPending, isTrue);
    });
  });
}
