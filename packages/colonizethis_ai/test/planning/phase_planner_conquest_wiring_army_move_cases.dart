// Case bodies for `phase_planner_conquest_wiring_test.dart` (Refs #3997 Phase 8).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/conquest_planner.dart';
import 'package:colonizethis_ai/src/planning/planner_context.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';
import 'phase_planner_conquest_wiring_support.dart';

void registerPhasePlannerConquestWiringArmyMoveCases() {
group('runConquestArmyMovePlanner phase military wiring', () {
    late Game game;
    late PlannerContext ctx;
    late AIWorldSnapshot snapshot;

    setUp(() {
      game = Game(
        id: 'g-phase-conquest-wiring',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|gp1_1',
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
          newWorld: RegionData(
            provinces: [
              Province(
                id: 'newWorld|tribe1_a',
                regionId: 'newWorld',
                ownerId: 'tribe1',
              ),
            ],
          ),
          armies: const [
            Army(
              id: 'army1',
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|gp1_1',
              isHomeArmy: false,
              regimentUnitIds: ['reg1'],
            ),
          ],
        ),
        players: const [Player(id: 'gp1', displayName: 'P1', isHuman: false)],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        aiControlByGpId: const {'gp1': true},
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atWar,
          ),
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'tribe1',
            state: RelationState.atWar,
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      ctx = buildTestPlannerContext(
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
              armyId: 'army1',
              destinationProvinceId: 'oldWorld|minor1_a',
            ),
            ArmyMoveOrder(
              armyId: 'army1',
              destinationProvinceId: 'newWorld|tribe1_a',
            ),
          ],
        ),
      );
      snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: const ThreatSummary(atWarWith: ['minor1', 'tribe1']),
        opportunities: const OpportunitySummary(),
        conquest: const ConquestSummary(
          oldWorldProvincesOwned: 3,
          invadableProvinceIdsSorted: ['oldWorld|minor1_a'],
        ),
        colonial: const ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|tribe1_a'],
        ),
        economy: const EconomySummary(),
        relations: const {},
      );
    });

    test('EXPAND phase plan chooses OW destination over NW candidate', () {
      const phasePlan = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandMilitaryPlan: kConquestWiringExpandOwOnly,
      );
      final orders = runConquestArmyMovePlanner(
        ctx: ctx,
        snapshot: snapshot,
        declaredWarTargetFactionId: 'minor1',
        phasePlan: phasePlan,
      );
      final moves = orders.armyMoveOrdersByPlayerId['gp1'] ?? const [];
      expect(moves, hasLength(1));
      expect(moves.single.destinationProvinceId, 'oldWorld|minor1_a');
    });

    test('COLONIAL phase plan chooses NW destination over OW candidate', () {
      const phasePlan = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialMilitaryPlan: kConquestWiringColonialNwOnly,
      );
      final orders = runConquestArmyMovePlanner(
        ctx: ctx,
        snapshot: snapshot,
        declaredWarTargetFactionId: 'tribe1',
        phasePlan: phasePlan,
      );
      final moves = orders.armyMoveOrdersByPlayerId['gp1'] ?? const [];
      expect(moves, hasLength(1));
      expect(moves.single.destinationProvinceId, 'newWorld|tribe1_a');
    });

    test('DEVELOP phase plan emits no conquest army moves', () {
      const phasePlan = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      final orders = runConquestArmyMovePlanner(
        ctx: ctx,
        snapshot: snapshot,
        phasePlan: phasePlan,
      );
      expect(orders.armyMoveOrdersByPlayerId['gp1'], isNull);
    });

    test('null phase plan preserves legacy invadable union behaviour', () {
      final orders = runConquestArmyMovePlanner(
        ctx: ctx,
        snapshot: snapshot,
        declaredWarTargetFactionId: 'minor1',
      );
      final moves = orders.armyMoveOrdersByPlayerId['gp1'] ?? const [];
      expect(moves, hasLength(1));
      expect(
        moves.single.destinationProvinceId,
        anyOf('oldWorld|minor1_a', 'newWorld|tribe1_a'),
      );
    });
  });
}
