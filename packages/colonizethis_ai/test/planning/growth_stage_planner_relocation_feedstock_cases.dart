// AC7 feedstock-province relocation cases for growth_stage_planner_relocation_test.dart.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/growth_stage_builder_relocation.dart';
import 'package:colonizethis_ai/src/planning/growth_stage_work_priorities.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/growth_stage_planner_test_support.dart';
import '../support/planner_test_helpers.dart';

void registerGrowthStagePlannerRelocationFeedstockCases() {
  group('growth-stage Builder relocation — AC7 feedstock province', () {
    test('ownedFabricFeedstockProvinceIdsSorted finds wool province only', () {
      final ids = ownedFabricFeedstockProvinceIdsSorted(
        growthStageRelocationFeedstockGame(),
        'gp1',
      );
      expect(ids, [kGrowthStageRelocationPWool]);
    });

    test(
      'suggestGrowthStageBuilderFeedstockRelocation moves Builder to wool province',
      () {
        final game = growthStageRelocationFeedstockGame();
        final view = buildPlayerView(
          game,
          kGrowthStageRelocationTwoProvinceTopology,
          'gp1',
        );
        final stage = GrowthStage.compute(game, 'gp1');
        final pref = growthStageFeedstockPreference(
          game: game,
          playerId: 'gp1',
          stage: stage,
          growthStagePlannerEnabled: true,
        );
        final move = suggestGrowthStageBuilderFeedstockRelocation(
          game: game,
          view: view,
          topology: kGrowthStageRelocationTwoProvinceTopology,
          currentOrders: const Orders(),
          suggestionAPI: const DefaultOrderSuggestionAPI(),
          stage: stage,
          feedstockPreference: pref,
          growthStagePlannerEnabled: true,
        );
        expect(move, isNotNull);
        expect(move!.unitId, 'b1');
        expect(
          Unit.provinceIdFromTileKey(move.destinationTileKey),
          kGrowthStageRelocationPWool,
        );
      },
    );

    test('returns null when Builder already co-located with wool', () {
      final game = growthStageRelocationFeedstockGame();
      final ws = game.worldState;
      final relocatedBuilder = ws.oldWorld.units.single.copyWith(
        locationProvinceId: kGrowthStageRelocationPWool,
        tileKey: kGrowthStageRelocationTileWool,
      );
      final coLocated = Game(
        id: game.id,
        worldState: WorldState(
          turnState: ws.turnState,
          oldWorld: RegionData(
            provinces: ws.oldWorld.provinces,
            units: [relocatedBuilder],
          ),
          newWorld: ws.newWorld,
          resourceByTileKey: ws.resourceByTileKey,
          playerVisibilityByTile: ws.playerVisibilityByTile,
          tileKeysByRegionAndProvince: ws.tileKeysByRegionAndProvince,
        ),
        players: game.players,
      );
      final view = buildPlayerView(
        coLocated,
        kGrowthStageRelocationTwoProvinceTopology,
        'gp1',
      );
      final stage = GrowthStage.compute(coLocated, 'gp1');
      final pref = growthStageFeedstockPreference(
        game: coLocated,
        playerId: 'gp1',
        stage: stage,
        growthStagePlannerEnabled: true,
      );
      final move = suggestGrowthStageBuilderFeedstockRelocation(
        game: coLocated,
        view: view,
        topology: kGrowthStageRelocationTwoProvinceTopology,
        currentOrders: const Orders(),
        suggestionAPI: const DefaultOrderSuggestionAPI(),
        stage: stage,
        feedstockPreference: pref,
        growthStagePlannerEnabled: true,
      );
      expect(move, isNull);
    });

    test('orchestrator emits relocation before work (move/work XOR)', () {
      final game = growthStageRelocationFeedstockGame();
      final view = buildPlayerView(
        game,
        kGrowthStageRelocationTwoProvinceTopology,
        'gp1',
      );
      final snapshot = AIWorldSnapshot.fromPlayerView(
        view,
        topology: kGrowthStageRelocationTwoProvinceTopology,
      );
      final outcome = runDomainPlannersWithOutcome(
        DomainPlannerInput(
          game: game,
          topology: kGrowthStageRelocationTwoProvinceTopology,
          nationId: 'gp1',
          view: view,
          snapshot: snapshot,
          config: kTestAiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: kTestSeeds,
          suggestionAPI: const DefaultOrderSuggestionAPI(),
          economyPlan: const EconomyPlan(
            productionAssignments: [],
            cargoPreference: CargoPreference.none,
          ),
          options: OrchestratorOptions(growthStagePlannerEnabled: true),
        ),
      );
      final moves = outcome.orders.moveOrdersByPlayerId['gp1'] ?? const [];
      expect(
        moves.where((m) => m.unitId == 'b1'),
        isNotEmpty,
        reason: 'bootstrap Builder should relocate toward wool province',
      );
      final work = outcome.orders.workOrdersByPlayerId['gp1'] ?? const [];
      expect(
        work.where((w) => w.unitId == 'b1'),
        isEmpty,
        reason: 'relocated Builder must not receive work same turn',
      );
    });
  });
}
