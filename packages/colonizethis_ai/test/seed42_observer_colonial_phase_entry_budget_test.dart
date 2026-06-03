// Observer seed-42 turn-150 colonial phase-entry budget gate
// (Refs #2848 § Subtasks/ACs — "Phase-entry budget (≤ 90)").
//
// This focused regression-guard pins the **≤ 90 turn COLONIAL phase-entry
// budget** documented under #2848 § "COLONIAL phase timeline budget"
// ("Each GP has ≤ 90 turns to reach COLONIAL, leaving ≥ 60 turns for NW
// acquisition + improvements") and surfaced as an AC item alongside the
// existing turn-150 colonial verification gates.
//
// Gate semantics pinned by this test:
//   1. For each Great Power `gp1..gp6`, the GP's deterministic
//      `observerGoalPhaseFor` classification must equal
//      `ObserverGoalPhase.colonial` on or before turn index 89
//      (zero-based -> turn number 90). The COLONIAL phase is reached as
//      soon as the GP passes the EXPAND -> COLONIAL transition; the
//      budget therefore measures the first-COLONIAL turn per GP.
//   2. A GP that never reaches COLONIAL across the entire 150-turn
//      seed-42 campaign fails the gate with a deterministic failure
//      message listing the GP id and its terminal phase distribution.
//
// The test deliberately mirrors the structural pattern of
// `seed42_observer_colonial_regression_test.dart` (init game, full-AI
// per-turn loop, 15-minute timeout) and the per-turn phase-classification
// pattern of `seed42_observer_colonial_c0_diagnostic_test.dart` (call
// `runPhasePlanners` per GP per turn using `AIWorldSnapshot.fromPlayerView`
// and read the resulting `PhasePlanOutcome.phase`). Keeping the surfaces
// aligned makes the budget gate easy to reason about alongside the
// existing colonial-acquisition diagnostic surface captured by #2852.
//
// Skip-status precedent: see the existing S10 skip on
// `seed42_observer_conquest_regression_test.dart` and the #2848 S0 skip
// on `seed42_observer_colonial_regression_test.dart`. This test stays
// `skip`ped while the seed-42 phase-entry budget is unreachable for
// gp3..gp6 (those GPs are stuck in EXPAND for all 100 turns under the
// most recent S7-D refresh — Refs #2847 / #2924 / #2925) and pending
// the soft-phase priority system (#2847) closing the EXPAND -> COLONIAL
// transition gap.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/faithful_full_ai_test_handoff.dart';

/// Per-GP COLONIAL phase-entry budget for the seed-42 turn-150 observer
/// campaign per #2848 § "COLONIAL phase timeline budget". A first-COLONIAL
/// turn (zero-based) at or below this value satisfies the budget; above
/// fails it.
///
/// Derived from the 150-turn colonial gate (`kColonialRegressionTurns`)
/// minus the documented "≥ 60 turns for NW acquisition + improvements"
/// post-entry tail. Keeping the constant local mirrors
/// `kColonialImprovementMinRatio` in
/// `seed42_observer_colonial_regression_test.dart` and avoids dragging
/// the test into a `tool/run_observer_game` dependency.
const int kColonialPhaseEntryBudgetTurns = 90;

/// Total turn count the budget is measured across — must be at least
/// `kColonialPhaseEntryBudgetTurns + 1` so a GP that enters COLONIAL on
/// the very last allowed turn (zero-based index 89) is still detected as
/// a pass. Aligns with the seed-42 colonial gate horizon (turn 150) so
/// the budget surface and the existing colonial gates stay anchored to
/// the same simulation window.
const int kColonialPhaseEntryHorizonTurns = 150;

/// Great Power factionIds the budget gate scopes to (gp1..gp6). Mirrors
/// `kColonialRegressionGreatPowerIds` in
/// `seed42_observer_colonial_regression_test.dart` so the two
/// observer-tied gates pin the same GP cohort.
const Set<String> kColonialPhaseEntryGreatPowerIds = {
  'gp1',
  'gp2',
  'gp3',
  'gp4',
  'gp5',
  'gp6',
};

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42: every Great Power enters COLONIAL by turn '
    '$kColonialPhaseEntryBudgetTurns (#2848 phase-entry budget)',
    () {
      final init = runInitGame(
        config: GameSetupConfig(seed: 42),
        options: const InitGameOptions(
          cellSize: 24,
          renderPng: false,
          skipFillLakes: false,
        ),
      );
      var game = applyFaithfulFullAiTestHandoff(init.game);
      final topo = init.combinedTopology;
      final tileMap = init.tileMapByRegion;

      // Stable ordering matches the existing colonial diagnostic test
      // (`seed42_observer_colonial_c0_diagnostic_test.dart`) so the two
      // surfaces report the same GP cohort.
      final gpIds = [
        for (var i = 1; i <= 6; i++)
          if (kColonialPhaseEntryGreatPowerIds.contains('gp$i')) 'gp$i',
      ];

      // Zero-based first-COLONIAL turn index per GP. `null` means the
      // GP never reached COLONIAL during the horizon.
      final firstColonialTurn = <String, int?>{
        for (final gpId in gpIds) gpId: null,
      };
      // Per-GP phase distribution across the horizon — surfaced in the
      // failure message so an over-budget GP shows exactly where the
      // turns went (e.g. 100 turns in EXPAND for gp3..gp5 under the
      // current S7-D baseline).
      final phaseTurnCount = <String, Map<ObserverGoalPhase, int>>{
        for (final gpId in gpIds)
          gpId: <ObserverGoalPhase, int>{
            for (final ph in ObserverGoalPhase.values) ph: 0,
          },
      };

      for (var t = 0; t < kColonialPhaseEntryHorizonTurns; t++) {
        for (final gpId in gpIds) {
          final view = buildPlayerView(game, topo, gpId);
          final snap = AIWorldSnapshot.fromPlayerView(view, topology: topo);
          // Mirror `seed42_observer_colonial_c0_diagnostic_test.dart`:
          // `runPhasePlanners` returns the canonical `PhasePlanOutcome`
          // whose `.phase` field is the deterministic per-GP per-turn
          // classification used by every downstream planner module.
          final outcome = runPhasePlanners(game: game, snapshot: snap);
          phaseTurnCount[gpId]![outcome.phase] =
              (phaseTurnCount[gpId]![outcome.phase] ?? 0) + 1;
          if (outcome.phase == ObserverGoalPhase.colonial) {
            firstColonialTurn[gpId] ??= t;
          }
        }

        final fullAi = generateOrdersForGameFullAI(
          game,
          topo,
          tileMapByRegion: tileMap,
        );
        final merged = mergeOrderLists(
          humanOrders: const Orders(),
          aiOrders: fullAi.orders,
        );
        final assignments = fullAi.economyPlansByPlayerId.map(
          (pid, plan) => MapEntry(pid, plan.productionAssignments),
        );
        final result = validateOrdersAndResolveTurnFromTrustedOrders(
          game: fullAi.game,
          topology: topo,
          orders: merged,
          tileMapByRegion: tileMap,
          defaultAssignmentsByPlayerId: assignments,
        );
        expect(result, isA<TurnResolutionComplete>());
        game = (result as TurnResolutionComplete).game;
      }

      // Positive AC: every GP entered COLONIAL by the budget cutoff.
      // Zero-based first-COLONIAL turn index <= kColonialPhaseEntryBudgetTurns - 1
      // means the GP reached COLONIAL on or before turn number
      // `kColonialPhaseEntryBudgetTurns`.
      final overBudget = <String, Map<String, Object?>>{};
      for (final gpId in gpIds) {
        final first = firstColonialTurn[gpId];
        final phaseSummary = <String, int>{
          for (final entry in phaseTurnCount[gpId]!.entries)
            entry.key.name: entry.value,
        };
        if (first == null) {
          overBudget[gpId] = <String, Object?>{
            'firstColonialTurn': null,
            'reason': 'never_reached_colonial',
            'phaseTurnCount': phaseSummary,
          };
          continue;
        }
        // Compare against the zero-based budget index (89 for a 90-turn
        // budget). Turn 90 (one-based) corresponds to index 89.
        if (first >= kColonialPhaseEntryBudgetTurns) {
          overBudget[gpId] = <String, Object?>{
            'firstColonialTurn': first,
            'reason': 'exceeded_budget',
            'phaseTurnCount': phaseSummary,
          };
        }
      }

      expect(
        overBudget,
        isEmpty,
        reason:
            'Refs #2848 § "COLONIAL phase timeline budget": every GP must '
            'enter ObserverGoalPhase.colonial on or before turn '
            '$kColonialPhaseEntryBudgetTurns (zero-based index '
            '${kColonialPhaseEntryBudgetTurns - 1}). Over-budget GPs '
            '(per-GP {firstColonialTurn, reason, phaseTurnCount}): '
            '$overBudget. Per #2848 scope constraint, EXPAND-side tuning '
            'belongs to #2847 — do not weaken this budget here.',
      );

      // Negative regression guard: per-GP phase totals must sum to the
      // horizon turn count so a future refactor that accidentally drops
      // GPs from the loop (e.g. by changing `gpIds` ordering or
      // narrowing the cohort) surfaces as a deterministic failure
      // instead of a silent pass.
      for (final gpId in gpIds) {
        expect(
          phaseTurnCount[gpId]!.values.fold<int>(0, (a, b) => a + b),
          kColonialPhaseEntryHorizonTurns,
          reason:
              '$gpId phase-count total must equal '
              'kColonialPhaseEntryHorizonTurns '
              '($kColonialPhaseEntryHorizonTurns); '
              'mismatch indicates the per-turn classification loop '
              'dropped one or more turns for this GP and the budget '
              'assertion above is no longer trustworthy.',
        );
      }
    },
    skip:
        'Refs #2848 § "COLONIAL phase timeline budget" '
        '(seed 42, ≤ $kColonialPhaseEntryBudgetTurns turns to enter '
        'COLONIAL): per the latest S7-D refresh on issue #2847 '
        '(2026-05-29 post-#2925), gp3..gp5 stay in EXPAND for all 100 '
        'observed turns and gp6 only enters COLONIAL around turn 94 — '
        'over budget for every failing GP. The root cause is upstream '
        'of COLONIAL (EXPAND geographic peer-war lock + build-pipeline '
        'gate; Refs #2847 / #2924 / #2925). Skip mirrors the existing '
        'S0 skip on seed42_observer_colonial_regression_test.dart and '
        'the S10 skip precedent on '
        'seed42_observer_conquest_regression_test.dart. Re-run with '
        '`dart test --run-skipped` once the soft-phase priority system '
        'lands and the EXPAND -> COLONIAL transition gate closes.',
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
