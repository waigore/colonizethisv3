// Pins live orchestrator Spy civilian-work wiring (Refs #3834 R11).

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String _nationId = kOrchestratorGp1NationId;

const FakeOrderSuggestionAPIForDomainPlannerTests _spyWorkApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [
    WorkOrder(
      unitId: kOrchestratorSpyUnitId,
      target: kWorkTargetCounterSpy,
      targetTileKey: kOrchestratorSpyCounterSpyTile,
    ),
  ],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
);

const EconomyPlan _economyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig _aiConfig = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'peacemaker',
);

WorkOrder _emittedSpyWork(Orders orders) {
  final work = orders.workOrdersByPlayerId[_nationId] ?? const <WorkOrder>[];
  final spyWork = work.where((w) => w.unitId == kOrchestratorSpyUnitId).toList();
  expect(spyWork, hasLength(1));
  return spyWork.single;
}

Orders _runWithPhase(PhasePlanOutcome phasePlan) {
  final game = buildOrchestratorSpyPhaseWiringScenarioGame(
    id: 'g-3834-spy-phase-wiring',
  );
  const topology = MapTopology(nodes: [], edges: []);
  final view = buildPlayerView(game, topology, _nationId);
  final snapshot = AIWorldSnapshot.fromPlayerView(view);
  return runDomainPlannersWithOutcome(
    game: game,
    topology: topology,
    nationId: _nationId,
    view: view,
    snapshot: snapshot,
    config: _aiConfig,
    primaryGoal: StrategicGoal.expand,
    seeds: AISeedBundle.fromTurnSeed(383400),
    suggestionAPI: _spyWorkApi,
    economyPlan: _economyPlan,
    options: OrchestratorOptions(phasePlan: phasePlan),
  ).orders;
}

void main() {
  group('runDomainPlannersWithOutcome live Spy wiring (Refs #3834)', () {
    test('DEVELOP plan emits counter_spy for idle Spy', () {
      final spyWork = _emittedSpyWork(
        _runWithPhase(PhasePlanOutcome.defaultDevelop),
      );
      expect(spyWork.target, kWorkTargetCounterSpy);
      expect(spyWork.targetTileKey, kOrchestratorSpyCounterSpyTile);
    });

    test('determinism: same DEVELOP plan yields same Spy work order', () {
      final first = _emittedSpyWork(
        _runWithPhase(PhasePlanOutcome.defaultDevelop),
      );
      final second = _emittedSpyWork(
        _runWithPhase(PhasePlanOutcome.defaultDevelop),
      );
      expect(second.target, first.target);
      expect(second.targetTileKey, first.targetTileKey);
    });
  });
}
