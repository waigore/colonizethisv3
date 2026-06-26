import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../domain_planner_test_fake_api.dart';
import '../planner_test_helpers.dart';

const _nationId = 'gp_seller';
const _tileGrain = 'oldWorld|p0|0|0';
const _tileWool = 'oldWorld|p0|1|0';

Game _lockRecoverySellerGame({required int treasury}) {
  return Game(
    id: 'g-h8-extraction-orchestrator',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 30),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < 5; i++)
            Province(
              id: 'oldWorld|p$i',
              regionId: kRegionOldWorld,
              ownerId: _nationId,
            ),
        ],
        units: [
          Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
            ownerId: _nationId,
            locationProvinceId: 'oldWorld|p0',
          ),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {_tileGrain: 'grain', _tileWool: 'wool'},
      playerVisibilityByTile: const {
        _nationId: {_tileGrain: 'fullyVisible', _tileWool: 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: const {
        kRegionOldWorld: {
          'oldWorld|p0': [_tileGrain, _tileWool],
        },
      },
    ),
    players: [
      Player(
        id: _nationId,
        displayName: 'Seller',
        isHuman: false,
        leaderKey: 'napoleon',
        treasury: treasury,
      ),
    ],
  );
}

void main() {
  group('H8-extraction orchestrator civilian-work force-on (Refs #2847)', () {
    final threshold = cheapestRegimentBuildTreasuryCost();
    const topology = MapTopology(nodes: [], edges: []);
    const woolImprovement = WorkOrder(
      unitId: 'b1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: _tileWool,
    );
    const grainImprovement = WorkOrder(
      unitId: 'b1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: _tileGrain,
    );

    test(
      'selects wool improvement under conquer goal when feedstock gate is active',
      () {
        final game = _lockRecoverySellerGame(treasury: threshold);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = AIWorldSnapshot.fromPlayerView(
          view,
          topology: topology,
        );
        final outcome = runDomainPlannersWithOutcome(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: const AIConfig(
            leaderId: 'napoleon',
            personalityId: 'napoleon',
            hiddenAgendaId: 'peacemaker',
          ),
          primaryGoal: StrategicGoal.conquer,
          seeds: AISeedBundle.fromTurnSeed(284701),
          suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
            work: [grainImprovement, woolImprovement],
            build: [],
            move: [],
            research: [],
            navalMove: [],
            navalMission: [],
          ),
          economyPlan: kTestEconomyPlan,
        );

        expect(outcome.domainGateData?.workPlannerRan, isTrue);
        final work = outcome.orders.workOrdersByPlayerId[_nationId];
        expect(work, isNotNull);
        expect(work!.single.targetTileKey, _tileWool);
      },
    );

    test(
      'treasury-independent: selects wool improvement even when broke',
      () {
        // Refs #2847 H8-extraction: the feedstock-extraction gate is
        // treasury-independent, so a broke below-quota seller is still routed
        // onto the wool feedstock tile (the input stages ahead of treasury
        // recovery; the market bids and build order stay treasury-gated).
        final game = _lockRecoverySellerGame(treasury: 0);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = AIWorldSnapshot.fromPlayerView(
          view,
          topology: topology,
        );
        final outcome = runDomainPlannersWithOutcome(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: const AIConfig(
            leaderId: 'napoleon',
            personalityId: 'napoleon',
            hiddenAgendaId: 'peacemaker',
          ),
          primaryGoal: StrategicGoal.conquer,
          seeds: AISeedBundle.fromTurnSeed(284701),
          suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
            work: [grainImprovement, woolImprovement],
            build: [],
            move: [],
            research: [],
            navalMove: [],
            navalMission: [],
          ),
          economyPlan: kTestEconomyPlan,
        );

        expect(outcome.domainGateData?.workPlannerRan, isTrue);
        final work = outcome.orders.workOrdersByPlayerId[_nationId];
        expect(work, isNotNull);
        expect(work!.single.targetTileKey, _tileWool);
      },
    );
  });
}
