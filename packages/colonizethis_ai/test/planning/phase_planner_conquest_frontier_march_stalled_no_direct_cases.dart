// Case bodies for `phase_planner_conquest_frontier_march_test.dart` (Refs #4079 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/conquest_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';
import 'phase_planner_conquest_frontier_march_support.dart';

void registerPhasePlannerConquestFrontierMarchStalledNoDirectCases() {
  group('runConquestArmyMovePlanner stalled-expansion own-territory '
      'frontier-march (Refs #2509 EXPAND)', () {
    test(
      'COLONIAL (at-quota) keeps strict invadable-only prefilter — '
      'own-territory candidates do not produce DEVELOP-side army moves',
      () {
        // At-quota GP (ow=12) is NOT stalled-expansion, so the strict
        // invadable prefilter still applies — the stalled-expansion
        // own-territory allowance must NOT leak into COLONIAL routing.
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|gp1_inner',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|gp1_idle',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [
            TopologyEdge(
              id1: 'oldWorld|gp1_inner',
              id2: 'oldWorld|gp1_idle',
            ),
          ],
        );
        final game = Game(
          id: 'g-at-quota-no-own-march',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 80,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|gp1_inner',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|gp1_idle',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: const [
              Army(
                id: 'army_inner',
                ownerId: 'gp1',
                regionId: 'oldWorld',
                stationedProvinceId: 'oldWorld|gp1_inner',
                isHomeArmy: false,
                regimentUnitIds: ['reg1'],
              ),
            ],
          ),
          players: const [
            Player(id: 'gp1', displayName: 'P1', isHuman: false),
          ],
          tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
          aiControlByGpId: const {'gp1': true},
        );
        final ctx = buildTestPlannerContext(
          game: game,
          topology: topology,
          nationId: 'gp1',
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
                armyId: 'army_inner',
                destinationProvinceId: 'oldWorld|gp1_idle',
              ),
            ],
          ),
        );
        final snapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: const ThreatSummary(),
          opportunities: const OpportunitySummary(),
          // At-quota: ow=12 -> NOT stalled-expansion
          conquest: const ConquestSummary(oldWorldProvincesOwned: 12),
          colonial: const ColonialSummary(),
          economy: const EconomySummary(),
          relations: const {},
        );
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonial,
          colonialMilitaryPlan: kFrontierMarchColonialNwOnly,
        );

        final orders = runConquestArmyMovePlanner(
          ctx: ctx,
          snapshot: snapshot,
          phasePlan: phasePlan,
        );
        expect(
          orders.armyMoveOrdersByPlayerId['gp1'],
          isNull,
          reason:
              'At-quota COLONIAL must still apply the strict invadable-only '
              'prefilter — own-territory candidates do not score and no '
              'army move is emitted (regression guard for the EXPAND-only '
              'frontier-march allowance).',
        );
      },
    );
  });
}
