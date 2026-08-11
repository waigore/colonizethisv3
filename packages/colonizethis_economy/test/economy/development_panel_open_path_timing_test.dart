// Open-path timing guard for Development panel (Refs #4175 Slice E AC2).
//
// Profiling surrogate for Flutter DevTools timeline captures: documents that the
// lazy per-region read model is measurably cheaper than the monolithic dual-region
// build used before Slice E, and that shared connectivity is reused across regions.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show rankIndustryCounselRecommendations;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show
        economyPreviewInputs,
        forcesFeedingForPlayer,
        labourReadinessForPlayer,
        previewStockpileNetDeltaByCommodityForPlayer;
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Map<String, TileMapResult> tileMapByRegion;
  late MapTopology topology;
  late Map<String, String> provinceDisplayNamesById;
  late Map<String, String> playerDisplayNamesById;
  const playerId = 'pl1';
  const orders = Orders();

  setUp(() {
    const owProvince = 'oldWorld|p1';
    const owProvince2 = 'oldWorld|p2';
    const nwProvince = 'newWorld|n1';
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
      grid: const [
        ['n1', 'n1'],
      ],
      resourceGrid: const [
        [Resource.spices, Resource.spices],
      ],
    );
    game = spainExtractorGame(
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
      newWorld: RegionData(
        provinces: [
          Province(
            id: nwProvince,
            regionId: kRegionNewWorld,
            ownerId: playerId,
          ),
        ],
      ),
      tileKeysByRegionAndProvince: {
        kRegionOldWorld: {
          owProvince: ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
          owProvince2: ['oldWorld|p2|0|0', 'oldWorld|p2|1|0'],
        },
        kRegionNewWorld: {
          nwProvince: ['newWorld|n1|0|0', 'newWorld|n1|1|0'],
        },
      },
    );
    tileMapByRegion = {
      kRegionOldWorld: owMap,
      kRegionNewWorld: nwMap,
    };
    topology = MapTopology();
    provinceDisplayNamesById = {
      owProvince: 'OW-1',
      owProvince2: 'OW-2',
      nwProvince: 'NW-1',
    };
    playerDisplayNamesById = {playerId: 'Spain'};
  });

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

  /// Surrogate for `ProductionScreenBody` synchronous prep on panel open
  /// (stockpile preview, labour/forces readiness, industry counsel ranking).
  void runProductionPanelOpenPathSurrogate() {
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
    rankIndustryCounselRecommendations(
      game: game,
      playerId: playerId,
      currentOrders: orders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
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

  test(
    'lazy Old World-only read model is faster than monolithic dual-region build (Refs #4175 Slice E AC2)',
    () {
      const iterations = 50;
      final monolithicMicros = timeMicros(
        () => buildDevelopmentPanelModel(
          game: game,
          playerId: playerId,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
          currentOrders: orders,
          provinceDisplayNamesById: provinceDisplayNamesById,
          playerDisplayNamesById: playerDisplayNamesById,
        ),
        iterations: iterations,
      );
      final lazyOwMicros = timeMicros(
        runDevelopmentLazyOldWorldOpenPath,
        iterations: iterations,
      );

      // Slice E open path builds one visited region; expect a measurable win vs
      // eager dual-region projection (typically ~35–55% on this fixture).
      final improvementRatio =
          (monolithicMicros - lazyOwMicros) / monolithicMicros;
      expect(
        lazyOwMicros,
        lessThan(monolithicMicros),
        reason:
            'monolithic=$monolithicMicrosµs lazyOW=$lazyOwMicrosµs '
            '(${ (improvementRatio * 100).toStringAsFixed(1)}% faster) '
            'over $iterations iterations',
      );
      expect(
        improvementRatio,
        greaterThanOrEqualTo(0.25),
        reason:
            'expected at least 25% read-model win on timing fixture; '
            'monolithic=$monolithicMicrosµs lazyOW=$lazyOwMicrosµs',
      );
    },
  );

  test(
    'lazy Old World open path is within Production panel peer budget (Refs #4175 Slice E AC1)',
    () {
      const iterations = 50;
      // Production peer surrogate is heavier (stockpile preview + counsel ranking);
      // Development lazy OW path must stay within 2× on the same fixture.
      const peerFactor = 2.0;
      final productionPeerMicros = timeMicros(
        runProductionPanelOpenPathSurrogate,
        iterations: iterations,
      );
      final lazyOwMicros = timeMicros(
        runDevelopmentLazyOldWorldOpenPath,
        iterations: iterations,
      );

      expect(
        lazyOwMicros,
        lessThanOrEqualTo((productionPeerMicros * peerFactor).round()),
        reason:
            'development lazyOW=$lazyOwMicrosµs productionPeer=$productionPeerMicrosµs '
            '(${peerFactor}x budget=${(productionPeerMicros * peerFactor).round()}µs) '
            'over $iterations iterations',
      );
    },
  );

  test(
    'buildDevelopmentPanelBuildContextFromConnectivity reuses connectivity map (Refs #4175 Slice E)',
    () {
      final connectivity = resolveDevelopmentPanelConnectivity(
        game: game,
        tileMapByRegion: tileMapByRegion,
        topology: topology,
      );
      final beforeOrders = buildDevelopmentPanelBuildContextFromConnectivity(
        connectivity: connectivity,
        game: game,
        playerId: playerId,
        currentOrders: orders,
      );
      final afterOrders = buildDevelopmentPanelBuildContextFromConnectivity(
        connectivity: connectivity,
        game: game,
        playerId: playerId,
        currentOrders: Orders(
          workOrdersByPlayerId: {
            playerId: const [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetBuildImprovement,
                targetTileKey: 'oldWorld|p1|0|0',
              ),
            ],
          },
        ),
      );

      expect(
        identical(beforeOrders.connectedTileKeys, afterOrders.connectedTileKeys),
        isTrue,
      );
      expect(
        identical(beforeOrders.playerConnectivity, afterOrders.playerConnectivity),
        isTrue,
      );
      expect(beforeOrders.ownerCache, equals(afterOrders.ownerCache));
    },
  );

  test(
    'composeDevelopmentPanelRegionModel reuses scopes across draft-order churn (Refs #4175 Slice E)',
    () {
      final unit = Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final scopedGame = TestFixtures.oldWorldGameWithUnit(unit: unit);
      final scopedTileMapByRegion = {
        kRegionOldWorld: tileMapByRegion[kRegionOldWorld]!,
      };
      final scopedConnectivity = resolveDevelopmentPanelConnectivity(
        game: scopedGame,
        tileMapByRegion: scopedTileMapByRegion,
        topology: topology,
      );
      final scopes = buildDevelopmentPanelRegionScopesForPlayer(
        game: scopedGame,
        playerId: playerId,
        regionId: kRegionOldWorld,
        tileMapByRegion: scopedTileMapByRegion,
        provinceDisplayNamesById: provinceDisplayNamesById,
        playerDisplayNamesById: playerDisplayNamesById,
        connectivityByPlayer: scopedConnectivity,
      );
      const emptyOrders = Orders();
      final pendingOrders = Orders(
        workOrdersByPlayerId: {
          playerId: const [
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );
      final sharedEmpty = buildDevelopmentPanelBuildContextFromConnectivity(
        connectivity: scopedConnectivity,
        game: scopedGame,
        playerId: playerId,
        currentOrders: emptyOrders,
      );
      final sharedPending = buildDevelopmentPanelBuildContextFromConnectivity(
        connectivity: scopedConnectivity,
        game: scopedGame,
        playerId: playerId,
        currentOrders: pendingOrders,
      );
      final composedEmpty = composeDevelopmentPanelRegionModel(
        scopes: scopes,
        shared: sharedEmpty,
        game: scopedGame,
        playerId: playerId,
        currentOrders: emptyOrders,
      );
      final composedPending = composeDevelopmentPanelRegionModel(
        scopes: scopes,
        shared: sharedPending,
        game: scopedGame,
        playerId: playerId,
        currentOrders: pendingOrders,
      );

      expect(
        identical(composedEmpty.ownedScopes, composedPending.ownedScopes),
        isTrue,
      );
      expect(composedEmpty.idleBuilderCount, 1);
      expect(composedPending.idleBuilderCount, 0);
      expect(composedPending.assignedCivilians, hasLength(1));
    },
  );
}
