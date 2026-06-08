// Helpers for the combat phase: apply one land battle (quick or auto-resolve), evidence, dialogue.
// SPEC/program/turn-resolution-phase-details.md § Combat. Called from turn_resolver._runCombatPhase.

import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_combat/src/combat/battle_general_assignment.dart';
import 'package:colonizethis_combat/src/combat/combat_resolver.dart';
import 'package:colonizethis_combat/src/combat/conflict_detection.dart';
import 'package:colonizethis_combat/src/combat/military_attack_economy.dart';
import 'package:colonizethis_combat/src/combat/quick_battle_input_builder.dart';
import 'package:colonizethis_combat/src/combat/quick_battle_resolver.dart';
import 'package:colonizethis_diplomacy/src/dossier/evidence_rules.dart';
import 'package:colonizethis_diplomacy/src/dossier/event_dialogue.dart';
import 'package:colonizethis_world/src/event_bus/game_event_bus.dart';
import 'package:colonizethis_world/src/game_events.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import '../turn_resolution_seeds.dart';

/// Runs one land battle: applies result (quick battle or auto-resolve), evidence, and dialogue.
Game runOneLandBattle(
  Game state,
  BattleContext ctx,
  CombatMode mode,
  Map<String, double> feedingCoverageByPlayerId,
  int turn,
  int battleIndex,
  int seed,
  CombatPhaseGeneralLedger combatGeneralLedger, {
  void Function(DialogueEvent)? onDialogue,
  void Function(GameEvent)? onGameEvent,
}) {
  state = applyLandBattleAttackTreasuryCosts(state, ctx);

  final attackerUnitsTotal = ctx.attackers.fold<int>(
    0,
    (s, a) => s + a.unitIds.length,
  );
  logicLog.i(
    'combat battle_start turn=$turn battleIndex=$battleIndex '
    'regionId=${ctx.regionId} provinceId=${ctx.provinceId} '
    'defenderFactionId=${ctx.defenderFactionId} attackerSides=${ctx.attackers.length} '
    'attackerUnitsTotal=$attackerUnitsTotal mode=${mode.name}',
  );

  String? winnerId;
  Map<String, int> casualties = {};

  if (mode == CombatMode.quickBattle) {
    final input = buildQuickBattleInput(
      state,
      ctx,
      seed: state.worldState.turnState.turnNumber,
    );
    final qbResult = resolveQuickBattle(input);
    state = applyQuickBattleResultToGame(state, ctx, qbResult);
    recordAttackCommandersForResolvedBattle(ctx, null, combatGeneralLedger);
    final qbFlipped =
        qbResult.provinceFlips &&
        qbResult.winner == QuickBattleWinner.attacker &&
        ctx.attackers.isNotEmpty;
    logicLog.i(
      'combat battle_apply regionId=${ctx.regionId} provinceId=${ctx.provinceId} '
      'mode=quickBattle winner=${qbResult.winner.name} provinceFlipped=$qbFlipped '
      'attCasualties=${qbResult.attackerCasualties.length} '
      'defCasualties=${qbResult.defenderCasualties.length}',
    );

    // Determine winner and casualties
    if (qbResult.winner == QuickBattleWinner.attacker) {
      winnerId = ctx.attackers.isNotEmpty
          ? ctx.attackers.first.factionId
          : null;
    } else if (qbResult.winner == QuickBattleWinner.defender) {
      winnerId = ctx.defenderFactionId;
    } else {
      // Mutual exhaustion - no clear winner
      winnerId = null;
    }
    casualties = {
      for (final id in qbResult.attackerCasualties) id: 1,
      for (final id in qbResult.defenderCasualties) id: 1,
    };

    if (qbResult.winner == QuickBattleWinner.attacker &&
        qbResult.provinceFlips &&
        ctx.attackers.isNotEmpty) {
      final victorId = ctx.attackers.first.factionId;
      final evidence = evidenceForLandBattleVictory(
        state,
        victorId,
        ctx.defenderFactionId,
        turn,
      );
      if (evidence.isNotEmpty) {
        state = state.copyWith(
          dossierEvidenceEntries: [
            ...state.dossierEvidenceEntries,
            ...evidence,
          ],
        );
      }
      _emitLandBattleDialogue(
        state,
        victorId,
        ctx.defenderFactionId,
        ctx.provinceId,
        turn,
        battleIndex,
        seed,
        onDialogue,
      );
    } else {
      final victorId = qbResult.winner == QuickBattleWinner.defender
          ? ctx.defenderFactionId
          : (qbResult.provinceFlips && ctx.attackers.isNotEmpty
                ? ctx.attackers.first.factionId
                : null);
      final loserId =
          victorId == ctx.defenderFactionId && ctx.attackers.isNotEmpty
          ? ctx.attackers.first.factionId
          : (victorId != null ? ctx.defenderFactionId : null);
      if (victorId != null && loserId != null) {
        _emitLandBattleDialogue(
          state,
          victorId,
          loserId,
          ctx.provinceId,
          turn,
          battleIndex,
          seed,
          onDialogue,
        );
      }
    }
  } else {
    state = resolveBattleContext(
      state,
      ctx,
      feedingCoverageByPlayerId: feedingCoverageByPlayerId,
      combatGeneralLedger: combatGeneralLedger,
    );
    final province = ProvinceId.isPrefixed(ctx.provinceId)
        ? tryGetProvince(state.worldState, ctx.provinceId)
        : tryGetProvinceByRegion(
            state.worldState,
            ctx.regionId,
            ctx.provinceId,
          );
    final victorId = province?.ownerId;

    // Determine winner and casualties for auto-resolve
    winnerId = victorId;
    // For auto-resolve, we don't have detailed casualty info from the resolver
    // so we emit empty casualties map per spec (at least winner/loser info is present)

    if (victorId != null && victorId != ctx.defenderFactionId) {
      final evidence = evidenceForLandBattleVictory(
        state,
        victorId,
        ctx.defenderFactionId,
        turn,
      );
      if (evidence.isNotEmpty) {
        state = state.copyWith(
          dossierEvidenceEntries: [
            ...state.dossierEvidenceEntries,
            ...evidence,
          ],
        );
      }
    }
    final effectiveVictorId = victorId ?? ctx.defenderFactionId;
    final effectiveLoserId =
        victorId == ctx.defenderFactionId && ctx.attackers.isNotEmpty
        ? ctx.attackers.first.factionId
        : ctx.defenderFactionId;
    _emitLandBattleDialogue(
      state,
      effectiveVictorId,
      effectiveLoserId,
      ctx.provinceId,
      turn,
      battleIndex,
      seed,
      onDialogue,
    );
  }
  // Emit combat_result event for this battle
  if (onGameEvent != null && winnerId != null && ctx.attackers.isNotEmpty) {
    deliverGameEvent(
      CombatResultEvent(
        provinceId: ctx.provinceId,
        attackerId: ctx.attackers.first.factionId,
        defenderId: ctx.defenderFactionId,
        winnerId: winnerId,
        turnNumber: turn,
        casualties: casualties,
      ),
      onGameEvent: onGameEvent,
    );
  }

  return state;
}

void _emitLandBattleDialogue(
  Game state,
  String victorId,
  String loserId,
  String provinceId,
  int turn,
  int battleIndex,
  int seed,
  void Function(DialogueEvent)? onDialogue,
) {
  if (onDialogue == null) return;
  final dialogueSeed =
      (seed ^ (battleIndex * kTurnResolutionSeedMix)) & kTurnResolutionLcgMask;
  final events = dialogueEventsForLandBattleResult(
    state,
    victorId,
    loserId,
    provinceId,
    turn,
    dialogueSeed,
  );
  if (events.isNotEmpty) {
    for (final e in events) {
      onDialogue(e);
    }
  }
}
