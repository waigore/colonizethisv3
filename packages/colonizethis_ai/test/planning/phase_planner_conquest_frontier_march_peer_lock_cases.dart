// Case bodies for `phase_planner_conquest_frontier_march_test.dart` (Refs #4079 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/conquest_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';

void registerPhasePlannerConquestFrontierMarchPeerLockCases() {
  group('runConquestArmyMovePlanner geographic peer-lock minor transit '
      '(Refs #2847 H4-b)', () {
    test(
      'prefers peer province adjacent to at-war minor over peer interior '
      'without minor reach',
      () {
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|gp4_own',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|gp3_gateway',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|gp3_interior',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|minor1_a',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [
            TopologyEdge(
              id1: 'oldWorld|gp4_own',
              id2: 'oldWorld|gp3_gateway',
            ),
            TopologyEdge(
              id1: 'oldWorld|gp3_gateway',
              id2: 'oldWorld|minor1_a',
            ),
            TopologyEdge(
              id1: 'oldWorld|gp3_gateway',
              id2: 'oldWorld|gp3_interior',
            ),
          ],
        );
        final game = Game(
          id: 'g-h4b-transit-prefer',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 40,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|gp4_own',
                  regionId: 'oldWorld',
                  ownerId: 'gp4',
                ),
                Province(
                  id: 'oldWorld|gp3_gateway',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
                Province(
                  id: 'oldWorld|gp3_interior',
                  regionId: 'oldWorld',
                  ownerId: 'gp3',
                ),
                Province(
                  id: 'oldWorld|minor1_a',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: const [
              Army(
                id: 'army_gp4',
                ownerId: 'gp4',
                regionId: 'oldWorld',
                stationedProvinceId: 'oldWorld|gp4_own',
                isHomeArmy: false,
                regimentUnitIds: ['reg1'],
              ),
            ],
          ),
          players: const [
            Player(id: 'gp3', displayName: 'P3', isHuman: false),
            Player(id: 'gp4', displayName: 'P4', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          aiControlByGpId: const {'gp4': true},
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp4',
              factionId2: 'gp3',
              state: RelationState.atWar,
            ),
            DiplomacyRelation(
              factionId1: 'gp4',
              factionId2: 'minor1',
              state: RelationState.atWar,
            ),
          ],
        );
        final ctx = buildTestPlannerContext(
          game: game,
          topology: topology,
          nationId: 'gp4',
          primaryGoal: StrategicGoal.conquer,
          suggestionAPI: const FakeOrderSuggestionAPIForDomainPlannerTests(
            work: [],
            build: [],
            move: [],
            research: [],
            navalMove: [],
            navalMission: [],
            diplomatic: [],
            armyMove: [
              ArmyMoveOrder(
                armyId: 'army_gp4',
                destinationProvinceId: 'oldWorld|gp3_interior',
              ),
              ArmyMoveOrder(
                armyId: 'army_gp4',
                destinationProvinceId: 'oldWorld|gp3_gateway',
              ),
            ],
          ),
        );
        final snapshot = AIWorldSnapshot(
          playerId: 'gp4',
          threats: const ThreatSummary(atWarWith: ['gp3', 'minor1']),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(
            oldWorldProvincesOwned: 1,
            invadableProvinceIdsSorted: [
              'oldWorld|gp3_gateway',
              'oldWorld|gp3_interior',
            ],
            adjacentOwnerFactionIdsSorted: ['gp3'],
          ),
          colonial: const ColonialSummary(),
          economy: const EconomySummary(),
          relations: const {},
        );
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          expandMilitaryPlan: ExpandMilitaryPlan(
            priorityDestinationProvinceIdsSorted: [
              'oldWorld|gp3_gateway',
              'oldWorld|gp3_interior',
            ],
            priorityTargetOwnerFactionIdsSorted: ['gp3'],
          ),
        );

        final orders = runConquestArmyMovePlanner(
          ctx: ctx,
          snapshot: snapshot,
          declaredWarTargetFactionId: 'gp3',
          phasePlan: phasePlan,
        );

        final moves = orders.armyMoveOrdersByPlayerId['gp4'] ?? const [];
        expect(moves, hasLength(1));
        expect(
          moves.single.destinationProvinceId,
          'oldWorld|gp3_gateway',
          reason:
              'Under geographic peer-war lock the gateway peer province '
              'adjacent to an at-war minor must beat the peer interior '
              'that only deepens the zero-sum GP war.',
        );
      },
    );

  });
}
