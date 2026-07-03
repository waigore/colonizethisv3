// Pins live orchestrator Spy civilian-work wiring (Refs #3834 R11).

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _ow = 'oldWorld';
const String _ownProvince = '$_ow|p1';
const String _spyUnitId = 's1';
const String _counterSpyTile = '$_ownProvince|0|0';

Game _scenarioGame() => Game(
  id: 'g-3834-spy-phase-wiring',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 30),
    oldWorld: RegionData(
      provinces: const [
        Province(id: _ownProvince, regionId: _ow, ownerId: _nationId),
      ],
      units: [
        Unit(
          id: _spyUnitId,
          type: kUnitTypeSpy,
          ownerId: _nationId,
          locationProvinceId: _ownProvince,
          tileKey: _counterSpyTile,
        ),
      ],
    ),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {
      _nationId: {_counterSpyTile: 'fullyVisible'},
    },
    tileKeysByRegionAndProvince: const {
      _ow: {_ownProvince: [_counterSpyTile]},
    },
  ),
  players: const [
    Player(
      id: _nationId,
      displayName: 'GP1',
      isHuman: false,
      leaderKey: 'victoria',
      capitalProvinceId: _ownProvince,
    ),
  ],
);

const FakeOrderSuggestionAPIForDomainPlannerTests _spyWorkApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [
    WorkOrder(
      unitId: _spyUnitId,
      target: kWorkTargetCounterSpy,
      targetTileKey: _counterSpyTile,
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
  final spyWork = work.where((w) => w.unitId == _spyUnitId).toList();
  expect(spyWork, hasLength(1));
  return spyWork.single;
}

Orders _runWithPhase(PhasePlanOutcome phasePlan) {
  final game = _scenarioGame();
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
      expect(spyWork.targetTileKey, _counterSpyTile);
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
