import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/lock_recovery_seller_test_support.dart';
import '../support/planner_test_helpers.dart';

void main() {
  group('H8-extraction orchestrator civilian-work force-on (Refs #2847)', () {
    final threshold = cheapestRegimentBuildTreasuryCost();
    const topology = MapTopology(nodes: [], edges: []);
    const woolImprovement = WorkOrder(
      unitId: 'b1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: kH8FeedstockLockRecoveryWoolTile,
    );
    const grainImprovement = WorkOrder(
      unitId: 'b1',
      target: kWorkTargetBuildImprovement,
      targetTileKey: kH8FeedstockLockRecoveryGrainTile,
    );

    test(
      'selects wool improvement under conquer goal when feedstock gate is active',
      () {
        final game = buildH8FeedstockLockRecoverySellerGame(treasury: threshold);
        final view = buildPlayerView(game, topology, kH8FeedstockLockRecoverySellerId);
        final snapshot = AIWorldSnapshot.fromPlayerView(
          view,
          topology: topology,
        );
        final outcome = runDomainPlannersWithOutcome(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kH8FeedstockLockRecoverySellerId,
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
          ),
        );

        expect(outcome.domainGateData?.workPlannerRan, isTrue);
        final work = outcome.orders.workOrdersByPlayerId[kH8FeedstockLockRecoverySellerId];
        expect(work, isNotNull);
        expect(work!.single.targetTileKey, kH8FeedstockLockRecoveryWoolTile);
      },
    );

    test(
      'treasury-independent: selects wool improvement even when broke',
      () {
        // Refs #2847 H8-extraction: the feedstock-extraction gate is
        // treasury-independent, so a broke below-quota seller is still routed
        // onto the wool feedstock tile (the input stages ahead of treasury
        // recovery; the market bids and build order stay treasury-gated).
        final game = buildH8FeedstockLockRecoverySellerGame(treasury: 0);
        final view = buildPlayerView(game, topology, kH8FeedstockLockRecoverySellerId);
        final snapshot = AIWorldSnapshot.fromPlayerView(
          view,
          topology: topology,
        );
        final outcome = runDomainPlannersWithOutcome(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kH8FeedstockLockRecoverySellerId,
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
          ),
        );

        expect(outcome.domainGateData?.workPlannerRan, isTrue);
        final work = outcome.orders.workOrdersByPlayerId[kH8FeedstockLockRecoverySellerId];
        expect(work, isNotNull);
        expect(work!.single.targetTileKey, kH8FeedstockLockRecoveryWoolTile);
      },
    );
  });
}
