// Seed-42 EXPAND-phase first-10-turns trace pin for the issue #2509 S7
// tuning loop.
//
// Companion to `seed42_expand_phase_turn1_pin_test.dart` which captures
// only the turn-1 pre-resolution state. The 2026-05-26 turn-100
// OW-conquest baseline comment on issue #2509 explicitly recommended a
// per-turn `(gp, phase, declareWarTarget, regimentCount, treasury,
// invadableSorted)` trace for a single seed-42 run before attempting
// any S7 phase-planner tuning, observing in particular that:
//
//   "[gp1] starts at 7 of 10 OW provinces yet acquires zero net OW
//    over 100 turns — the highest-risk failure mode. Worth tracing
//    whether `observerGoalPhaseFor` prematurely routes gp1 into
//    COLONIAL-lite (turn ≥ 120 / OW ≥ 9 — should not fire at start = 7)
//    or into COLONIAL (OW ≥ 10 — should not fire either), and whether
//    `planExpandDeclareWar` keeps returning `null` for gp1 due to
//    peace-target / regiment-floor predicates."
//
// The full 100-turn regression test
// (`seed42_observer_conquest_regression_test.dart`) is still skipped
// while the turn-100 gate is red, so the canonical seed-42 trace
// across resolved turns is invisible to CI today. This test fills
// that gap with a fast, deterministic 10-turn EXPAND invariant pin
// under live AI resolution.
//
// What is asserted (universal-truth invariant)
// --------------------------------------------
//
// While `ownOw < kObserverConquestMinOwProvincesPerGp` (10) **and**
// the turn number is below the COLONIAL-lite floor
// (`kObserverColonialLiteMinTurn` = 120), the deterministic phase
// from `observerGoalPhaseFor` **must** be `ObserverGoalPhase.expand`:
//
//   - COLONIAL-lite is gated on turn ≥ 120 (issue #2509 § Phase
//     transition guard, `observer_goal_phase.dart:71-74`).
//   - COLONIAL and DEVELOP both require OW ≥ 10 (issue #2509 §
//     Phase transition guard).
//   - The first 10 resolved turns (turns 1..11 captured) are
//     therefore the cleanest universal-truth window for this
//     invariant: a regression that prematurely routes a below-quota
//     GP into COLONIAL / COLONIAL-lite / DEVELOP within turns 1..11
//     would surface immediately.
//
// What is captured but **not** asserted (S7 tuning targets)
// ----------------------------------------------------------
//
// The trace also captures the data the baseline comment specifically
// asked for, so a future S7 tuning slice can read the canonical
// failure mode straight off this test's `reason` payload:
//
//   - `declareWarTarget`: result of `planExpandDeclareWar` for the
//     active GP. The current `origin/dev` baseline shows the planner
//     returns `null` for several GPs from turn 4 onward despite
//     non-empty `invadableProvinceIdsSorted`, which the baseline
//     comment flagged as the "planner keeps returning null due to
//     peace-target / regiment-floor predicates" failure mode. We
//     record the value but do **not** assert non-null — that is the
//     S7 phase-planner tuning gate, and asserting it here would
//     duplicate the (skipped) `seed42_observer_conquest_regression_test`
//     contract without adding new coverage.
//   - `treasury`: drops from 5000 (start) to ~50–550 by turn 4–6
//     across all six GPs in the current baseline; the
//     `cheapestRegimentBuildTreasuryCost()` (2000 today) treasury
//     guard inside `planExpandDeclareWar` arm 1 is the proximate
//     cause of the post-turn-4 null returns.
//   - `regimentCount`, `invadableCount`, `atWarWith`,
//     `adjacentOwnerFactionIdsSorted`: the predicate inputs the
//     `planExpandDeclareWar` priority arms branch on (issue #2509
//     § EXPAND phase planner § planExpandDeclareWar). Captured so
//     a regression in any one of them is visible from a single
//     test failure without re-running the slow 100-turn observer
//     campaign.
//
// On any failure of the asserted invariant, the captured per-turn
// per-GP trace table is attached to the assertion `reason` and
// surfaces the structured data the S7 tuning loop needs.
//
// Runtime note: 10 full-AI turn resolutions on the canonical
// seed-42 init currently take ~30–40 s on the agent host (the
// 100-turn regression test runs ~3 min 23 s; the cost is roughly
// linear in turns at this scale). The 5-minute timeout is a safety
// margin only — see `colonizethis-turn-resolution-budget.mdc`.
//
// References:
//   - Issue #2509 § Phase transition guard (EXPAND below-quota rule).
//   - Issue #2509 § Requirements § Must-have #5 (OW pressure preserved
//     while below quota — EXPAND is the only phase below the OW quota
//     before turn 120).
//   - Issue #2509 comment 2026-05-26 (turn-100 OW-conquest baseline +
//     "instrument the per-turn trace" pickup for S7).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show planExpandDeclareWar;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart'
    show observerGoalPhaseFor;
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        GameSetupConfig,
        kObserverColonialLiteMinTurn,
        kObserverConquestMinOwProvincesPerGp;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

class _GpTurnTrace {
  const _GpTurnTrace({
    required this.turn,
    required this.gpId,
    required this.phase,
    required this.declareWarTarget,
    required this.ownOw,
    required this.invadableCount,
    required this.regimentCount,
    required this.treasury,
    required this.atWarWith,
    required this.adjacentOwners,
  });

  final int turn;
  final String gpId;
  final ObserverGoalPhase phase;
  final String? declareWarTarget;
  final int ownOw;
  final int invadableCount;
  final int regimentCount;
  final int treasury;
  final List<String> atWarWith;
  final List<String> adjacentOwners;

  String formatRow() =>
      'turn=$turn $gpId  phase=$phase  ow=$ownOw  invadable=$invadableCount  '
      'regiments=$regimentCount  treasury=$treasury  '
      'declareWarTarget=$declareWarTarget  atWarWith=$atWarWith  '
      'adjacentOwners=$adjacentOwners';
}

/// Number of full-AI turn resolutions to run.
///
/// Captures pre-resolution per-GP traces at turns 1 .. [_kTurnsToResolve] + 1
/// (so traces include the post-resolution state at the start of turn 11).
const int _kTurnsToResolve = 10;

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test('seed 42 first $_kTurnsToResolve resolved turns: every below-quota '
      'pre-COLONIAL-lite Great Power stays in EXPAND (S7 multi-turn '
      'diagnostic)', () {
    final init = runInitGame(
      config: GameSetupConfig(seed: 42),
      options: const InitGameOptions(
        cellSize: 24,
        renderPng: false,
        skipFillLakes: false,
      ),
    );
    var game = init.game.copyWith(
      aiControlByGpId: {for (final p in init.game.players) p.id: true},
    );
    final topo = init.combinedTopology;
    final tileMap = init.tileMapByRegion;

    final tracesByTurn = <int, List<_GpTurnTrace>>{};

    for (var turn = 1; turn <= _kTurnsToResolve + 1; turn++) {
      final perGp = <_GpTurnTrace>[];
      for (var i = 1; i <= 6; i++) {
        final gpId = 'gp$i';
        final view = buildPlayerView(game, topo, gpId);
        final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topo);
        final phase = observerGoalPhaseFor(snapshot: snapshot, game: game);
        final declareWarTarget = planExpandDeclareWar(
          game: game,
          snapshot: snapshot,
        );
        final player = game.playerById(gpId)!;
        perGp.add(
          _GpTurnTrace(
            turn: turn,
            gpId: gpId,
            phase: phase,
            declareWarTarget: declareWarTarget,
            ownOw: snapshot.conquest.oldWorldProvincesOwned,
            invadableCount: snapshot.conquest.invadableProvinceIdsSorted.length,
            regimentCount: regimentCountForPlayer(game, gpId),
            treasury: player.treasury,
            atWarWith: List.of(snapshot.threats.atWarWith)..sort(),
            adjacentOwners: List.of(
              snapshot.conquest.adjacentOwnerFactionIdsSorted,
            )..sort(),
          ),
        );
      }
      tracesByTurn[turn] = perGp;

      if (turn > _kTurnsToResolve) {
        break;
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
      expect(
        result,
        isA<TurnResolutionComplete>(),
        reason: 'Turn $turn resolution failed before invariant check.',
      );
      game = (result as TurnResolutionComplete).game;
    }

    final traceTable = StringBuffer();
    for (var turn = 1; turn <= _kTurnsToResolve + 1; turn++) {
      traceTable.writeln('=== Turn $turn ===');
      for (final t in tracesByTurn[turn]!) {
        traceTable.writeln('  ${t.formatRow()}');
      }
    }
    final reason =
        'seed-42 first ${_kTurnsToResolve + 1} turn EXPAND-phase trace:\n'
        '$traceTable';

    // Universal-truth invariant: while ownOw < quota (10) and turn <
    // COLONIAL-lite floor (120), `observerGoalPhaseFor` must return
    // EXPAND. Below-quota routing into COLONIAL / COLONIAL-lite /
    // DEVELOP under these conditions would be a phase-transition
    // regression. The first ${_kTurnsToResolve + 1} captured turns
    // are well below the turn-120 COLONIAL-lite floor, so the
    // invariant collapses to: any below-quota GP at any captured
    // turn must be in EXPAND.
    for (var turn = 1; turn <= _kTurnsToResolve + 1; turn++) {
      for (final t in tracesByTurn[turn]!) {
        if (t.ownOw >= kObserverConquestMinOwProvincesPerGp) {
          // At-or-above-quota GPs are allowed to leave EXPAND
          // (COLONIAL / DEVELOP both require OW >= quota); the
          // turn-100 baseline confirms gp2 / gp3 / gp6 can cross
          // the quota within the first few turns. This invariant
          // only constrains below-quota GPs.
          continue;
        }
        if (t.turn >= kObserverColonialLiteMinTurn) {
          // Pre-COLONIAL-lite floor never fires under
          // ${_kTurnsToResolve + 1} resolved turns, but check
          // explicitly so the universal-truth assertion stays
          // honest if the constant ever changes.
          continue;
        }
        expect(
          t.phase,
          ObserverGoalPhase.expand,
          reason:
              '${t.gpId} at turn $turn is below the OW quota '
              '(${t.ownOw} < $kObserverConquestMinOwProvincesPerGp) '
              'and before the COLONIAL-lite turn floor '
              '($kObserverColonialLiteMinTurn) yet phase = ${t.phase}. '
              'EXPAND is the only valid phase for a below-quota GP '
              'before turn $kObserverColonialLiteMinTurn (issue #2509 '
              '§ Phase transition guard). $reason',
        );
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
