// Seed-42 EXPAND-phase initial-state pin for the issue #2509 S7 tuning loop.
//
// Spec contract (issue #2509 § Single-goal phase-driven architecture):
//
//   "EXPAND: oldWorldProvincesOwned < 10 → reach 10 OW provinces. Do
//    nothing else."
//
// The 2026-05-26 turn-100 OW-conquest baseline comment on issue #2509
// flagged that only one of six GPs meets the per-GP net +3 gate on
// seed 42 today and called for a per-turn `(gp, phase, declareWarTarget,
// peaceTargets, regimentCount, treasury, invadableSorted)` trace before
// attempting S7 phase-planner tuning. The full 100-turn regression test
// (`seed42_observer_conquest_regression_test.dart`) is still skipped
// while the turn-100 gate is red, so we lack a fast, deterministic pin
// for the *initial* phase-planner state on the canonical seed.
//
// This test fills that gap with a single-shot turn-1 inspection:
//
//   1. Init the seed-42 game (no AI orders resolved yet — turn 1
//      pre-resolution state).
//   2. For each gp1..gp6, build a `PlayerView` + `AIWorldSnapshot`
//      and capture `(phase, declareWarTarget, peaceTargets, ownOw,
//      treasury)` from the canonical phase-planner entry points
//      (`observerGoalPhaseFor`, `planExpandDeclareWar`,
//      `expandPhaseGpPeaceTargets`).
//   3. Pin the universal deterministic invariants every seed-42 turn-1
//      GP must satisfy:
//
//        - own OW < `kObserverConquestMinOwProvincesPerGp` (10): the
//          observer conquest quota threshold is 10 and no seed-42 GP
//          starts at or above it.
//        - `phase == ObserverGoalPhase.expand`: a below-quota GP at
//          turn 1 is never in COLONIAL (needs OW ≥ 10), COLONIAL-lite
//          (needs OW ≥ 9 + turn ≥ 120), or DEVELOP (needs OW ≥ 10).
//        - `treasury >= cheapestRegimentBuildTreasuryCost()`: the
//          `planExpandDeclareWar` treasury guard must not fire on the
//          seed-42 start state — every GP has enough gold to afford
//          the cheapest catalog regiment on turn 1.
//        - `expandPhaseGpPeaceTargets` is empty: no GP–GP wars have
//          been declared yet on turn 1, so the peace-target collector
//          must return an empty list (filters by `atWarWith` and the
//          fresh game has no `RelationState.atWar` rows).
//
// On any failure the captured per-GP trace is attached to the
// assertion `reason`, so a future regression in `observerGoalPhaseFor`,
// `planExpandDeclareWar`, the starting treasury / regiment economy,
// or the at-war diplomacy seed surfaces the full structured table the
// S7 tuning loop needs.
//
// This pin is fast: a single `runInitGame` + 6 `buildPlayerView` calls
// without any turn resolution. It is intentionally scoped to the
// turn-1 deterministic invariants only — the full 100-turn convergence
// gate stays in `seed42_observer_conquest_regression_test.dart` (still
// skipped on the AC9 / S7 work).
//
// References:
//   - Issue #2509 § Requirements § Must-have #5 (OW pressure preserved
//     while below quota — EXPAND is the only initial phase).
//   - Issue #2509 § Phase transition guard (EXPAND below-quota rule).
//   - Issue #2509 comment 2026-05-26 (turn-100 OW-conquest baseline +
//     "instrument the per-turn trace" pickup for S7).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost, planExpandDeclareWar;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart'
    show expandPhaseGpPeaceTargets, observerGoalPhaseFor;
import 'package:colonizethis_data/colonizethis_data.dart'
    show GameSetupConfig, kObserverConquestMinOwProvincesPerGp;
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

class _Gp1Trace {
  const _Gp1Trace({
    required this.gpId,
    required this.phase,
    required this.declareWarTarget,
    required this.peaceTargets,
    required this.ownOw,
    required this.treasury,
  });

  final String gpId;
  final ObserverGoalPhase phase;
  final String? declareWarTarget;
  final List<String> peaceTargets;
  final int ownOw;
  final int treasury;

  String formatRow() =>
      '$gpId  phase=$phase  ow=$ownOw  treasury=$treasury  '
      'declareWarTarget=$declareWarTarget  peaceTargets=$peaceTargets';
}

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test('seed 42 turn 1: every Great Power starts in EXPAND with enough '
      'treasury to declare and no GP–GP wars yet', () {
    final init = runInitGame(
      config: GameSetupConfig(seed: 42),
      options: const InitGameOptions(
        cellSize: 24,
        renderPng: false,
        skipFillLakes: false,
      ),
    );
    final game = init.game.copyWith(
      aiControlByGpId: {for (final p in init.game.players) p.id: true},
    );
    final topo = init.combinedTopology;

    final traces = <_Gp1Trace>[];
    for (var i = 1; i <= 6; i++) {
      final gpId = 'gp$i';
      final view = buildPlayerView(game, topo, gpId);
      final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topo);
      final phase = observerGoalPhaseFor(snapshot: snapshot, game: game);
      final declareWarTarget = planExpandDeclareWar(
        game: game,
        snapshot: snapshot,
      );
      final peaceTargets = expandPhaseGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final player = game.playerById(gpId)!;
      traces.add(
        _Gp1Trace(
          gpId: gpId,
          phase: phase,
          declareWarTarget: declareWarTarget,
          peaceTargets: peaceTargets,
          ownOw: snapshot.conquest.oldWorldProvincesOwned,
          treasury: player.treasury,
        ),
      );
    }

    final traceTable = traces.map((t) => t.formatRow()).join('\n');
    final reason = 'seed-42 turn-1 per-GP EXPAND-phase trace:\n$traceTable';

    final cheapestRegimentCost = cheapestRegimentBuildTreasuryCost();
    for (final t in traces) {
      expect(
        t.ownOw,
        lessThan(kObserverConquestMinOwProvincesPerGp),
        reason:
            '${t.gpId} starts at or above the observer OW quota '
            '($kObserverConquestMinOwProvincesPerGp) which would skip '
            'EXPAND entirely. $reason',
      );
      expect(
        t.phase,
        ObserverGoalPhase.expand,
        reason:
            '${t.gpId} is not in EXPAND at turn 1 despite being below '
            'the observer OW quota. $reason',
      );
      expect(
        t.treasury,
        greaterThanOrEqualTo(cheapestRegimentCost),
        reason:
            '${t.gpId} starts below the cheapest-regiment treasury cost '
            '($cheapestRegimentCost), which would short-circuit '
            'planExpandDeclareWar at the treasury guard. $reason',
      );
      expect(
        t.peaceTargets,
        isEmpty,
        reason:
            '${t.gpId} has non-empty EXPAND peace targets at turn 1 '
            'but no GP–GP wars have been declared yet on a fresh '
            'init. $reason',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
