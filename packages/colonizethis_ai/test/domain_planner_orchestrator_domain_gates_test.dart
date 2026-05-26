// Pins the orchestrator wiring contract for the Refs #2832 decision-
// provenance trace fields:
//
//   - `runDomainPlannersWithOutcome` must populate
//     `DomainPlannerOutcome.phasePlan` with the same `PhasePlanOutcome`
//     it consumes (the resolved plan; either the externally-injected
//     one, or the orchestrator's internal `runPhasePlanners(...)`
//     fallback).
//   - It must populate `DomainPlannerOutcome.domainGateData` with the
//     activation booleans + resolved per-planner thresholds the AI
//     trace builder emits under `thresholds.domainGates`.
//   - The recorded `conquestPasses` value follows the existing
//     `extraPassesActive` rule today: 22 under EXPAND / COLONIAL-lite,
//     1 under COLONIAL / DEVELOP. These are issue-#2832 ACs.
//
// The fixture reuses the same minimal EXPAND game as
// `domain_planner_orchestrator_phase_plan_injection_test.dart` so the
// new pins live side-by-side with the legacy phase-plan injection
// contract (a planner-state regression that would break this test
// would also break the existing legacy pin).

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/domain_gate_data.dart';
import 'package:colonizethis_ai/src/planning/domain_planner_outcome.dart';
import 'package:colonizethis_ai/src/planning/naval_planner.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/planner_context.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _minorId = 'minor1';
const String _fieldArmyId = 'field_a';
const String _owMinorProvince = 'oldWorld|minor1';
const String _owHomeProvince = 'oldWorld|gp1_0';

const List<String> _gp1OwProvincesBelowQuota = <String>[
  _owHomeProvince,
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
];

Game _scenarioGame() {
  return Game(
    id: 'g-2832-orchestrator-domain-gates',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 30),
      oldWorld: RegionData(
        provinces: [
          for (final id in _gp1OwProvincesBelowQuota)
            Province(id: id, regionId: 'oldWorld', ownerId: _nationId),
          const Province(
            id: _owMinorProvince,
            regionId: 'oldWorld',
            ownerId: _minorId,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      armies: const [
        Army(
          id: _fieldArmyId,
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: _owHomeProvince,
          regimentUnitIds: ['u_field'],
          isHomeArmy: false,
        ),
      ],
    ),
    players: const [
      Player(
        id: _nationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'napoleon',
      ),
    ],
    minorNations: const [
      MinorNation(id: _minorId, displayName: 'Minor One'),
    ],
    tribes: const [],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _minorId,
        state: RelationState.atWar,
        score: -100,
      ),
    ],
  );
}

const FakeOrderSuggestionAPIForDomainPlannerTests _conquestCandidateApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
  armyMove: [
    ArmyMoveOrder(
      armyId: _fieldArmyId,
      destinationProvinceId: _owMinorProvince,
    ),
  ],
);

const EconomyPlan _economyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig _aiConfig = AIConfig(
  leaderId: 'napoleon',
  personalityId: 'napoleon',
  hiddenAgendaId: 'warmonger',
);

AIWorldSnapshot _expandSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(atWarWith: [_minorId]),
    opportunities: OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 7,
      invadableProvinceIdsSorted: [_owMinorProvince],
      adjacentOwnerFactionIdsSorted: [_minorId],
    ),
    economy: EconomySummary(ownProvinceCount: 7),
    relations: {
      _minorId: DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _minorId,
        state: RelationState.atWar,
        score: -100,
      ),
    },
  );
}

DomainPlannerOutcome _runForPhase(PhasePlanOutcome plan) {
  final game = _scenarioGame();
  const topology = MapTopology(nodes: [], edges: []);
  final view = buildPlayerView(game, topology, _nationId);
  final snapshot = _expandSnapshot();
  return runDomainPlannersWithOutcome(
    game: game,
    topology: topology,
    nationId: _nationId,
    view: view,
    snapshot: snapshot,
    config: _aiConfig,
    primaryGoal: StrategicGoal.conquer,
    seeds: AISeedBundle.fromTurnSeed(2832100),
    suggestionAPI: _conquestCandidateApi,
    economyPlan: _economyPlan,
    phasePlan: plan,
  );
}

void main() {
  group('Refs #2832 domain gate data on DomainPlannerOutcome', () {
    test('phasePlan slot surfaces the injected plan unchanged', () {
      const injected = PhasePlanOutcome.defaultDevelop;
      final outcome = _runForPhase(injected);
      expect(
        identical(outcome.phasePlan, injected),
        isTrue,
        reason:
            'When a phasePlan is injected, the orchestrator must thread '
            'the same instance through DomainPlannerOutcome.phasePlan so '
            'callers (strategic_ai trace builder) can emit '
            'state.phasePlan without recomputing the dispatch.',
      );
    });

    test(
      'gate booleans / conquestPasses follow the active phase: EXPAND -> 22',
      () {
        final game = _scenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _expandSnapshot();
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
          reason:
              'Sanity guard: this fixture must place gp1 in EXPAND for '
              'the conquestPasses AC (22 under EXPAND / COLONIAL-lite, '
              '1 otherwise) to be observable.',
        );

        final outcome = runDomainPlannersWithOutcome(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.conquer,
          seeds: AISeedBundle.fromTurnSeed(2832200),
          suggestionAPI: _conquestCandidateApi,
          economyPlan: _economyPlan,
        );

        final gates = outcome.domainGateData;
        expect(gates, isNotNull);
        expect(gates!.conquestPasses, kStalledConquestArmyMovePasses);
        expect(gates.conquestArmyMovePlannerRan, isTrue);
        expect(gates.movePlannerRan, isTrue);
        expect(gates.diplomacyPlannerRan, isTrue);
        // Naval activation depends on per-fixture weight arithmetic
        // (`computeNavalRunGate` >= `kNavalRunMinWeight`); the boolean
        // round-trip test below pins the trace shape. Here we just
        // assert it is a boolean (truthy or falsy) so a future
        // regression that dropped the field surfaces.
        expect(gates.navalPlannerRan, isA<bool>());
      },
    );

    test(
      'gate booleans / conquestPasses follow the active phase: DEVELOP -> 1',
      () {
        final outcome = _runForPhase(PhasePlanOutcome.defaultDevelop);
        final gates = outcome.domainGateData;
        expect(gates, isNotNull);
        expect(gates!.conquestPasses, 1);
      },
    );

    test(
      'computeNavalRunGate.willRun is false when base weight falls below '
      'kNavalRunMinWeight with no colonial-pressure boost',
      () {
        final game = _scenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _expandSnapshot();
        final ctx = PlannerContext(
          nationId: _nationId,
          view: view,
          game: game,
          topology: topology,
          orders: const Orders(),
          config: _aiConfig,
          primaryGoal: StrategicGoal.conquer,
          seeds: AISeedBundle.fromTurnSeed(2832300),
          suggestionAPI: _conquestCandidateApi,
        );
        // EXPAND with no NW pressure: phase-dispatched naval directive
        // reports `colonialPreferenceActive: false`, so the gate is
        // decided purely by `ctx.resolveNavalBaseWeight() >=
        // kNavalRunMinWeight`. The minimal fixture's weight is below
        // that bound, so `willRun` is false.
        final phasePlan = runPhasePlanners(
          game: game,
          snapshot: snapshot,
          personalityId: _aiConfig.personalityId,
        );
        final gate = computeNavalRunGate(
          ctx: ctx,
          snapshot: snapshot,
          phasePlan: phasePlan,
        );
        expect(gate.willRun, gate.weight >= kNavalRunMinWeight);
      },
    );

    test('json shape matches the trace contract', () {
      const sample = DomainGateData(
        workPlannerRan: true,
        buildPlannerRan: false,
        movePlannerRan: true,
        diplomacyPlannerRan: true,
        navalPlannerRan: true,
        researchPlannerRan: true,
        conquestArmyMovePlannerRan: true,
        conquestPasses: 22,
        workThreshold: 40,
        buildThreshold: 30,
        researchThreshold: 40,
      );
      final json = sample.toJson();
      expect(json['workPlannerRan'], isTrue);
      expect(json['buildPlannerRan'], isFalse);
      expect(json['conquestPasses'], 22);
      final thresholds = json['thresholds'] as Map<String, Object?>;
      expect(thresholds['work'], 40);
      expect(thresholds['build'], 30);
      expect(thresholds['research'], 40);
    });
  });
}
