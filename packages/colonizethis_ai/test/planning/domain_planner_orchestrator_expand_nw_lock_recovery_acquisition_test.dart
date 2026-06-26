// Pins the **secondary (Path E)** acceptance criterion of issue #2924 at
// the `runDomainPlanners` integration boundary:
//
//   Under the EXPAND geographic peer-war lock with `treasury == 0` and
//   `newWorldProvincesOwned == 0`, the `newWorldAcquisition` priority is
//   floored at `kPhasePriorityNwTreasuryRecoveryFloor` (= 0.60) by the
//   resource-need override (`SPEC/ai/phase-planner-architecture.md`
//   § Resource-need overrides). With that floor active, the AI must
//   emit at least one NW-acquisition-supporting order so the
//   "conquer/purchase NW provinces with riches first" treasury-income
//   chain the owner directed (#2924 comments, 2026-05-28) can begin —
//   rather than gaining zero NW provinces across the whole campaign.
//
// This is the positive mirror of
// `domain_planner_orchestrator_expand_nw_declare_war_suppression_test.dart`,
// which pins the legacy hard-suppress contract via an explicit
// `newWorldAcquisition = 0.0` override. The EXPAND universal colonial
// dispatch (Refs #2847; `phasePlanFullColonialOutputsActive` returns
// true under EXPAND once `newWorldAcquisition > 0`) is what makes the
// NW colonial declare-war reachable under the lock floor. Without this
// pin, a regression that re-introduced a boolean EXPAND-wide NW
// `declareWar` suppression (ignoring the soft weight) would silently
// re-close the Path E lock-recovery route while the legacy
// hard-suppress regression test (which threads 0.0) still passed.
//
// Coverage layers:
//   - Positive (EXPAND, NW floor 0.60): merged diplomatic orders
//     **do** contain `declareWar` toward the visible NW tribe colonial
//     target the fake API provides.
//   - Negative control (EXPAND, NW weight 0.0): the same candidate is
//     dropped, proving the emission is gated on the NW weight and not
//     an unconditional EXPAND allow (which would regress the legacy
//     hard-suppress contract / pull GPs off the OW quota path).
//   - Determinism guard (Refs #2509 Must-have #7): identical lock-floor
//     EXPAND inputs produce identical diplomatic-order fingerprints.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _tribeId = 'tribe1';
const String _tribeNwProvince = 'newWorld|tribe1_nw0';

// EXPAND priority profile with the New-World acquisition weight floored
// at the resource-need override value (`kPhasePriorityNwTreasuryRecoveryFloor`
// = 0.60) the lock predicate applies when
// `treasury == 0 && newWorldProvincesOwned == 0 &&
// boostTreasuryRecoveryCargo == true`. Old-World weights stay on the
// early-sprint plateau so the only delta from the suppression test's
// `_nwAcquisitionZeroExpand` fixture is the NW weight crossing zero.
const PhasePriorityWeights _nwAcquisitionLockFloorExpand = PhasePriorityWeights(
  oldWorldConquest: 0.95,
  newWorldAcquisition: kPhasePriorityNwTreasuryRecoveryFloor,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const PhasePlanOutcome _expandPhasePlanLockFloorNw = PhasePlanOutcome(
  phase: ObserverGoalPhase.expand,
  priorityWeights: _nwAcquisitionLockFloorExpand,
);

// Negative-control profile: NW weight pinned to zero restores the legacy
// hard-suppress contract (same fixture as the suppression test).
const PhasePriorityWeights _nwAcquisitionZeroExpand = PhasePriorityWeights(
  oldWorldConquest: 0.95,
  newWorldAcquisition: 0.0,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const PhasePlanOutcome _expandPhasePlanZeroNw = PhasePlanOutcome(
  phase: ObserverGoalPhase.expand,
  priorityWeights: _nwAcquisitionZeroExpand,
);

// Sub-quota OW set (< `kObserverConquestMinOwProvincesPerGp` = 10) so
// `isBelowObserverConquestQuota` is true and the GP enters EXPAND per
// `observerGoalPhaseFor` — the phase the lock predicate operates in.
const List<String> _gp1OwProvincesBelowQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
];

Game _scenarioGame() {
  return Game(
    id: 'g-2924-expand-nw-lock-recovery-acquisition',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 110),
      oldWorld: RegionData(
        provinces: [
          for (final id in _gp1OwProvincesBelowQuota)
            Province(id: id, regionId: 'oldWorld', ownerId: _nationId),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: _tribeNwProvince,
            regionId: 'newWorld',
            ownerId: _tribeId,
          ),
        ],
      ),
      // Non-empty Home Army keeps `regimentCountForPlayer` > 0 so the
      // orchestrator does not divert into the zero-regiment stalemate
      // peace paths — same guard pattern as the sibling suppression pins.
      armies: [
        Army(
          id: homeArmyIdFor(_nationId),
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: _gp1OwProvincesBelowQuota.first,
          regimentUnitIds: const ['u_gp1'],
          isHomeArmy: true,
        ),
      ],
    ),
    players: const [
      Player(
        id: _nationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'henry',
      ),
    ],
    tribes: const [Tribe(id: _tribeId, displayName: 'T1')],
    minorNations: const [],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _tribeId,
        state: RelationState.atPeace,
        score: 0,
      ),
    ],
  );
}

// Fake API provides one `declareWar(tribe1)` candidate (NW tribe colonial
// target). The orchestrator's EXPAND scoring + selection pass is what
// decides whether the candidate survives under the active NW weight.
const FakeOrderSuggestionAPIForDomainPlannerTests _nwTribeDeclareWarApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
  diplomatic: [
    DiplomaticOrder(
      type: DiplomaticOrderType.declareWar,
      targetFactionId: _tribeId,
    ),
  ],
);

const EconomyPlan _economyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

const AIConfig _aiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

// 7 OW provinces -> EXPAND (below the observer quota of 10), with the
// tribe a visible NW invadable owner + preferred colonial target so the
// NW declare-war scoring path is exercised across all triggering
// predicates. `treasury == 0` and `newWorldProvincesOwned == 0` mirror
// the lock predicate state the NW floor is keyed on.
AIWorldSnapshot _expandLockSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 7,
      provincesToVictory: 24,
    ),
    colonial: ColonialSummary(
      newWorldProvincesOwned: 0,
      invadableNewWorldProvinceIdsSorted: [_tribeNwProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [_tribeId],
      preferredColonialTargetFactionIdsSorted: [_tribeId],
    ),
    economy: EconomySummary(ownProvinceCount: 7, treasury: 0),
    relations: {
      _tribeId: DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _tribeId,
        state: RelationState.atPeace,
        score: 0,
      ),
    },
  );
}

List<String> _declareWarTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
    if (order.type == DiplomaticOrderType.declareWar) order.targetFactionId,
];

Orders _runOrchestrator({
  required PhasePlanOutcome phasePlan,
  required int turnSeed,
}) {
  final game = _scenarioGame();
  const topology = MapTopology(nodes: [], edges: []);
  final view = buildPlayerView(game, topology, _nationId);
  final snapshot = _expandLockSnapshot();

  expect(
    observerGoalPhaseFor(snapshot: snapshot, game: game),
    ObserverGoalPhase.expand,
    reason:
        'Fixture must place GP in EXPAND so the lock-floor NW '
        'acquisition contract is exercised by the orchestrator.',
  );

  return runDomainPlanners(
    game: game,
    topology: topology,
    nationId: _nationId,
    view: view,
    snapshot: snapshot,
    config: _aiConfig,
    primaryGoal: StrategicGoal.expand,
    seeds: AISeedBundle.fromTurnSeed(turnSeed),
    suggestionAPI: _nwTribeDeclareWarApi,
    economyPlan: _economyPlan,
    phasePlan: phasePlan,
  );
}

void main() {
  group('runDomainPlanners EXPAND-phase NW lock-recovery acquisition', () {
    test(
      'EXPAND with NW floor 0.60 emits declareWar toward NW tribe '
      '(Path E secondary AC)',
      () {
        final orders = _runOrchestrator(
          phasePlan: _expandPhasePlanLockFloorNw,
          turnSeed: 2924240,
        );

        expect(
          _declareWarTargets(orders),
          contains(_tribeId),
          reason:
              'Under the EXPAND geographic peer-war lock the '
              'resource-need override floors newWorldAcquisition at '
              'kPhasePriorityNwTreasuryRecoveryFloor (0.60); the '
              'orchestrator must surface an NW-acquisition declareWar so '
              'the "conquer/purchase NW provinces with riches first" '
              'treasury-income chain (#2924 owner direction) can begin. '
              'An empty contains list indicates the EXPAND universal '
              'colonial dispatch (Refs #2847) re-closed the Path E route.',
        );
      },
    );

    test(
      'EXPAND with NW weight 0.0 drops the same declareWar '
      '(legacy hard-suppress negative control)',
      () {
        final orders = _runOrchestrator(
          phasePlan: _expandPhasePlanZeroNw,
          turnSeed: 2924241,
        );

        expect(
          _declareWarTargets(orders),
          isNot(contains(_tribeId)),
          reason:
              'With newWorldAcquisition pinned to 0.0 the legacy '
              'hard-suppress contract must hold so the lock-floor '
              'emission above is proven to be gated on the NW weight '
              'crossing zero — not an unconditional EXPAND allow.',
        );
      },
    );

    test('emits identical diplomatic orders for identical lock-floor inputs',
        () {
      List<String> diplomaticFingerprint(Orders orders) => <String>[
        for (final o
            in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
          '${o.type}|${o.targetFactionId}|${o.overtureStage}',
      ];

      final firstRun = _runOrchestrator(
        phasePlan: _expandPhasePlanLockFloorNw,
        turnSeed: 2924242,
      );
      final secondRun = _runOrchestrator(
        phasePlan: _expandPhasePlanLockFloorNw,
        turnSeed: 2924242,
      );

      expect(
        diplomaticFingerprint(secondRun),
        diplomaticFingerprint(firstRun),
        reason:
            'Determinism (Refs #2509 Must-have #7): identical lock-floor '
            'EXPAND inputs must produce identical diplomatic orders.',
      );
    });
  });
}
