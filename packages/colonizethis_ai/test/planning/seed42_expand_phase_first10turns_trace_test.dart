// Seed-42 EXPAND-phase first-10-turns trace pin for the issue #2509 S7
// tuning loop. Trace capture lives in sibling support; see file header there
// and issue #2509 comment 2026-05-26 for the full diagnostic rationale.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart'
    show ObserverGoalPhase;
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        MapTopology,
        kObserverColonialLiteMinTurn,
        kObserverConquestMinOwProvincesPerGp;
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import '../support/seed42_observer_campaign.dart';
import 'seed42_expand_phase_first10turns_trace_support.dart';

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 first $kSeed42ExpandPhaseTurnsToResolve resolved turns: every '
    'below-quota pre-COLONIAL-lite Great Power stays in EXPAND (S7 multi-turn '
    'diagnostic)',
    () {
      final tracesByTurn = <int, List<Seed42ExpandPhaseGpTurnTrace>>{};
      MapTopology? topo;

      final result = runSeed42ObserverCampaign(
        turns: kSeed42ExpandPhaseTurnsToResolve,
        onBeforeResolve: (harnessTurn, fullAi, game, topology, tileMap) {
          topo = topology;
          final turn = harnessTurn + 1;
          tracesByTurn[turn] = captureSeed42ExpandPhaseGpTurnTraces(
            turn: turn,
            game: game,
            topo: topology,
          );
        },
      );

      tracesByTurn[kSeed42ExpandPhaseTurnsToResolve + 1] =
          captureSeed42ExpandPhaseGpTurnTraces(
        turn: kSeed42ExpandPhaseTurnsToResolve + 1,
        game: result.finalGame,
        topo: topo!,
      );

      final traceTable = StringBuffer();
      for (var turn = 1; turn <= kSeed42ExpandPhaseTurnsToResolve + 1; turn++) {
        traceTable.writeln('=== Turn $turn ===');
        for (final t in tracesByTurn[turn]!) {
          traceTable.writeln('  ${t.formatRow()}');
        }
      }
      final reason =
          'seed-42 first ${kSeed42ExpandPhaseTurnsToResolve + 1} turn '
          'EXPAND-phase trace:\n'
          '$traceTable';

      for (var turn = 1; turn <= kSeed42ExpandPhaseTurnsToResolve + 1; turn++) {
        for (final t in tracesByTurn[turn]!) {
          if (t.ownOw >= kObserverConquestMinOwProvincesPerGp) {
            continue;
          }
          if (t.turn >= kObserverColonialLiteMinTurn) {
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
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
