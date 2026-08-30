// AC14 Builder anti-thrash cases for growth_stage_planner_relocation_test.dart.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/growth_stage_builder_relocation.dart';
import 'package:colonizethis_ai/src/planning/move_planner.dart';
import 'package:colonizethis_ai/src/planning/planner_context.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/growth_stage_planner_test_support.dart';
import '../support/planner_test_helpers.dart';

void registerGrowthStagePlannerRelocationAntiThrashCases() {
  group('growthStageReservedBuilderUnitIds — AC14 Builder anti-thrash', () {
    test('positive: bootstrap idle Builder is reserved', () {
      final game = growthStageReservedBootstrapGame();
      final view = buildPlayerView(
        game,
        kGrowthStageRelocationTwoProvinceTopology,
        'gp1',
      );
      final reserved = growthStageReservedBuilderUnitIds(
        game: game,
        view: view,
        playerId: 'gp1',
        growthStagePlannerEnabled: true,
      );
      expect(reserved, contains('b1'));
    });

    test('negative: flag off returns empty', () {
      final game = growthStageReservedBootstrapGame();
      final view = buildPlayerView(
        game,
        kGrowthStageRelocationTwoProvinceTopology,
        'gp1',
      );
      final reserved = growthStageReservedBuilderUnitIds(
        game: game,
        view: view,
        playerId: 'gp1',
        growthStagePlannerEnabled: false,
      );
      expect(reserved, isEmpty);
    });

    test('negative: mature GP (no feedstock stage) returns empty', () {
      final game = growthStageReservedMatureGame();
      final view = buildPlayerView(
        game,
        const MapTopology(nodes: [], edges: []),
        'gp1',
      );
      final reserved = growthStageReservedBuilderUnitIds(
        game: game,
        view: view,
        playerId: 'gp1',
        growthStagePlannerEnabled: true,
      );
      expect(reserved, isEmpty);
    });

    test(
      'runMovePlanner suppresses reserved Builder move when flag on; '
      'emits it when flag off',
      () {
        final game = growthStageReservedBootstrapGame();
        final view = buildPlayerView(
          game,
          kGrowthStageRelocationTwoProvinceTopology,
          'gp1',
        );
        final api = FakeOrderSuggestionAPIForDomainPlannerTests(
          work: const [],
          build: const [],
          move: const [
            MoveOrder(
              unitId: 'b1',
              destinationTileKey: kGrowthStageRelocationTileWool,
            ),
          ],
          research: const [],
          navalMove: const [],
          navalMission: const [],
        );
        PlannerContext ctx({required bool enabled}) => PlannerContext(
          nationId: 'gp1',
          view: view,
          game: game,
          topology: kGrowthStageRelocationTwoProvinceTopology,
          orders: const Orders(),
          config: kTestAiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: kTestSeeds,
          suggestionAPI: api,
          growthStagePlannerEnabled: enabled,
        );

        final ordersOn = runMovePlanner(ctx: ctx(enabled: true));
        expect(
          ordersOn.moveOrdersByPlayerId['gp1'] ?? const <MoveOrder>[],
          isEmpty,
          reason: 'reserved bootstrap Builder must not get a generic move',
        );

        final ordersOff = runMovePlanner(ctx: ctx(enabled: false));
        expect(
          (ordersOff.moveOrdersByPlayerId['gp1'] ?? const <MoveOrder>[])
              .map((m) => m.unitId),
          contains('b1'),
          reason: 'flag off: generic move planner relocates Builder as before',
        );
      },
    );
  });
}
