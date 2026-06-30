// Seed-42 EXPAND-phase first-25-turns trace pin with field-army positions
// for the issue #2509 S7 tuning loop.
//
// Companion to `seed42_expand_phase_first10turns_trace_test.dart` (PR #2823),
// which captures turns 1..11 and the proximate `planExpandDeclareWar`
// null-return failure mode that PR #2825 then fixed for arm 2. The 10-turn
// horizon is short enough that mid-game phase regressions and field-army
// stalls only emerge after a GP's treasury collapse stabilises (turns
// ~5–15) and the diplomacy planner accumulates enough at-war partners for
// the peace-target / declare-war / conquest passes to interact in their
// post-treasury-collapse steady state. Extending the universal-truth
// invariant to turn 25 closes that gap without paying for the full
// (still-skipped) 100-turn `seed42_observer_conquest_regression_test.dart`
// runtime (~3 min 20 s on the agent host today).
//
// What this test asserts (universal-truth invariant — same as the 10-turn
// pin)
// ----------------------------------------------------------------------
//
// While `ownOw < kObserverConquestMinOwProvincesPerGp` (10) **and** the
// turn number is below the COLONIAL-lite floor
// (`kObserverColonialLiteMinTurn` = 120), the deterministic phase from
// `observerGoalPhaseFor` **must** be `ObserverGoalPhase.expand`. This is
// the issue #2509 § Phase transition guard contract — COLONIAL and
// DEVELOP both require OW ≥ 10; COLONIAL-lite is gated on turn ≥ 120.
// The first 25 captured turns are well below the turn-120 COLONIAL-lite
// floor, so the invariant collapses to: any below-quota GP at any
// captured turn must be in EXPAND. A regression that prematurely routes
// a below-quota GP into COLONIAL / COLONIAL-lite / DEVELOP within the
// 25-turn window would surface immediately.
//
// What this test additionally captures (S7 tuning targets — observed,
// not asserted)
// ----------------------------------------------------------------------
//
// The 25-turn window is long enough to surface **two structural failure
// modes** the 10-turn pin cannot reach:
//
//   1. **Field-army stall.** Below-quota GPs at war with at least one
//      faction that owns invadable OW provinces should commit at least
//      one field army to a non-capital province within a few turns. On
//      `origin/dev` post-PR #2825 the diagnostic record shows several
//      seed-42 GPs (gp1, gp4, gp5) keep all their field armies parked
//      at the capital across the entire 25-turn window despite at-war
//      adjacent invadable OW frontiers and the
//      `_applyStalledArmyMovesForAllFieldArmies` /
//      `_runStalledFrontierArmyMoveFallback` paths in
//      `conquest_planner.dart`. The captured `home=` /
//      `field=` columns surface the per-army stationed province so a
//      future S7 fix can read the failure mode straight off this test's
//      `reason` payload.
//   2. **Premature blocker-GP peace.** When a GP frontier neighbour
//      crosses the OW quota first (seed-42 turn ~5: gp3 / gp6 reach
//      `ow >= 10` and route to COLONIAL), the COLONIAL-phase
//      `planColonialPeace` peaces every at-war GP that does not block
//      its primary colonial NW target. The below-quota neighbour
//      (gp4 / gp5) thus loses its only invadable OW frontier-blocker
//      war within the 25-turn window. The captured `atWarGp=` column
//      surfaces this transition (e.g. `[gp6, …] -> [...]`) so a future
//      S7 fix at the `planColonialPeace` / EXPAND-side accept-peace
//      boundary can read the regression row directly.
//
// Neither failure mode is asserted here — both are S7 tuning targets,
// and asserting them would either require the still-skipped
// `seed42_observer_conquest_regression_test` contract or push policy
// decisions ahead of the SPEC update that would authorize them. The
// test instead embeds the structured per-turn per-GP trace into the
// assertion `reason` payload so any future failure of the asserted
// invariant prints the data the next S7 slice needs without re-running
// the 100-turn observer campaign.
//
// Runtime note: 25 full-AI turn resolutions on the canonical seed-42
// init currently take ~50–55 s on the agent host (linear scaling against
// the 10-turn pin's ~30 s and the 100-turn regression test's ~3 min
// 23 s). The 6-minute timeout is a safety margin only — see
// `colonizethis-turn-resolution-budget.mdc`.
//
// References:
//   - Issue #2509 § Phase transition guard (EXPAND below-quota rule).
//   - Issue #2509 § Requirements § Must-have #5 (OW pressure preserved
//     while below quota — EXPAND is the only valid phase for a below-
//     quota GP before turn 120).
//   - Issue #2509 § COLONIAL phase planner § planColonialPeace (peace
//     all at-war GPs except colonial-target blocker — the proximate
//     cause of the gp5 / gp6 premature peace observed here).
//   - PR #2823 (10-turn EXPAND-phase trace pin — companion).
//   - PR #2825 (planExpandDeclareWar arm 1/3 treasury gate scoping —
//     the 10-turn null-return regression this 25-turn pin extends past).

// Migrated to the shared [runSeed42ObserverCampaign] harness (Refs #3749
// step 2): the init / handoff / per-turn resolve loop is owned by
// `test/support/seed42_observer_campaign.dart`; this test contributes only
// its per-turn pre-resolution trace capture and invariant assertions.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show planExpandDeclareWar;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart'
    show observerGoalPhaseFor;
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        MapTopology,
        kObserverColonialLiteMinTurn,
        kObserverConquestMinOwProvincesPerGp;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import '../support/seed42_observer_campaign.dart';

/// Stationed province + regiment count for one army.
class _ArmyTrace {
  const _ArmyTrace({
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
  final List<_ArmyTrace> homeArmies;
  final List<_ArmyTrace> fieldArmies;

  String formatRow() =>
      'turn=$turn $gpId  phase=$phase  ow=$ownOw  '
      'invadable=$invadableCount  regiments=$regimentCount  '
      'treasury=$treasury  declareWarTarget=$declareWarTarget  '
      'atWarGp=$atWarGp  atWarMinorTribe=$atWarMinorTribe  '
      'adjacentOwners=$adjacentOwners  '
      'home=$homeArmies  field=$fieldArmies';
}

/// Captures pre-resolution per-GP traces for one 1-based campaign turn.
List<_GpTurnTrace> _captureGpTurnTraces({
  required int turn,
  required Game game,
  required MapTopology topo,
}) {
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
    final atWarGp = <String>[
      for (final factionId in snapshot.threats.atWarWith)
        if (game.playerById(factionId) != null) factionId,
    ]..sort();
    final atWarMinorTribe = <String>[
      for (final factionId in snapshot.threats.atWarWith)
        if (game.playerById(factionId) == null) factionId,
    ]..sort();
    final ownerArmies = game.worldState.armies.where(
      (a) => a.ownerId == gpId,
    );
    final homeArmies = <_ArmyTrace>[
      for (final a in ownerArmies)
        if (a.isHomeArmy)
          _ArmyTrace(
            armyId: a.id,
            stationedProvinceId: a.stationedProvinceId,
            regimentCount: a.regimentUnitIds.length,
          ),
    ]..sort((a, b) => a.armyId.compareTo(b.armyId));
    final fieldArmies = <_ArmyTrace>[
      for (final a in ownerArmies)
        if (!a.isHomeArmy)
          _ArmyTrace(
            armyId: a.id,
            stationedProvinceId: a.stationedProvinceId,
            regimentCount: a.regimentUnitIds.length,
          ),
    ]..sort((a, b) => a.armyId.compareTo(b.armyId));
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
        atWarGp: atWarGp,
        atWarMinorTribe: atWarMinorTribe,
        adjacentOwners: List.of(
          snapshot.conquest.adjacentOwnerFactionIdsSorted,
        )..sort(),
        homeArmies: homeArmies,
        fieldArmies: fieldArmies,
      ),
    );
  }
  return perGp;
}

/// Number of full-AI turn resolutions to run.
///
/// Captures pre-resolution per-GP traces at turns 1 .. [_kTurnsToResolve] + 1
/// (so traces include the post-resolution state at the start of turn 26).
const int _kTurnsToResolve = 25;

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test('seed 42 first $_kTurnsToResolve resolved turns: every below-quota '
      'pre-COLONIAL-lite Great Power stays in EXPAND with field-army '
      'positions captured (S7 multi-turn diagnostic)', () {
    final tracesByTurn = <int, List<_GpTurnTrace>>{};
    MapTopology? topo;

    final result = runSeed42ObserverCampaign(
      turns: _kTurnsToResolve,
      onBeforeResolve: (harnessTurn, fullAi, game, topology, tileMap) {
        topo = topology;
        final turn = harnessTurn + 1;
        tracesByTurn[turn] = _captureGpTurnTraces(
          turn: turn,
          game: game,
          topo: topology,
        );
      },
    );

    tracesByTurn[_kTurnsToResolve + 1] = _captureGpTurnTraces(
      turn: _kTurnsToResolve + 1,
      game: result.finalGame,
      topo: topo!,
    );

    final traceTable = StringBuffer();
    for (var turn = 1; turn <= _kTurnsToResolve + 1; turn++) {
      traceTable.writeln('=== Turn $turn ===');
      for (final t in tracesByTurn[turn]!) {
        traceTable.writeln('  ${t.formatRow()}');
      }
    }
    final reason =
        'seed-42 first ${_kTurnsToResolve + 1} turn EXPAND-phase trace '
        'with field-army positions:\n$traceTable';

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
          // (COLONIAL / DEVELOP both require OW >= quota); seed-42
          // confirms gp2 / gp3 / gp6 cross the quota within the
          // first few turns. This invariant only constrains
          // below-quota GPs.
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
  }, timeout: const Timeout(Duration(minutes: 6)));
}
