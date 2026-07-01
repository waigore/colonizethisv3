// Pins the live orchestrator wiring of the Spy civilian-work phase preference
// (Refs #3794 § Spy, AC23/AC24 in the live economy pass).
//
// The contract-level `selectFullAiCivilianWorkOrders` scorer already proves
// that a Spy prefers `steal_tech` outside DEVELOP and `counter_spy` in DEVELOP
// when given the `spyDevelopPhase` flag (see
// `full_ai_civilian_work_spy_scoring_test.dart`). This file guards the *live*
// integration: `_runEconomyDomainPlanners`
// (`domain_planner_orchestrator_economy.dart`) must derive that flag from the
// dispatched `PhasePlanOutcome` via `resolvePhaseEconomyDevelopActive` and pass
// it through (`spyDevelopPhase: developPhase`). A refactor that silently
// dropped that argument would regress the live Spy preference to the
// non-DEVELOP default (`steal_tech` always) without failing any existing
// orchestrator test — the phase-plan injection pin uses no Spy unit, so it
// cannot catch this.
//
// The fixture injects `PhasePlanOutcome.defaultDevelop` /
// `PhasePlanOutcome.defaultExpand` directly (the same deterministic seam used
// by `domain_planner_orchestrator_phase_plan_injection_test.dart`) so the
// active phase — and therefore the expected Spy target — is decided by the
// injected plan, not by fixture drift.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _rivalId = 'gp2';
const String _ow = 'oldWorld';
const String _ownProvince = '$_ow|p1';
const String _rivalCapitalProvince = '$_ow|gp2cap';
const String _spyUnitId = 's1';

// `counter_spy` targets one of the GP's own provinces; `steal_tech` targets the
// rival Great Power's capital province. Both candidates are carried for the
// same idle Spy so the unified Spy pool decides cross-type preference by phase.
const String _counterSpyTile = '$_ownProvince|0|0';
const String _stealTechTile = '$_rivalCapitalProvince|0|0';

Game _scenarioGame() => Game(
  id: 'g-3794-spy-phase-wiring',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 30),
    oldWorld: RegionData(
      provinces: const [
        Province(id: _ownProvince, regionId: _ow, ownerId: _nationId),
        Province(
          id: _rivalCapitalProvince,
          regionId: _ow,
          ownerId: _rivalId,
        ),
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
      _nationId: {
        _counterSpyTile: 'fullyVisible',
        _stealTechTile: 'fullyVisible',
      },
    },
    tileKeysByRegionAndProvince: const {
      _ow: {
        _ownProvince: [_counterSpyTile],
        _rivalCapitalProvince: [_stealTechTile],
      },
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
    Player(
      id: _rivalId,
      displayName: 'GP2',
      isHuman: false,
      leaderKey: 'napoleon',
      capitalProvinceId: _rivalCapitalProvince,
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
    WorkOrder(
      unitId: _spyUnitId,
      target: kWorkTargetStealTech,
      targetTileKey: _stealTechTile,
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
  expect(
    spyWork,
    hasLength(1),
    reason:
        'The orchestrator economy pass must emit exactly one Spy work order '
        'for the idle Spy from the unified Spy pool.',
  );
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
    seeds: AISeedBundle.fromTurnSeed(379400),
    suggestionAPI: _spyWorkApi,
    economyPlan: _economyPlan,
    options: OrchestratorOptions(phasePlan: phasePlan),
  ).orders;
}

void main() {
  group('runDomainPlannersWithOutcome live Spy phase wiring (Refs #3794)', () {
    test(
      'AC24 live: injected DEVELOP plan makes the orchestrator prefer '
      'counter_spy over the alphabetically-later steal_tech',
      () {
        final spyWork = _emittedSpyWork(
          _runWithPhase(PhasePlanOutcome.defaultDevelop),
        );
        expect(
          spyWork.target,
          kWorkTargetCounterSpy,
          reason:
              'Under DEVELOP the orchestrator must pass spyDevelopPhase=true '
              'into selectFullAiCivilianWorkOrders so the Spy prefers '
              'counter_spy. A steal_tech result here means the live '
              'spyDevelopPhase: developPhase wiring was dropped.',
        );
        expect(spyWork.targetTileKey, _counterSpyTile);
      },
    );

    test(
      'AC23 live: injected EXPAND plan makes the orchestrator prefer '
      'steal_tech (non-DEVELOP default)',
      () {
        final spyWork = _emittedSpyWork(
          _runWithPhase(PhasePlanOutcome.defaultExpand),
        );
        expect(
          spyWork.target,
          kWorkTargetStealTech,
          reason:
              'Outside DEVELOP the orchestrator must pass spyDevelopPhase=false '
              'so the Spy prefers steal_tech.',
        );
        expect(spyWork.targetTileKey, _stealTechTile);
      },
    );

    test(
      'determinism: injecting the same DEVELOP plan twice yields the same '
      'emitted Spy work order',
      () {
        final first = _emittedSpyWork(
          _runWithPhase(PhasePlanOutcome.defaultDevelop),
        );
        final second = _emittedSpyWork(
          _runWithPhase(PhasePlanOutcome.defaultDevelop),
        );
        expect(second.target, first.target);
        expect(second.targetTileKey, first.targetTileKey);
      },
    );
  });
}
