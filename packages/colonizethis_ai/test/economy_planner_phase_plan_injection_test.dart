// Pins the strategic-AI hoisted phase-plan contract for `runEconomyPlanner`
// (Refs #2509 S5).
//
// `generateStrategicOrdersWithTrace` (`strategic_ai.dart`) now dispatches
// `runPhasePlanners(planningGame, planningSnapshot, config.personalityId)`
// *before* calling `runEconomyPlanner` and threads the resulting
// `PhasePlanOutcome` into the planner via a new optional `phasePlan` named
// parameter. The planner short-circuits its previously-unconditional
// `isBelowQuotaPeaceTreasuryRecovery` compute (`colonial_pressure.dart`)
// and instead derives the EXPAND below-quota peace treasury-recovery cargo
// boost from the dispatched phase via
// `resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive` /
// `resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive`
// (`phase_planner_economy_filter.dart`). The treasury affordability arm
// (`treasury + pendingRichesTreasuryDelta(...) <
// cheapestRegimentBuildTreasuryCost()`) is preserved unchanged so the
// migration only swaps the phase-signal path.
//
// This file pins three contracts on the new wiring at the
// `runEconomyPlanner` boundary so a future refactor that:
//
//   - silently dropped the new `phasePlan` parameter (regressing to the
//     internal `isBelowQuotaPeaceTreasuryRecovery` compute) would fail the
//     *positive* "consumes external plan" test below;
//   - silently dropped the legacy `isBelowQuotaPeaceTreasuryRecovery`
//     fallback would fail the *fallback equivalence* test;
//   - introduced any non-determinism in the cargo-preference path would
//     fail the *determinism* guard (Refs #2509 Must-have #7).
//
// The fixture is the same "below-quota peace + insufficient regiments +
// zero treasury" trap exercised by the existing `economy_planner_test.dart`
// "below-quota peace treasury recovery boosts cargo when broke at peace"
// pin: OW = 8 (< observer quota of 10), regimentCount = 3 (in the
// `[1, kBelowQuotaPeaceMinRegimentsBeforeDeclareWar)` insufficient-regiments
// band), `atWarWithAnyGreatPower = false`, `hasInvadableProvinces = true`,
// `treasury = 0` with an empty stockpile. Under EXPAND the recovery boost
// fires and `cargoPreference` reaches at least `preferCargo`; under
// `PhasePlanOutcome.defaultDevelop` every phase resolver collapses to
// `false` and the boost is suppressed, dropping the cargo preference back
// to `none`.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String _nationId = 'gp1';
const String _owHomeProvince = 'oldWorld|p1';
const String _owInvadableMinorProvince = 'oldWorld|minor1';

Game _brokeAtPeaceGame() {
  return const Game(
    id: 'g-2509-economy-phase-plan-injection',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _owHomeProvince,
            regionId: 'oldWorld',
            ownerId: _nationId,
          ),
        ],
      ),
      newWorld: RegionData(),
      armies: [
        Army(
          id: 'army_gp1',
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: _owHomeProvince,
          regimentUnitIds: ['u1', 'u2', 'u3'],
          isHomeArmy: true,
        ),
      ],
    ),
    players: [
      Player(
        id: _nationId,
        displayName: 'France',
        isHuman: false,
        treasury: 0,
        stockpile: Stockpile(),
        workerPool: WorkerPool(peasants: 0),
      ),
    ],
  );
}

// OW = 8 puts the GP in EXPAND (`oldWorldProvincesOwned <
// kObserverConquestMinOwProvincesPerGp = 10`). One invadable OW minor
// province keeps `hasInvadableProvinces = true`. Empty `atWarWith` keeps
// `atWarWithAnyGreatPower = false`. The combination satisfies the
// insufficient-regiments arm of the EXPAND rebuild trap.
const AIWorldSnapshot _expandTrapSnapshot = AIWorldSnapshot(
  playerId: _nationId,
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: 8,
    invadableProvinceIdsSorted: [_owInvadableMinorProvince],
  ),
  colonial: ColonialSummary(),
  economy: EconomySummary(),
  relations: {},
);

const AIConfig _napoleonConfig = AIConfig(
  leaderId: 'napoleon',
  personalityId: 'napoleon',
  hiddenAgendaId: 'warmonger',
);

int _cargoLevel(CargoPreference p) => p == CargoPreference.strongCargo
    ? 2
    : p == CargoPreference.preferCargo
    ? 1
    : 0;

void main() {
  group('runEconomyPlanner phasePlan injection', () {
    test('natural-fixture sanity: EXPAND-trap snapshot lifts cargo preference '
        'above `none` when phasePlan is omitted (legacy compute path)', () {
      // Guards the contrast between the legacy compute (boost fires) and
      // the injected `defaultDevelop` path (boost suppressed). A future
      // fixture drift that pushed `none` even under the legacy path
      // would silently pass the injection assertion below; this sanity
      // pin catches it first.
      final game = _brokeAtPeaceGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);

      expect(
        observerGoalPhaseFor(snapshot: _expandTrapSnapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Sanity guard for the injection contract: the snapshot must '
            'place the GP in EXPAND so the contrast between the legacy '
            'compute (boost fires) and the injected `defaultDevelop` '
            'path (boost suppressed) is decided by the new parameter, '
            'not by the fixture itself.',
      );

      final plan = runEconomyPlanner(
        game: game,
        view: view,
        config: _napoleonConfig,
        seeds: AISeedBundle.fromTurnSeed(2509400),
        snapshot: _expandTrapSnapshot,
      );

      expect(
        _cargoLevel(plan.cargoPreference),
        greaterThan(0),
        reason:
            'EXPAND-trap snapshot with treasury=0 and insufficient '
            'regiments must trigger the cargo recovery boost under the '
            'legacy compute path. A `none` preference here means the '
            'fixture itself is not exercising the recovery arm — rewire '
            'before relying on the positive injection assertion below.',
      );
    });

    test('injected `defaultDevelop` PhasePlanOutcome suppresses the EXPAND '
        'below-quota peace treasury-recovery boost — cargo preference drops '
        'below the natural-EXPAND legacy compute level', () {
      final game = _brokeAtPeaceGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      const seeds = 2509401;

      final naturalPlan = runEconomyPlanner(
        game: game,
        view: view,
        config: _napoleonConfig,
        seeds: AISeedBundle.fromTurnSeed(seeds),
        snapshot: _expandTrapSnapshot,
      );
      final injectedDevelopPlan = runEconomyPlanner(
        game: game,
        view: view,
        config: _napoleonConfig,
        seeds: AISeedBundle.fromTurnSeed(seeds),
        snapshot: _expandTrapSnapshot,
        phasePlan: PhasePlanOutcome.defaultDevelop,
      );

      expect(
        _cargoLevel(injectedDevelopPlan.cargoPreference),
        lessThan(_cargoLevel(naturalPlan.cargoPreference)),
        reason:
            'When `phasePlan: PhasePlanOutcome.defaultDevelop` is '
            'supplied, both phase-planner economy rebuild-trap '
            'resolvers collapse to `false` (DEVELOP phase) and the '
            'cargo recovery boost must be suppressed. A '
            'greater-or-equal cargo preference here means the planner '
            'silently ignored the injected plan and recomputed '
            '`isBelowQuotaPeaceTreasuryRecovery` from '
            '`colonial_pressure.dart` — exactly the regression this '
            'pin guards against.',
      );
    });

    test('omitting `phasePlan` produces a cargo preference identical to '
        'passing the natural-dispatch `runPhasePlanners(...)` result — '
        'legacy compute and phase-derived path agree under EXPAND', () {
      // Pins the fallback-equivalence contract: under EXPAND the
      // phase-derived path
      // (`resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive`
      // /
      // `resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive`
      // + the treasury affordability arm) must match the legacy
      // `isBelowQuotaPeaceTreasuryRecovery` compute. A future refactor
      // that accidentally branched the two paths (for example by
      // letting the phase resolvers drop the treasury arm) would
      // diverge here.
      final game = _brokeAtPeaceGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      const seeds = 2509402;

      final naturalPlan = runPhasePlanners(
        game: game,
        snapshot: _expandTrapSnapshot,
        personalityId: _napoleonConfig.personalityId,
      );

      final legacyPath = runEconomyPlanner(
        game: game,
        view: view,
        config: _napoleonConfig,
        seeds: AISeedBundle.fromTurnSeed(seeds),
        snapshot: _expandTrapSnapshot,
      );
      final phaseDerivedPath = runEconomyPlanner(
        game: game,
        view: view,
        config: _napoleonConfig,
        seeds: AISeedBundle.fromTurnSeed(seeds),
        snapshot: _expandTrapSnapshot,
        phasePlan: naturalPlan,
      );

      expect(
        phaseDerivedPath.cargoPreference,
        legacyPath.cargoPreference,
        reason:
            'Legacy-compute and phase-derived paths must agree on the '
            'cargo preference when fed the dispatched plan that the '
            'orchestrator would have computed internally. Divergence '
            'here means the phase resolvers and the legacy compute have '
            'drifted apart on the rebuild-trap arms.',
      );
      expect(
        phaseDerivedPath.productionAssignments.length,
        legacyPath.productionAssignments.length,
        reason:
            'Production-assignment count is downstream of `effectiveLabour`, '
            'which is independent of the phase plan in this fixture; '
            'differing counts here would indicate the phase parameter '
            'is leaking into unrelated planner branches.',
      );
    });

    test('deterministic: two consecutive `runEconomyPlanner` calls with the '
        'same hoisted `phasePlan` produce identical cargo preference and '
        'production assignments (Refs #2509 Must-have #7)', () {
      final game = _brokeAtPeaceGame();
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, _nationId);
      const seeds = 2509403;

      final phasePlan = runPhasePlanners(
        game: game,
        snapshot: _expandTrapSnapshot,
        personalityId: _napoleonConfig.personalityId,
      );

      final plan1 = runEconomyPlanner(
        game: game,
        view: view,
        config: _napoleonConfig,
        seeds: AISeedBundle.fromTurnSeed(seeds),
        snapshot: _expandTrapSnapshot,
        phasePlan: phasePlan,
      );
      final plan2 = runEconomyPlanner(
        game: game,
        view: view,
        config: _napoleonConfig,
        seeds: AISeedBundle.fromTurnSeed(seeds),
        snapshot: _expandTrapSnapshot,
        phasePlan: phasePlan,
      );

      expect(plan1.cargoPreference, plan2.cargoPreference);
      expect(
        plan1.productionAssignments.length,
        plan2.productionAssignments.length,
      );
      for (var i = 0; i < plan1.productionAssignments.length; i++) {
        expect(
          plan1.productionAssignments[i].recipeId,
          plan2.productionAssignments[i].recipeId,
        );
        expect(
          plan1.productionAssignments[i].assignedLabour,
          plan2.productionAssignments[i].assignedLabour,
        );
      }
    });
  });
}
