// Trace capture helpers for seed-42 EXPAND first-25-turns field-army pin
// (Refs #4602 Slice B). Used by the sibling `*_test.dart`.

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

/// Stationed province + regiment count for one army.
class Seed42ExpandFieldArmyTrace {
  const Seed42ExpandFieldArmyTrace({
    required this.armyId,
    required this.stationedProvinceId,
    required this.regimentCount,
  });

  final String armyId;
  final String stationedProvinceId;
  final int regimentCount;

  @override
  String toString() => '$armyId@$stationedProvinceId(${regimentCount}r)';
}

class Seed42ExpandGpTurnTrace {
  const Seed42ExpandGpTurnTrace({
    required this.turn,
    required this.gpId,
    required this.phase,
    required this.declareWarTarget,
    required this.ownOw,
    required this.invadableCount,
    required this.regimentCount,
    required this.treasury,
    required this.atWarGp,
    required this.atWarMinorTribe,
    required this.adjacentOwners,
    required this.homeArmies,
    required this.fieldArmies,
  });

  final int turn;
  final String gpId;
  final ObserverGoalPhase phase;
  final String? declareWarTarget;
  final int ownOw;
  final int invadableCount;
  final int regimentCount;
  final int treasury;

  /// At-war partners filtered to Great Powers (sorted ascending).
  final List<String> atWarGp;

  /// At-war partners filtered to minors / tribes (sorted ascending).
  final List<String> atWarMinorTribe;

  final List<String> adjacentOwners;
  final List<Seed42ExpandFieldArmyTrace> homeArmies;
  final List<Seed42ExpandFieldArmyTrace> fieldArmies;

  String formatRow() =>
      'turn=$turn $gpId  phase=$phase  ow=$ownOw  '
      'invadable=$invadableCount  regiments=$regimentCount  '
      'treasury=$treasury  declareWarTarget=$declareWarTarget  '
      'atWarGp=$atWarGp  atWarMinorTribe=$atWarMinorTribe  '
      'adjacentOwners=$adjacentOwners  '
      'home=$homeArmies  field=$fieldArmies';
}

/// Captures pre-resolution per-GP traces for one 1-based campaign turn.
List<Seed42ExpandGpTurnTrace> captureSeed42ExpandGpTurnTraces({
  required int turn,
  required Game game,
  required MapTopology topo,
}) {
  final perGp = <Seed42ExpandGpTurnTrace>[];
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
    final atWarGp = <String>[
      for (final factionId in snapshot.threats.atWarWith)
        if (game.playerById(factionId) != null) factionId,
    ]..sort();
    final atWarMinorTribe = <String>[
      for (final factionId in snapshot.threats.atWarWith)
        if (game.playerById(factionId) == null) factionId,
    ]..sort();
    final ownerArmies = game.worldState.armies.where((a) => a.ownerId == gpId);
    final homeArmies = <Seed42ExpandFieldArmyTrace>[
      for (final a in ownerArmies)
        if (a.isHomeArmy)
          Seed42ExpandFieldArmyTrace(
            armyId: a.id,
            stationedProvinceId: a.stationedProvinceId,
            regimentCount: a.regimentUnitIds.length,
          ),
    ]..sort((a, b) => a.armyId.compareTo(b.armyId));
    final fieldArmies = <Seed42ExpandFieldArmyTrace>[
      for (final a in ownerArmies)
        if (!a.isHomeArmy)
          Seed42ExpandFieldArmyTrace(
            armyId: a.id,
            stationedProvinceId: a.stationedProvinceId,
            regimentCount: a.regimentUnitIds.length,
          ),
    ]..sort((a, b) => a.armyId.compareTo(b.armyId));
    perGp.add(
      Seed42ExpandGpTurnTrace(
        turn: turn,
        gpId: gpId,
        phase: phase,
        declareWarTarget: declareWarTarget,
        ownOw: snapshot.conquest.oldWorldProvincesOwned,
        invadableCount: snapshot.conquest.invadableProvinceIdsSorted.length,
        regimentCount: regimentCountForPlayer(game, gpId),
        treasury: player.treasury,
        atWarGp: atWarGp,
        atWarMinorTribe: atWarMinorTribe,
        adjacentOwners: List.of(snapshot.conquest.adjacentOwnerFactionIdsSorted)
          ..sort(),
        homeArmies: homeArmies,
        fieldArmies: fieldArmies,
      ),
    );
  }
  return perGp;
}

/// Number of full-AI turn resolutions to run.
///
/// Captures pre-resolution per-GP traces at turns 1 .. [kSeed42ExpandFirst25TurnsToResolve] + 1
/// (so traces include the post-resolution state at the start of turn 26).
const int kSeed42ExpandFirst25TurnsToResolve = 25;
