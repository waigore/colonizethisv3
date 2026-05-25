// Pins the strategic-AI hoisted phase-plan contract for
// `runDomainPlannersWithOutcome` (Refs #2509 S5).
//
// `generateStrategicOrdersWithTrace` (`strategic_ai.dart`) now resolves the
// dispatched `PhasePlanOutcome` once per AI player turn via
// `runPhasePlanners(planningGame, planningSnapshot, config.personalityId)`
// and threads the resulting plan into `runDomainPlannersWithOutcome` via a
// new optional `phasePlan` named parameter. The orchestrator short-circuits
// its previously-unconditional internal `runPhasePlanners` call
// (`phasePlan ?? runPhasePlanners(...)`) so the dispatch runs exactly once
// per AI turn against the same `(Game, AIWorldSnapshot, personalityId)`
// inputs the orchestrator would have used internally.
//
// This file pins three contracts on the new wiring at the
// `runDomainPlannersWithOutcome` boundary so a future refactor that:
//
//   - silently dropped the new `phasePlan` parameter (regressing to the
//     internal compute) would fail the *positive* "consumes external plan"
//     test below;
//   - silently dropped the legacy `runPhasePlanners(...)` fallback would
//     fail the *negative* "internal compute path stays green" test;
//   - introduced any non-determinism in the dispatch / propagation path
//     would fail the *determinism* guard (Refs #2509 Must-have #7).
//
// The fixture deliberately constructs a state where natural-phase EXPAND
// would commit a conquest army move (non-empty `armyMove` suggestion,
// OW=7, non-empty `invadableProvinceIdsSorted`). Overriding the dispatched
// plan with `PhasePlanOutcome.defaultDevelop` forces
// `runConquestArmyMovePlanner` to short-circuit via
// `resolvePhaseConquestInvadable.skipConquestPass` (active only under
// DEVELOP, see `phase_planner_conquest_filter.dart:53-58`). The
// orchestrator surfaces that decision on `DomainPlannerOutcome
// .conquestArmyMoveCount` — non-zero under EXPAND's conquest passes, zero
// under DEVELOP's short-circuit (the DEVELOP path also runs the
// relocation `runArmyMovePlanner` which is *not* a conquest pass, so the
// `armyMoveOrdersByPlayerId` total is **not** the right pin — the
// orchestrator-tracked `conquestArmyMoveCount` is). That contrast is the
// orchestrator-level evidence that the new parameter actually rewires
// the dispatch.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/domain_planner_outcome.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _minorId = 'minor1';
const String _fieldArmyId = 'field_a';
const String _owMinorProvince = 'oldWorld|minor1';
const String _owHomeProvince = 'oldWorld|gp1_0';

// 7 GP-owned OW provinces: well below the observer quota of 10, so the
// natural phase is EXPAND. The conquest army-move planner runs and the
// orchestrator surfaces the fake suggestion below.
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
    id: 'g-2509-orchestrator-phase-plan-injection',
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
    minorNations: const [MinorNation(id: _minorId, displayName: 'Minor One')],
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

// Fake API drives a single conquest army-move candidate so the orchestrator
// output cleanly reflects whether the conquest planner ran (EXPAND) or
// short-circuited (DEVELOP).
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
    // 7 OW provinces -> below the observer quota; one invadable minor
    // frontier so the natural-dispatch EXPAND conquest pass has somewhere
    // to march.
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

void main() {
  group('runDomainPlannersWithOutcome phasePlan injection', () {
    test('natural-fixture sanity: EXPAND dispatch commits at least one '
        'conquest army move when phasePlan is omitted (legacy internal '
        'compute)', () {
      final game = _scenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _expandSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Sanity guard for the injection contract: the fixture must '
            'place the GP in EXPAND so the contrast between the '
            'internal-compute (EXPAND, `conquestArmyMoveCount > 0`) '
            'and injected `defaultDevelop` (DEVELOP, '
            '`conquestArmyMoveCount == 0`) paths is decided by the '
            'new parameter, not by the fixture itself.',
      );

      final outcome = runDomainPlannersWithOutcome(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.conquer,
        seeds: AISeedBundle.fromTurnSeed(2509300),
        suggestionAPI: _conquestCandidateApi,
        economyPlan: _economyPlan,
      );

      expect(
        outcome.conquestArmyMoveCount,
        greaterThan(0),
        reason:
            'EXPAND dispatch must run the conquest army-move planner '
            'and commit the candidate. A zero count here means the '
            'fixture itself is not exercising the conquest pass — '
            'rewire before relying on the positive injection assertion '
            'below.',
      );
    });

    test('injected `defaultDevelop` PhasePlanOutcome forces DEVELOP routing — '
        'orchestrator skips the conquest pass (conquestArmyMoveCount == 0), '
        'overriding the natural EXPAND dispatch', () {
      final game = _scenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _expandSnapshot();

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'The injection contract is observable only when the natural '
            'dispatch would have routed to EXPAND. If a future fixture '
            'drift flipped the natural phase, this guard catches it '
            'before the assertion below silently passes.',
      );

      final outcome = runDomainPlannersWithOutcome(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.conquer,
        seeds: AISeedBundle.fromTurnSeed(2509300),
        suggestionAPI: _conquestCandidateApi,
        economyPlan: _economyPlan,
        phasePlan: PhasePlanOutcome.defaultDevelop,
      );

      expect(
        outcome.conquestArmyMoveCount,
        0,
        reason:
            'When `phasePlan: PhasePlanOutcome.defaultDevelop` is '
            'supplied, `runConquestArmyMovePlanner` must short-circuit '
            'via `resolvePhaseConquestInvadable.skipConquestPass` '
            '(active only under DEVELOP) and contribute zero entries '
            'to `conquestArmyMoveCount`. A positive count here means '
            'the orchestrator silently ignored the injected plan and '
            'recomputed EXPAND internally — exactly the regression '
            'this pin guards against. (Total army-move orders may be '
            'non-zero in DEVELOP via the relocation pass; the '
            'orchestrator-tracked `conquestArmyMoveCount` is the only '
            'count that separates the two paths.)',
      );
    });

    test(
      'omitting `phasePlan` produces identical orders to passing the natural '
      '`runPhasePlanners(...)` result — internal compute and external '
      'hoist agree byte-for-byte',
      () {
        // Pins the fallback equivalence contract: the orchestrator's
        // internal `runPhasePlanners(...)` and a hoisted external
        // `runPhasePlanners(...)` against the same inputs must produce
        // the same downstream behaviour. A future refactor that
        // accidentally branched the two paths (for example by reading
        // additional state inside the orchestrator that the hoisted
        // version did not see) would diverge here.
        final game = _scenarioGame();
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _expandSnapshot();

        final naturalPlan = runPhasePlanners(
          game: game,
          snapshot: snapshot,
          personalityId: _aiConfig.personalityId,
        );

        final ordersInternal = runDomainPlannersWithOutcome(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.conquer,
          seeds: AISeedBundle.fromTurnSeed(2509301),
          suggestionAPI: _conquestCandidateApi,
          economyPlan: _economyPlan,
        ).orders;

        final ordersExternal = runDomainPlannersWithOutcome(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.conquer,
          seeds: AISeedBundle.fromTurnSeed(2509301),
          suggestionAPI: _conquestCandidateApi,
          economyPlan: _economyPlan,
          phasePlan: naturalPlan,
        ).orders;

        expect(
          ordersExternal.armyMoveOrdersByPlayerId,
          ordersInternal.armyMoveOrdersByPlayerId,
          reason:
              'Hoisted-plan and internal-dispatch paths must agree on the '
              'army-move fingerprint when fed identical inputs. Divergence '
              'here means the orchestrator is reading state behind the '
              'parameter (or the dispatcher is non-deterministic for the '
              'same `(Game, AIWorldSnapshot, personalityId)` inputs — '
              'which violates Must-have #7).',
        );
        expect(
          ordersExternal.workOrdersByPlayerId,
          ordersInternal.workOrdersByPlayerId,
          reason:
              'Work-order fingerprint parity guards the economy-pass call '
              'sites that consume the same `PhasePlanOutcome` via '
              '`shouldSuppressWorkOrderFromPhasePlan` and the COLONIAL/'
              'DEVELOP civilian-work resolvers.',
        );
        expect(
          ordersExternal.buildUnitOrdersByPlayerId,
          ordersInternal.buildUnitOrdersByPlayerId,
          reason:
              'Build-order fingerprint parity guards the EXPAND '
              'rebuild-trap arms and the COLONIAL build cap, all of which '
              'route through the dispatched `PhasePlanOutcome` slots in '
              '`_appendEconomyBuildOrders`.',
        );
        expect(
          ordersExternal.diplomaticOrdersByPlayerId,
          ordersInternal.diplomaticOrdersByPlayerId,
          reason:
              'Diplomatic-order fingerprint parity guards the three '
              'declare-war suppression resolvers and the phase-specific '
              'peace-target functions that consume the dispatched '
              '`PhasePlanOutcome` in `runDiplomacyPlannerWithResult`.',
        );
        expect(
          ordersExternal.navalMoveOrdersByPlayerId,
          ordersInternal.navalMoveOrdersByPlayerId,
          reason:
              'Naval-move fingerprint parity guards the colonial naval '
              'boost / ranking that reads `resolvePhaseNavalDirective` '
              'off the dispatched plan in `runNavalPlanner`.',
        );
      },
    );

    test('injecting the same `PhasePlanOutcome` twice into '
        'runDomainPlannersWithOutcome produces identical orders '
        '(Must-have #7 determinism under hoisted dispatch)', () {
      final game = _scenarioGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      final snapshot = _expandSnapshot();

      final naturalPlan = runPhasePlanners(
        game: game,
        snapshot: snapshot,
        personalityId: _aiConfig.personalityId,
      );

      DomainPlannerOutcome runOnce() => runDomainPlannersWithOutcome(
        game: game,
        topology: topology,
        nationId: _nationId,
        view: view,
        snapshot: snapshot,
        config: _aiConfig,
        primaryGoal: StrategicGoal.conquer,
        seeds: AISeedBundle.fromTurnSeed(2509302),
        suggestionAPI: _conquestCandidateApi,
        economyPlan: _economyPlan,
        phasePlan: naturalPlan,
      );

      final first = runOnce();
      final second = runOnce();

      expect(
        second.orders.armyMoveOrdersByPlayerId,
        first.orders.armyMoveOrdersByPlayerId,
        reason:
            'Two consecutive `runDomainPlannersWithOutcome` calls with '
            'the same hoisted `PhasePlanOutcome` must produce the same '
            'army-move orders. Non-determinism here would silently '
            'desynchronize the strategic-AI hoisted dispatch from the '
            'orchestrator-internal fallback the same fixture exercises '
            'in the equivalence test above.',
      );
      expect(
        second.declaredWarTargetFactionId,
        first.declaredWarTargetFactionId,
        reason:
            'The declare-war target tracked on `DomainPlannerOutcome` '
            'must be stable across runs — it is the same compute the '
            'AI trace export reads.',
      );
      expect(
        second.conquestArmyMoveCount,
        first.conquestArmyMoveCount,
        reason:
            'The conquest army-move count is the orchestrator-level '
            'rollup the trace pin consumes; determinism across the '
            'hoisted-plan path must be preserved.',
      );
    });
  });
}
