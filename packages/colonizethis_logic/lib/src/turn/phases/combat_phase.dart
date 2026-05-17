import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../combat/battle_general_assignment.dart';
import '../../combat/combat_mode_selection.dart';
import '../../combat/conflict_detection.dart';
import '../../combat/unopposed_province_capture.dart';
import '../../dossier/event_dialogue.dart';
import '../../game_events.dart';
import '../combat_phase_helpers.dart';
import '../turn_seed_constants.dart';
import '../../world/capital_and_gp_fall.dart';

void _emitPreBattleDialogueForConflicts(
  Game state,
  List<BattleContext> battles,
  int turn,
  int preBattleDialogueSeed,
  void Function(DialogueEvent) onDialogue,
) {
  if (battles.isEmpty) return;
  for (final ctx in battles) {
    final attackerIds = ctx.attackers.map((a) => a.factionId).toList()
      ..sort();
    final capitalThreatened = dialogueEventsForCapitalThreatened(
      state,
      capitalOwnerId: ctx.defenderFactionId,
      provinceId: ctx.provinceId,
      attackerFactionIds: attackerIds,
      turnNumber: turn,
      seed: preBattleDialogueSeed,
    );
    for (final e in capitalThreatened) {
      onDialogue(e);
    }
    for (final attackerId in attackerIds) {
      final reactive = dialogueEventsForReactiveHumanAttack(
        state,
        attackerFactionId: attackerId,
        defenderFactionId: ctx.defenderFactionId,
        provinceId: ctx.provinceId,
        turnNumber: turn,
        seed: preBattleDialogueSeed,
      );
      for (final e in reactive) {
        onDialogue(e);
      }
    }
  }
}

Game runCombatPhase(
  Game game,
  Orders orders,
  Map<String, double> feedingCoverageByPlayerId,
  MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion, {
  Map<String, MapTopology>? topologyByRegion,
  void Function(DialogueEvent)? onDialogue,
  void Function(GameEvent)? onGameEvent,
}) {
  final previousCapitalByPlayer = {
    for (final p in game.players) p.id: p.capitalProvinceId,
  };
  Game state = game;
  final turn = state.worldState.turnState.turnNumber;
  final preBattleDialogueSeed =
      (game.globalGameSeed ?? 0) ^ (turn * kTurnResolutionSeedMix);
  state = applyUnopposedProvinceCaptures(state, orders);
  logicLog.i('combat conflict_detection start turn=$turn');
  final battles = detectConflicts(state, orders);
  if (onDialogue != null && battles.isNotEmpty) {
    _emitPreBattleDialogueForConflicts(
      state,
      battles,
      turn,
      preBattleDialogueSeed,
      onDialogue,
    );
  }
  logicLog.i(
    'combat conflict_detection end turn=$turn battleContexts=${battles.length}',
  );
  final combatGeneralLedger = CombatPhaseGeneralLedger();
  final boundBattles = bindGeneralsForCombatPhase(
    game: state,
    contexts: battles,
    ledger: combatGeneralLedger,
  );
  final defaultMode = game.defaultCombatMode ?? CombatMode.autoResolve;
  var seed = (game.globalGameSeed ?? 0) ^ (turn * kTurnResolutionSeedMix);
  var battleIndex = 0;
  for (final ctx in boundBattles) {
    final mode = resolveCombatModeForBattle(
      state,
      ctx,
      defaultMode: defaultMode,
      perBattleOverrides: game.combatModeByProvinceId.isNotEmpty
          ? game.combatModeByProvinceId
          : null,
    );
    state = runOneLandBattle(
      state,
      ctx,
      mode,
      feedingCoverageByPlayerId,
      turn,
      battleIndex,
      seed,
      combatGeneralLedger,
      onDialogue: onDialogue,
      onGameEvent: onGameEvent,
    );
    seed =
        (seed * kTurnResolutionLcgMultiplier + kTurnResolutionLcgIncrement) &
        kTurnResolutionLcgMask;
    battleIndex++;
  }
  state = applyCapitalReassignmentAfterCombat(
    state,
    topology,
    topologyByRegion: topologyByRegion,
    tileMapByRegion: tileMapByRegion,
  );
  state = applyGreatPowerFall(state, previousCapitalByPlayer);
  return state;
}
