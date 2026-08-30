// Shared trace capture for `seed42_expand_phase_first10turns_trace_test.dart`
// (Refs #2509 S7 multi-turn diagnostic).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show planExpandDeclareWar;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart'
    show observerGoalPhaseFor;
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

class Seed42ExpandPhaseGpTurnTrace {
  const Seed42ExpandPhaseGpTurnTrace({
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
/// Captures pre-resolution per-GP traces at turns 1 .. [kSeed42ExpandPhaseTurnsToResolve] + 1.
const int kSeed42ExpandPhaseTurnsToResolve = 10;

/// Captures pre-resolution per-GP traces for one 1-based campaign turn.
List<Seed42ExpandPhaseGpTurnTrace> captureSeed42ExpandPhaseGpTurnTraces({
  required int turn,
  required Game game,
  required MapTopology topo,
}) {
  final perGp = <Seed42ExpandPhaseGpTurnTrace>[];
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
      Seed42ExpandPhaseGpTurnTrace(
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
  return perGp;
}
