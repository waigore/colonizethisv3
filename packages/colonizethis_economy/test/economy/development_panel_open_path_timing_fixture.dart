// Shared fixture for Development panel open-path timing and reuse tests (Refs #4175).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show rankIndustryCounselRecommendations;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show
        economyPreviewInputs,
        forcesFeedingForPlayer,
        labourReadinessForPlayer,
        previewStockpileNetDeltaByCommodityForPlayer;
import 'package:colonizethis_world/colonizethis_world.dart';

class DevelopmentPanelOpenPathTimingFixture {
  DevelopmentPanelOpenPathTimingFixture._({
    required this.game,
    required this.tileMapByRegion,
    required this.topology,
    required this.provinceDisplayNamesById,
    required this.playerDisplayNamesById,
  });

  final Game game;
  final Map<String, TileMapResult> tileMapByRegion;
  final MapTopology topology;
  final Map<String, String> provinceDisplayNamesById;
  final Map<String, String> playerDisplayNamesById;

  static const playerId = 'pl1';
  static const orders = Orders();

  factory DevelopmentPanelOpenPathTimingFixture.build() {
    const owProvince = 'oldWorld|p1';
    const owProvince2 = 'oldWorld|p2';
    const nwProvinceCount = 10;
    const nwTilesPerProvinceRow = 4;
    final nwGrid = List.generate(
      nwProvinceCount,
      (row) => List.generate(nwTilesPerProvinceRow, (_) => 'n${row + 1}'),
    );
    final nwResourceGrid = nwGrid
        .map((row) => row.map((_) => Resource.spices).toList())
        .toList();
    final nwProvinces = List.generate(
      nwProvinceCount,
      (index) {
        final localId = 'n${index + 1}';
        return Province(
          id: 'newWorld|$localId',
          regionId: kRegionNewWorld,
          ownerId: playerId,
        );
      },
    );
    final nwTileKeysByProvince = <String, List<String>>{};
    for (var row = 0; row < nwGrid.length; row++) {
      final localId = nwGrid[row].first;
      final provinceId = 'newWorld|$localId';
      for (var col = 0; col < nwGrid[row].length; col++) {
        nwTileKeysByProvince
            .putIfAbsent(provinceId, () => <String>[])
            .add('newWorld|$localId|$col|$row');
      }
    }
    final owMap = tileMapFromGrids(
      grid: const [
        ['p1', 'p1'],
        ['p2', 'p2'],
      ],
      resourceGrid: const [
        [Resource.grain, Resource.grain],
        [Resource.timber, Resource.timber],
      ],
    );
    final nwMap = tileMapFromGrids(
      grid: nwGrid,
      resourceGrid: nwResourceGrid,
    );
    final game = spainExtractorGame(
      tileState: const TileMapState(),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: owProvince,
            regionId: kRegionOldWorld,
            ownerId: playerId,
          ),
          Province(
            id: owProvince2,
            regionId: kRegionOldWorld,
            ownerId: playerId,
          ),
        ],
      ),
      newWorld: RegionData(provinces: nwProvinces),
      tileKeysByRegionAndProvince: {
        kRegionOldWorld: {
          owProvince: ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
          owProvince2: ['oldWorld|p2|0|0', 'oldWorld|p2|1|0'],
        },
        kRegionNewWorld: nwTileKeysByProvince,
      },
    );
    return DevelopmentPanelOpenPathTimingFixture._(
      game: game,
      tileMapByRegion: {
        kRegionOldWorld: owMap,
        kRegionNewWorld: nwMap,
      },
      topology: MapTopology(),
      provinceDisplayNamesById: {
        owProvince: 'OW-1',
        owProvince2: 'OW-2',
        for (var index = 0; index < nwProvinceCount; index++)
          'newWorld|n${index + 1}': 'NW-${index + 1}',
      },
      playerDisplayNamesById: {playerId: 'Spain'},
    );
  }

  void runDevelopmentLazyOldWorldOpenPath() {
    final shared = buildDevelopmentPanelBuildContext(
      game: game,
      playerId: playerId,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
      currentOrders: orders,
    );
    buildDevelopmentPanelRegionModel(
      shared: shared,
      game: game,
      playerId: playerId,
      regionId: kRegionOldWorld,
      tileMapByRegion: tileMapByRegion,
      currentOrders: orders,
      provinceDisplayNamesById: provinceDisplayNamesById,
      playerDisplayNamesById: playerDisplayNamesById,
    );
  }

  void runProductionPanelOpenPathSurrogate() {
    runProductionPanelOpenPathCore(includeCounselRanking: true);
  }

  void runProductionPanelOpenPathSurrogateWithoutCounsel() {
    runProductionPanelOpenPathCore(includeCounselRanking: false);
  }

  void runProductionPanelOpenPathCore({required bool includeCounselRanking}) {
    final inputs = economyPreviewInputs(
      tileMapByRegion: tileMapByRegion,
      currentOrders: orders,
    );
    previewStockpileNetDeltaByCommodityForPlayer(
      game: game,
      topology: topology,
      playerId: playerId,
      inputs: economyPreviewInputs(
        tileMapByRegion: tileMapByRegion,
        currentOrders: orders,
        defaultAssignmentsByPlayerId: {
          playerId: assignedRecipesFromDesiredOutput(const {}),
        },
      ),
    );
    final regimentCounts = regimentTypeCountsForPlayer(
      game.worldState,
      playerId,
    );
    final shipCounts = shipTypeCountsForPlayer(game.worldState, playerId);
    final foodCounts = MilitaryNavyFoodCounts(
      regimentCountsById: regimentCounts,
      shipCountsById: shipCounts,
    );
    labourReadinessForPlayer(
      game: game,
      topology: topology,
      playerId: playerId,
      foodCounts: foodCounts,
      inputs: inputs,
    );
    forcesFeedingForPlayer(
      game: game,
      topology: topology,
      playerId: playerId,
      foodCounts: foodCounts,
      inputs: inputs,
    );
    if (includeCounselRanking) {
      rankIndustryCounselRecommendations(
        game: game,
        playerId: playerId,
        currentOrders: orders,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
      );
    }
  }
}

int timeMicros(void Function() fn, {required int iterations}) {
  for (var i = 0; i < 3; i++) {
    fn();
  }
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    fn();
  }
  sw.stop();
  return sw.elapsedMicroseconds;
}

/// Median of three timed samples dampens shared-runner jitter on CI.
int timeMicrosMedian(void Function() fn, {required int iterations}) {
  final samples = <int>[
    for (var run = 0; run < 3; run++) timeMicros(fn, iterations: iterations),
  ]..sort();
  return samples[1];
}
