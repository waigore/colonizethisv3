// Unit tests for `runConquestArmyMovePlanner` stalled-expansion
// own-territory frontier-march behaviour (Refs #2509 EXPAND). Split out of
// `phase_planner_conquest_wiring_test.dart` to keep each test file at or
// below the repo-lint non-comment line limit (SPEC/program/repo-lint.md).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/conquest_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';

const ExpandMilitaryPlan _expandOwOnly = ExpandMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['oldWorld|minor1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['minor1'],
);

const ColonialMilitaryPlan _colonialNwOnly = ColonialMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe1'],
);

void main() {
  // Refs #2509 § EXPAND § planExpandMilitary stalled-expansion frontier-march
  // contract: under EXPAND (ow < 10) a field army at the capital whose
  // suggestArmyMoveOrders candidates land exclusively on own-territory
  // provinces must still receive a frontier-march army move from the
  // stalled-expansion conquest pass — otherwise the planner emits zero
  // army moves and the capital armies sit at the capital across the entire
  // 100-turn observer run (seed-42 gp1 ow gain = 0 against the +3 gate).
  //
  // Failure mode pinned (pre-fix `_scoreArmyMoveDestination` early-returned
  // `0` for any own-territory destination when
  // `phasePlanInvadableIsAuthoritative=true`; the strict invadable-only
  // `scoringCandidates` prefilter then emptied the list and the planner
  // returned without applying any move).
  group('runConquestArmyMovePlanner stalled-expansion own-territory '
      'frontier-march (Refs #2509 EXPAND)', () {
    test(
      'EXPAND ow<10 with own-territory-only candidates emits a frontier '
      'march to the at-war-minor frontier province',
      () {
        // Topology: own provinces gp1_inner and gp1_frontier; gp1_frontier
        // shares an edge with the at-war minor1_a invadable. The army sits
        // at gp1_inner; its direct neighbors (the suggested destinations
        // below) are own territory only.
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|gp1_inner',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|gp1_frontier',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|gp1_idle',
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
              id1: 'oldWorld|gp1_inner',
              id2: 'oldWorld|gp1_frontier',
            ),
            TopologyEdge(
              id1: 'oldWorld|gp1_inner',
              id2: 'oldWorld|gp1_idle',
            ),
            TopologyEdge(
              id1: 'oldWorld|gp1_frontier',
              id2: 'oldWorld|minor1_a',
            ),
          ],
        );
        final game = Game(
          id: 'g-stalled-frontier-march',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 40,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|gp1_inner',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|gp1_frontier',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|gp1_idle',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
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
                id: 'army_inner',
                ownerId: 'gp1',
                regionId: 'oldWorld',
                stationedProvinceId: 'oldWorld|gp1_inner',
                isHomeArmy: false,
                regimentUnitIds: ['reg1', 'reg2'],
              ),
            ],
          ),
          players: const [
            Player(id: 'gp1', displayName: 'P1', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          aiControlByGpId: const {'gp1': true},
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor1',
              state: RelationState.atWar,
            ),
          ],
        );

        // Suggestion API returns own-territory-only candidates — mirrors the
        // seed-42 gp1 observed behaviour where the capital army produces 12
        // suggestions all landing on gp1-owned provinces, none on the
        // invadable minor1 province.
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
                destinationProvinceId: 'oldWorld|gp1_frontier',
              ),
              ArmyMoveOrder(
                armyId: 'army_inner',
                destinationProvinceId: 'oldWorld|gp1_idle',
              ),
            ],
          ),
        );
        final snapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: const ThreatSummary(atWarWith: ['minor1']),
          opportunities: const OpportunitySummary(),
          // ow=7 -> stalledExpansion = true (below kStalledOldWorldProvinceThreshold)
          conquest: const ConquestSummary(
            oldWorldProvincesOwned: 7,
            invadableProvinceIdsSorted: ['oldWorld|minor1_a'],
            adjacentOwnerFactionIdsSorted: ['minor1'],
          ),
          colonial: const ColonialSummary(),
          economy: const EconomySummary(),
          relations: const {},
        );
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          expandMilitaryPlan: _expandOwOnly,
        );

        final orders = runConquestArmyMovePlanner(
          ctx: ctx,
          snapshot: snapshot,
          declaredWarTargetFactionId: 'minor1',
          phasePlan: phasePlan,
        );

        final moves = orders.armyMoveOrdersByPlayerId['gp1'] ?? const [];
        expect(
          moves,
          hasLength(1),
          reason:
              'Stalled-expansion EXPAND with own-territory-only candidates '
              'must still emit one army move (frontier-march) — pre-fix '
              'returned zero moves and the army parked at capital.',
        );
        expect(
          moves.single.destinationProvinceId,
          'oldWorld|gp1_frontier',
          reason:
              'Frontier-march scoring (`_stalledExpansionArmyMoveScoreDelta` '
              '→ `_isOnAtWarMinorOrTribeFrontier` + '
              '`kConquestArmyMoveAdjacentAtWarFrontierBonus`) must prefer '
              'gp1_frontier (adjacent to at-war minor1) over gp1_idle.',
        );
      },
    );

    test(
      'EXPAND ow<10 keeps own-territory frontier-march even when no direct '
      'invadable neighbour exists for any field army',
      () {
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'oldWorld|gp1_capital',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'oldWorld|gp1_frontier',
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
              id1: 'oldWorld|gp1_capital',
              id2: 'oldWorld|gp1_frontier',
            ),
            TopologyEdge(
              id1: 'oldWorld|gp1_frontier',
              id2: 'oldWorld|minor1_a',
            ),
          ],
        );
        final game = Game(
          id: 'g-stalled-frontier-no-direct',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 40,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|gp1_capital',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|gp1_frontier',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
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
                id: 'army_cap',
                ownerId: 'gp1',
                regionId: 'oldWorld',
                stationedProvinceId: 'oldWorld|gp1_capital',
                isHomeArmy: false,
                regimentUnitIds: ['reg1'],
              ),
            ],
          ),
          players: const [
            Player(id: 'gp1', displayName: 'P1', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          aiControlByGpId: const {'gp1': true},
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor1',
              state: RelationState.atWar,
            ),
          ],
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
                armyId: 'army_cap',
                destinationProvinceId: 'oldWorld|gp1_frontier',
              ),
            ],
          ),
        );
        final snapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: const ThreatSummary(atWarWith: ['minor1']),
          opportunities: const OpportunitySummary(),
          conquest: const ConquestSummary(
            oldWorldProvincesOwned: 7,
            invadableProvinceIdsSorted: ['oldWorld|minor1_a'],
            adjacentOwnerFactionIdsSorted: ['minor1'],
          ),
          colonial: const ColonialSummary(),
          economy: const EconomySummary(),
          relations: const {},
        );
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          expandMilitaryPlan: _expandOwOnly,
        );

        final orders = runConquestArmyMovePlanner(
          ctx: ctx,
          snapshot: snapshot,
          declaredWarTargetFactionId: 'minor1',
          phasePlan: phasePlan,
        );

        final moves = orders.armyMoveOrdersByPlayerId['gp1'] ?? const [];
        expect(moves, hasLength(1));
        expect(moves.single.destinationProvinceId, 'oldWorld|gp1_frontier');
      },
    );

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
          colonialMilitaryPlan: _colonialNwOnly,
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

  // Refs #2847 § H4-b — geographic peer-war lock minor-transit frontier march.
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
