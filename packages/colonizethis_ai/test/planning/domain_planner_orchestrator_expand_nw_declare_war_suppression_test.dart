// Pins the EXPAND-phase New World `declareWar` suppression rule from
// issue #2509 at the `runDomainPlanners` integration boundary:
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI), EXPAND:
//     Suppress: NW `declareWar`/`establishOverture`, NW conquest army moves,
//     NW naval colonial missions, `purchase_land` in `newWorld|`,
//     `build_improvement` on NW tiles, colonial cargo preference.
//
// The scoring-level half of the `declareWar` suppression is pinned in
// `packages/colonizethis_ai/test/observer_goal_phase_test.dart` group
// `EXPAND suppresses NW declareWar scoring` — that test calls
// `computeDiplomaticCandidateScores` directly and asserts the NW tribe
// `declareWar` candidate collapses to `0`. The symmetric **COLONIAL**
// allow-side is pinned in the same file by group
// `COLONIAL allows NW tribe declareWar scoring` (score strictly positive at
// OW quota).
//
// Sibling EXPAND orchestrator-level pins live in
// `domain_planner_orchestrator_expand_nw_overture_suppression_test.dart`
// (`establishOverture` half) and
// `domain_planner_orchestrator_expand_nw_work_suppression_test.dart`
// (NW `purchase_land` / `build_improvement` / NW conquest army moves halves).
// Neither covers the EXPAND `declareWar` suppression at the orchestrator
// integration: a future tuning slice that left the score collapse intact
// (NW tribe `declareWar` score = 0 in EXPAND) but added a parallel forced
// path in `domain_planner_orchestrator.dart` / `diplomacy_planner.dart` that
// surfaced a `declareWar(NW tribe)` directly into merged diplomatic orders
// — for example a colonial-pressure "forced NW war" helper mirroring
// `_defaultStartOwMinorDeclarePlannerResultIfNeeded` — would silently
// violate the EXPAND clause and pull GPs off the OW quota path before
// turn 100, regressing the canonical seed-42 `--verify-conquest` nightly
// gate (`SPEC/program/run_observer_game-tool.md`).
//
// The negative control asserts the same `declareWar` candidate **is**
// emitted in COLONIAL so a regression that over-suppresses NW
// `declareWar` at OW quota (and therefore strips the war + invasion
// acquisition route from § COLONIAL phase — acquisition priority rule 1
// "Join Empire → `purchase_land` → declare-war + NW invasion") is also
// caught at the orchestrator boundary.
//
// Coverage layers:
//   - Positive (EXPAND): merged diplomatic orders do **not** contain
//     `declareWar` toward the NW tribe candidate the fake API provides.
//   - Negative control (COLONIAL): the same `declareWar` candidate **is**
//     emitted by the orchestrator, so the test catches over-suppression
//     in the wrong phase.
//   - Determinism guard (must-have #7): identical EXPAND-phase inputs
//     produce identical diplomatic-order fingerprints.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/orchestrator_options.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_orchestrator_test_support.dart';
import 'domain_planner_orchestrator_expand_nw_declare_war_suppression_support.dart';
import 'domain_planner_orchestrator_expand_nw_declare_war_suppression_tail_cases.dart';

void main() {
  group('runDomainPlanners EXPAND-phase NW declareWar suppression', () {
    test('EXPAND drops declareWar toward NW tribe colonial target', () {
      final game = buildOrchestratorGp1TribeNwScenarioGame(
        id: 'g-2509-expand-nw-declare-suppress',
        gp1OwProvinces: kGp1OwProvincesBelowQuota,
        diplomacyRelations: const <DiplomacyRelation>[
          DiplomacyRelation(
            factionId1: kOrchestratorGp1NationId,
            factionId2: kOrchestratorTribeId,
            state: RelationState.atPeace,
            score: 0,
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, kExpandNwDeclareWarSuppressionNationId);
      final snapshot = buildOrchestratorExpandNwTribeTargetSnapshot(tribePeaceRelationScore: 0);

      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Fixture must place GP in EXPAND so the NW declareWar '
            'suppression contract is exercised by the orchestrator, not '
            'the COLONIAL fall-through (which has separate diplomacy '
            'rules that allow tribe declare-war).',
      );

      final orders = runDomainPlanners(
        DomainPlannerInput(
          game: game,
          topology: topology,
          nationId: kExpandNwDeclareWarSuppressionNationId,
          view: view,
          snapshot: snapshot,
          config: kExpandNwDeclareWarSuppressionAiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(2509240),
          suggestionAPI: kNwTribeDeclareWarApi,
          economyPlan: kExpandNwDeclareWarSuppressionEconomyPlan,
          options: OrchestratorOptions(phasePlan: kExpandPhasePlanHardSuppressNw),
        ),
      );

      expect(
        expandNwDeclareWarSuppressionTargets(orders),
        isNot(contains(kExpandNwDeclareWarSuppressionTribeId)),
        reason:
            'Under the explicit `newWorldAcquisition = 0.0` override '
            '(legacy hard-suppress regression contract), EXPAND must '
            'drop declareWar toward NW colonial targets so the GP stays '
            'focused on OW expansion to the quota of 10 (SPEC § Observer '
            'goal phases (Full AI), EXPAND suppressions: "NW declareWar/'
            'establishOverture..."). A non-empty contains list here '
            'indicates the orchestrator surfaced a declareWar the '
            'scoring path should have collapsed to 0 — most likely a '
            'forced/short-circuit declare-war helper bypassing the '
            'score gate.',
      );
    });

    test(
      'COLONIAL allows declareWar toward the same NW tribe candidate',
      () {
        final game = buildOrchestratorGp1TribeNwScenarioGame(
          id: 'g-2509-expand-nw-declare-suppress',
          gp1OwProvinces: kGp1OwProvincesAtQuota,
          diplomacyRelations: const <DiplomacyRelation>[
            DiplomacyRelation(
              factionId1: kOrchestratorGp1NationId,
              factionId2: kOrchestratorTribeId,
              state: RelationState.atPeace,
              score: 0,
            ),
          ],
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, kExpandNwDeclareWarSuppressionNationId);
        final snapshot = buildOrchestratorColonialNwTribeTargetSnapshot(tribeRelationScore: 0);

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonial,
          reason:
              'Negative-control fixture must place GP in COLONIAL so the '
              'EXPAND NW declareWar filter is verified to **not** fire '
              'here. Otherwise a regression that over-suppresses NW '
              'declareWar in COLONIAL (stripping the war + invasion '
              'acquisition route from SPEC § COLONIAL phase minimum '
              'rule 1) would also pass the positive case.',
        );

        final orders = runDomainPlanners(
          DomainPlannerInput(
            game: game,
            topology: topology,
            nationId: kExpandNwDeclareWarSuppressionNationId,
            view: view,
            snapshot: snapshot,
            config: kExpandNwDeclareWarSuppressionAiConfig,
            primaryGoal: StrategicGoal.conquer,
            seeds: AISeedBundle.fromTurnSeed(2509241),
            suggestionAPI: kNwTribeDeclareWarApi,
            economyPlan: kExpandNwDeclareWarSuppressionEconomyPlan,
          ),
        );

        expect(
          expandNwDeclareWarSuppressionTargets(orders),
          contains(kExpandNwDeclareWarSuppressionTribeId),
          reason:
              'COLONIAL must allow declareWar toward visible tribe '
              'colonial targets so the SPEC COLONIAL acquisition '
              'priority "Join Empire -> purchase_land -> declare-war + '
              'NW invasion" remains reachable. Over-suppression here '
              'would stall NW acquisition toward the turn-150 NW '
              'ownership gate.',
        );
      },
    );
  });

  registerDomainPlannerOrchestratorExpandNwDeclareWarSuppressionTailCases();
}
