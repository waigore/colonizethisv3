// Growth-stage planner Builder relocation / anti-thrash ACs (Refs #3371).
// SPEC/ai/growth-stage-planner.md. Split from growth_stage_planner_test.dart
// to respect the per-file non-comment line budget.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_ai/src/planning/growth_stage_builder_relocation.dart';
import 'package:colonizethis_ai/src/planning/growth_stage_work_priorities.dart';
import 'package:colonizethis_ai/src/planning/move_planner.dart';
import 'package:colonizethis_ai/src/planning/planner_context.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/growth_stage_planner_test_support.dart';
import '../support/planner_test_helpers.dart';

void main() {
  group('growth-stage Builder relocation — AC7 feedstock province', () {
    const ow = 'oldWorld';
    const pGrain = '$ow|p_grain';
    const pWool = '$ow|p_wool';
    const tileGrain = '$pGrain|0|0';
    const tileWool = '$pWool|0|0';

    final twoProvinceTopology = MapTopology(
      nodes: const [
        TopologyNode(
          id: 'p_grain',
          regionId: ow,
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'p_wool',
          regionId: ow,
          type: TopologyNodeType.province,
        ),
      ],
      edges: const [TopologyEdge(id1: 'p_grain', id2: 'p_wool')],
    );

    Game relocationGame() => Game(
      id: 'g-3371-reloc',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(id: pGrain, regionId: ow, ownerId: 'gp1'),
            Province(id: pWool, regionId: ow, ownerId: 'gp1'),
          ],
          units: [
            Unit(
              id: 'b1',
              type: kUnitTypeBuilder,
              ownerId: 'gp1',
              locationProvinceId: pGrain,
              tileKey: tileGrain,
              status: UnitStatus.idle,
            ),
          ],
        ),
        newWorld: const RegionData(),
        resourceByTileKey: const {tileGrain: 'grain', tileWool: 'wool'},
        playerVisibilityByTile: const {
          'gp1': {tileGrain: 'fullyVisible', tileWool: 'fullyVisible'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            pGrain: [tileGrain],
            pWool: [tileWool],
          },
        },
      ),
      players: [
        Player(
          id: 'gp1',
          displayName: 'GP1',
          isHuman: false,
          capitalProvinceId: pGrain,
          stockpile: const Stockpile(),
          workerPool: const WorkerPool(peasants: 4),
        ),
      ],
    );

    test('ownedFabricFeedstockProvinceIdsSorted finds wool province only', () {
      final ids = ownedFabricFeedstockProvinceIdsSorted(
        relocationGame(),
        'gp1',
      );
      expect(ids, [pWool]);
    });

    test(
      'suggestGrowthStageBuilderFeedstockRelocation moves Builder to wool province',
      () {
        final game = relocationGame();
        final view = buildPlayerView(game, twoProvinceTopology, 'gp1');
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
          topology: twoProvinceTopology,
          currentOrders: const Orders(),
          suggestionAPI: const DefaultOrderSuggestionAPI(),
          stage: stage,
          feedstockPreference: pref,
          growthStagePlannerEnabled: true,
        );
        expect(move, isNotNull);
        expect(move!.unitId, 'b1');
        expect(Unit.provinceIdFromTileKey(move.destinationTileKey), pWool);
      },
    );

    test('returns null when Builder already co-located with wool', () {
      final game = relocationGame();
      final ws = game.worldState;
      final relocatedBuilder = ws.oldWorld.units.single.copyWith(
        locationProvinceId: pWool,
        tileKey: tileWool,
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
      final view = buildPlayerView(coLocated, twoProvinceTopology, 'gp1');
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
        topology: twoProvinceTopology,
        currentOrders: const Orders(),
        suggestionAPI: const DefaultOrderSuggestionAPI(),
        stage: stage,
        feedstockPreference: pref,
        growthStagePlannerEnabled: true,
      );
      expect(move, isNull);
    });

    test('orchestrator emits relocation before work (move/work XOR)', () {
      final game = relocationGame();
      final view = buildPlayerView(game, twoProvinceTopology, 'gp1');
      final snapshot = AIWorldSnapshot.fromPlayerView(
        view,
        topology: twoProvinceTopology,
      );
      final outcome = runDomainPlannersWithOutcome(
        game: game,
        topology: twoProvinceTopology,
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

  group('growthStageReservedBuilderUnitIds — AC14 Builder anti-thrash', () {
    const ow = 'oldWorld';
    const pGrain = '$ow|p_grain';
    const pWool = '$ow|p_wool';
    const tileGrain = '$pGrain|0|0';
    const tileWool = '$pWool|0|0';

    final twoProvinceTopology = MapTopology(
      nodes: const [
        TopologyNode(
          id: 'p_grain',
          regionId: ow,
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'p_wool',
          regionId: ow,
          type: TopologyNodeType.province,
        ),
      ],
      edges: const [TopologyEdge(id1: 'p_grain', id2: 'p_wool')],
    );

    // Bootstrap GP: 4 peasants (low labour -> workerGrowthPriority high), zero
    // fabric, an owned unimproved wool tile -> fabric feedstock stage active.
    Game bootstrapGame() => Game(
      id: 'g-3371-ac14',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(id: pGrain, regionId: ow, ownerId: 'gp1'),
            Province(id: pWool, regionId: ow, ownerId: 'gp1'),
          ],
          units: [
            Unit(
              id: 'b1',
              type: kUnitTypeBuilder,
              ownerId: 'gp1',
              locationProvinceId: pGrain,
              tileKey: tileGrain,
              status: UnitStatus.idle,
            ),
          ],
        ),
        newWorld: const RegionData(),
        resourceByTileKey: const {tileGrain: 'grain', tileWool: 'wool'},
        playerVisibilityByTile: const {
          'gp1': {tileGrain: 'fullyVisible', tileWool: 'fullyVisible'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            pGrain: [tileGrain],
            pWool: [tileWool],
          },
        },
      ),
      players: [
        Player(
          id: 'gp1',
          displayName: 'GP1',
          isHuman: false,
          capitalProvinceId: pGrain,
          stockpile: const Stockpile(),
          workerPool: const WorkerPool(peasants: 4),
        ),
      ],
    );

    // Mature GP: high labour and 5 improved timber tiles + fabric reserve full,
    // so both fabric and infrastructure feedstock preferences are inactive.
    Game matureGame() {
      const tiles = [
        '$ow|p0|0|0',
        '$ow|p0|1|0',
        '$ow|p0|2|0',
        '$ow|p0|3|0',
        '$ow|p0|4|0',
      ];
      return Game(
        id: 'g-3371-ac14-mature',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|p0', regionId: ow, ownerId: 'gp1'),
            ],
            units: [
              Unit(
                id: 'b1',
                type: kUnitTypeBuilder,
                ownerId: 'gp1',
                locationProvinceId: '$ow|p0',
                tileKey: tiles.first,
                status: UnitStatus.idle,
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: {for (final t in tiles) t: 'timber'},
          tileState: TileMapState(
            improvementByTile: {for (final t in tiles) t: 1},
          ),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: false,
            capitalProvinceId: '$ow|p0',
            stockpile: const Stockpile().applyDelta(
              CommodityCatalog.fabric.id,
              kReserveTarget,
            ),
            workerPool: const WorkerPool(peasants: 30),
          ),
        ],
      );
    }

    test('positive: bootstrap idle Builder is reserved', () {
      final game = bootstrapGame();
      final view = buildPlayerView(game, twoProvinceTopology, 'gp1');
      final reserved = growthStageReservedBuilderUnitIds(
        game: game,
        view: view,
        playerId: 'gp1',
        growthStagePlannerEnabled: true,
      );
      expect(reserved, contains('b1'));
    });

    test('negative: flag off returns empty', () {
      final game = bootstrapGame();
      final view = buildPlayerView(game, twoProvinceTopology, 'gp1');
      final reserved = growthStageReservedBuilderUnitIds(
        game: game,
        view: view,
        playerId: 'gp1',
        growthStagePlannerEnabled: false,
      );
      expect(reserved, isEmpty);
    });

    test('negative: mature GP (no feedstock stage) returns empty', () {
      final game = matureGame();
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
        final game = bootstrapGame();
        final view = buildPlayerView(game, twoProvinceTopology, 'gp1');
        final api = FakeOrderSuggestionAPIForDomainPlannerTests(
          work: const [],
          build: const [],
          move: const [MoveOrder(unitId: 'b1', destinationTileKey: tileWool)],
          research: const [],
          navalMove: const [],
          navalMission: const [],
        );
        PlannerContext ctx({required bool enabled}) => PlannerContext(
          nationId: 'gp1',
          view: view,
          game: game,
          topology: twoProvinceTopology,
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
