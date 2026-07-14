// Pins the EXPAND-phase forced GP-only invadable frontier blocker
// `declareWar` contract at the `runDomainPlanners` integration boundary
// (Refs #2509).
//
// `stalledGpBlockerDeclareWarTarget`
// (`packages/colonizethis_ai/lib/src/planning/diplomacy_planner.dart`)
// forces a declare-war target when invadable Old World is held only by
// Great Powers (no minor on the border) and the GP is still below the
// observer conquest quota / stalled in the 1–9 OW band. The helper is
// exhaustively pinned at the function level by
// `packages/colonizethis_ai/test/diplomatic_candidate_scoring_suppression_part2_test.dart`
// (`stalledGpBlockerDeclareWarTarget` group: GP-only invadable blocker
// positive, mutual-plateau skip, zero-regiment skip, already-at-war
// skip, …) and was added on `origin/dev` by issue #2509 PR
// [#2577](https://github.com/waigore/colonizethisv3/pull/2577)
// (`fix(ai): GP-only invadable frontier blocker declare priority`).
//
// Neither the helper-level tests nor the existing diplomacy-planner
// suppression tests run the orchestrator, so a future tuning slice
// could leave the predicate intact but silently bypass the orchestrator
// short-circuit that emits the forced `declareWar` (for example by
// narrowing the `if (isOldWorldGpOnlyInvadableFrontier(...))` guard
// around `_plateauGpBlockerDeclarePlannerResultIfNeeded` in
// `runDiplomacyPlannerWithResult`, or by reordering the minor-first
// declare passes so a fall-through never reaches the GP-only blocker
// branch). That regression would starve below-quota EXPAND GPs of the
// only winnable declare on a GP-only invadable frontier (seed-42
// gp3/gp4) and directly threaten the turn-100
// `--verify-conquest` per-GP ≥3 net OW gain gate the nightly observer
// pipeline enforces (`SPEC/program/run_observer_game-tool.md` § Turn
// 100 OW conquest verify; nightly job `observer_conquest_verify` on
// `origin/dev` via PR #2506).
//
// This file is the orchestrator-level counterpart to:
//   - `diplomatic_candidate_scoring_suppression_part2_test.dart` group
//     `stalledGpBlockerDeclareWarTarget` (helper-level), and
//   - `domain_planner_orchestrator_expand_minor_declare_war_test.dart`
//     (EXPAND adjacent invadable OW minor `declareWar` orchestrator
//     pin, sibling slice for #2509 — PR #2621) so the EXPAND
//     declare-war priority order
//     ((a) minor-first → (b) GP-only blocker → (c) stalled invadable
//     GP owner) stays side-by-side reviewable.
//
// SPEC:
//   - `SPEC/ai/ai-architecture.md` § Observer goal phases (Full AI),
//     EXPAND declare-war priority order (GP-only invadable frontier
//     blocker after minor-first declares).
//   - `SPEC/program/order-suggestions.md` § Diplomatic orders.
//
// Coverage layers:
//   - Positive: EXPAND-phase merged diplomatic orders contain
//     `declareWar` toward the GP blocker even when the suggestion API
//     surfaces no candidate (the forced short-circuit appends the
//     order directly to the planner result).
//   - Negative: at-quota DEVELOP-phase merged diplomatic orders do
//     **not** contain `declareWar` toward the same GP blocker — the
//     `stalledGpBlockerDeclareWarTarget` helper short-circuits at the
//     `!isBelowObserverConquestQuota && !isStalledOldWorldExpansion`
//     gate, the `_plateauGpBlockerDeclarePlannerResultIfNeeded`
//     wrapper additionally short-circuits at the same gate, and
//     DEVELOP scoring zeroes every declare-war candidate so the
//     non-forced scoring fall-through cannot resurrect the order
//     either. This catches a regression that would silently re-emit
//     the forced declare past the OW conquest quota and burn turns
//     that should be servicing the turn-150 70% improvement gate.
//   - Determinism guard: re-running with identical EXPAND inputs
//     produces an identical diplomatic-order fingerprint (must-have
//     #7).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String _nationId = kOrchestratorGp1NationId;
const String _blockerGpId = kOrchestratorBlockerGpId;

// Below-quota set: kGp1OwProvincesBelowQuota (Refs #3941).
// Past-quota DEVELOP set: kGp1OwProvincesDevelop (Refs #3941).

// Empty suggestion API: no diplomatic candidates are surfaced. The
// forced GP-only blocker short-circuit appends the `declareWar`
// directly to the planner result without going through the suggestion
// API, so an empty API isolates the orchestrator's forced-declare
// integration from any candidate scoring path.
const FakeOrderSuggestionAPIForDomainPlannerTests _emptyApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
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

// `henry` / `merchant` matches the sibling EXPAND minor declare-war
// orchestrator pin in
// `domain_planner_orchestrator_expand_minor_declare_war_test.dart`.
// The `peacemaker` agenda would zero declare-war candidates regardless
// of phase via the agenda conquer modifier and risk masking the
// forced-blocker emission contract.
const AIConfig _aiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

// Snapshots: buildOrchestratorExpandGpOnlyBlockerSnapshot /
// buildOrchestratorDevelopGpOnlyBlockerSnapshot (Refs #3997).

List<String> _declareWarTargets(Orders orders) => <String>[
  for (final order in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
    if (order.type == DiplomaticOrderType.declareWar) order.targetFactionId,
];

void main() {
  group('runDomainPlanners EXPAND GP-only blocker declareWar', () {
    test(
      'emits forced declareWar toward GP-only invadable frontier blocker in EXPAND',
      () {
        final game = buildOrchestratorExpandGpOnlyBlockerScenarioGame(
          id: 'g-2509-expand-gp-only-blocker',
          gp1OwProvinces: kGp1OwProvincesBelowQuota,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = buildOrchestratorExpandGpOnlyBlockerSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
          reason:
              'Fixture must place GP in EXPAND so the GP-only invadable '
              'frontier blocker forced declare-war path is exercised by '
              'the orchestrator (not the COLONIAL/DEVELOP fall-through, '
              'which gates `_plateauGpBlockerDeclarePlannerResultIfNeeded` '
              'off at `!isBelowObserverConquestQuota` per SPEC § Observer '
              'goal phases (Full AI) EXPAND declare-war priority order).',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: _nationId,
            view: view,
            snapshot: snapshot,
            config: _aiConfig,
            primaryGoal: StrategicGoal.expand,
            seeds: AISeedBundle.fromTurnSeed(2509121),
            suggestionAPI: _emptyApi,
            economyPlan: _economyPlan,
          ),
        );

        expect(
          _declareWarTargets(orders),
          contains(_blockerGpId),
          reason:
              'EXPAND below quota with a GP-only invadable Old World '
              'frontier (no minor on the border) must surface the forced '
              '`declareWar` toward the primary invadable blocker GP in '
              'merged diplomatic orders so the GP can break the GP-only '
              'frontier and pursue the turn-100 per-GP +3 net OW gain '
              'gate (SPEC § Observer goal phases (Full AI), EXPAND '
              'declare-war priority order; PR #2577 narrative).',
        );
      },
    );

    test(
      'suppresses GP blocker declareWar at quota in DEVELOP',
      () {
        final game = buildOrchestratorExpandGpOnlyBlockerScenarioGame(
          id: 'g-2509-expand-gp-only-blocker',
          gp1OwProvinces: kGp1OwProvincesDevelop,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = buildOrchestratorDevelopGpOnlyBlockerSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.develop,
          reason:
              'Negative-control fixture must place GP in DEVELOP so the '
              'observer-quota gate inside '
              '`stalledGpBlockerDeclareWarTarget` (and the matching '
              'wrapper gate in `_plateauGpBlockerDeclarePlannerResultIfNeeded`) '
              'is exercised (otherwise this case would silently re-emit '
              'the EXPAND short-circuit and not verify the regression '
              'target).',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: _nationId,
            view: view,
            snapshot: snapshot,
            config: _aiConfig,
            primaryGoal: StrategicGoal.diplomacy,
            seeds: AISeedBundle.fromTurnSeed(2509122),
            suggestionAPI: _emptyApi,
            economyPlan: _economyPlan,
          ),
        );

        expect(
          _declareWarTargets(orders),
          isNot(contains(_blockerGpId)),
          reason:
              'DEVELOP must drop the GP-only invadable blocker forced '
              'declare (the helper short-circuits at the observer-quota / '
              'stalled-OW gate, the wrapper short-circuits at the same '
              'gate, and DEVELOP scoring zeroes every declare-war '
              'candidate from the non-forced fall-through). Suppressing '
              'this declare preserves civilian work bandwidth for the '
              'turn-150 70% extractable-tile improvement gate (SPEC § '
              'Observer goal phases (Full AI), DEVELOP).',
        );
      },
    );

    test(
      'emits identical diplomatic orders for identical EXPAND inputs',
      () {
        final game = buildOrchestratorExpandGpOnlyBlockerScenarioGame(
          id: 'g-2509-expand-gp-only-blocker',
          gp1OwProvinces: kGp1OwProvincesBelowQuota,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = buildOrchestratorExpandGpOnlyBlockerSnapshot();

        Orders runOnce(int turnSeed) => runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: _nationId,
            view: view,
            snapshot: snapshot,
            config: _aiConfig,
            primaryGoal: StrategicGoal.expand,
            seeds: AISeedBundle.fromTurnSeed(turnSeed),
            suggestionAPI: _emptyApi,
            economyPlan: _economyPlan,
          ),
        );

        final firstRun = runOnce(2509123);
        final secondRun = runOnce(2509123);

        List<String> diplomaticFingerprint(Orders orders) => <String>[
          for (final o
              in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
            '${o.type}|${o.targetFactionId}|${o.overtureStage}',
        ];

        expect(
          diplomaticFingerprint(secondRun),
          diplomaticFingerprint(firstRun),
          reason:
              'Determinism (must-have #7): identical EXPAND-phase inputs '
              'on a GP-only invadable frontier must produce identical '
              'diplomatic orders across runs (forced-blocker declare is '
              'derived from `Game` state, not from rng-driven candidate '
              'sampling, so the fingerprint must be stable).',
        );
      },
    );
  });
}
