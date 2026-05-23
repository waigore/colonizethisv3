// Diplomacy orchestrator wiring for phase-planner declare-war targets (Refs #2509 S5).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/planner_context.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../domain_planner_test_fake_api.dart';
import '../planner_test_helpers.dart';

void main() {
  group('runDiplomacyPlannerWithResult phase declare-war wiring', () {
    late Game game;
    late PlannerContext ctx;
    late AIWorldSnapshot snapshot;

    setUp(() {
      game = Game(
        id: 'g-phase-declare-war-wiring',
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
                id: 'oldWorld|minor1_1',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
        aiControlByGpId: const {'gp1': true},
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
        ),
      );
      snapshot = const AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 3),
        economy: EconomySummary(),
        relations: {},
      );
    });

    test('EXPAND phase plan forces declareWar on expand target', () {
      const phasePlan = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandDeclareWarTargetFactionId: 'minor1',
      );
      final result = runDiplomacyPlannerWithResult(
        ctx: ctx,
        snapshot: snapshot,
        pass: DiplomacyPlannerPass.declareWarOnly,
        phasePlan: phasePlan,
      );
      expect(result.declaredWarTargetFactionId, 'minor1');
      final orders = result.orders.diplomaticOrdersByPlayerId['gp1'] ?? const [];
      expect(
        orders.single.type,
        DiplomaticOrderType.declareWar,
      );
      expect(orders.single.targetFactionId, 'minor1');
    });

    test('COLONIAL phase plan forces declareWar on colonial acquisition target', () {
      const phasePlan = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialAcquisitionTarget: ColonialAcquisitionTarget(
          targetFactionId: 'tribe1',
          method: AcquisitionMethod.declareWar,
        ),
      );
      final result = runDiplomacyPlannerWithResult(
        ctx: ctx,
        snapshot: snapshot,
        pass: DiplomacyPlannerPass.declareWarOnly,
        phasePlan: phasePlan,
      );
      expect(result.declaredWarTargetFactionId, 'tribe1');
    });

    test(
      'phase plan with null declare targets skips legacy forced declare paths',
      () {
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
        );
        final result = runDiplomacyPlannerWithResult(
          ctx: ctx,
          snapshot: snapshot,
          pass: DiplomacyPlannerPass.declareWarOnly,
          phasePlan: phasePlan,
        );
        expect(result.declaredWarTargetFactionId, isNull);
        expect(
          result.orders.diplomaticOrdersByPlayerId['gp1'],
          isNull,
        );
      },
    );

    test('null phase plan still uses legacy below-quota minor declare path', () {
      const stalledSnapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 7,
          invadableProvinceIdsSorted: ['oldWorld|minor1_1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      final result = runDiplomacyPlannerWithResult(
        ctx: ctx,
        snapshot: stalledSnapshot,
        pass: DiplomacyPlannerPass.declareWarOnly,
      );
      expect(result.declaredWarTargetFactionId, 'minor1');
    });
  });
}
