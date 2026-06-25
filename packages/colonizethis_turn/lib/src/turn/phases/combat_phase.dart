import 'package:colonizethis_data/colonizethis_data.dart';
import '../turn_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import '../combat_phase_helpers.dart';
import '../turn_event_sink.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolution_events.dart';
import '../turn_resolver_config.dart';
import '../turn_resolution_seeds.dart';
import '../turn_phase_snapshot.dart';

void _emitPreBattleDialogueForConflicts(
  Game state,
  List<BattleContext> battles,
  int turn,
  int preBattleDialogueSeed,
  void Function(DialogueEvent) onDialogue,
) {
  if (battles.isEmpty) return;
  for (final ctx in battles) {
    final attackerIds = ctx.attackers.map((a) => a.factionId).toList()..sort();
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
  final previousCapitalByPlayer = snapshotBy(
    game.players,
    (p) => p.id,
    (p) => p.capitalProvinceId,
  );
  final previousCapitalByMinor = snapshotBy(
    game.minorNations,
    (m) => m.id,
    (m) => m.capitalProvinceId,
  );
  final previousCapitalByTribe = snapshotBy(
    game.tribes,
    (t) => t.id,
    (t) => t.capitalProvinceId,
  );
  Game state = game;
  final turn = state.worldState.turnState.turnNumber;
  final preBattleDialogueSeed = mixTurnSeed(game, turn);
  state = applyUnopposedProvinceCaptures(state, orders);
  turnLog.i('combat conflict_detection start turn=$turn');
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
  turnLog.i(
    'combat conflict_detection end turn=$turn battleContexts=${battles.length}',
  );
  final combatGeneralLedger = CombatPhaseGeneralLedger();
  final boundBattles = bindGeneralsForCombatPhase(
    game: state,
    contexts: battles,
    ledger: combatGeneralLedger,
  );
  final defaultMode = game.defaultCombatMode ?? CombatMode.autoResolve;
  // Combat-result/dialogue delivery historically bypasses the configured event
  // bus (only the onGameEvent callback + default logger), so the battle sink is
  // built without an eventBus to preserve that exact behaviour. Refs #3701.
  final battleSink = TurnEventSink(
    onGameEvent: onGameEvent,
    onDialogue: onDialogue,
  );
  var seed = mixTurnSeed(game, turn);
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
      sink: battleSink,
    );
    seed = advanceTurnSeed(seed);
    battleIndex++;
  }
  state = applyCapitalReassignmentAfterCombat(
    state,
    topology,
    topologyByRegion: topologyByRegion,
    tileMapByRegion: tileMapByRegion,
  );
  state = applyGreatPowerFall(state, previousCapitalByPlayer);
  state = applyFactionCapitalReassignmentAfterCombat(
    state,
    topology,
    topologyByRegion: topologyByRegion,
  );
  state = applyFactionTerminalFall(
    state,
    previousCapitalByMinor: previousCapitalByMinor,
    previousCapitalByTribe: previousCapitalByTribe,
  );
  return state;
}

/// Combat phase handler — captures pre-combat ownership, runs combat, emits
/// province-captured events, and updates the pipeline. Refs #2560.
TurnPhaseStepOutcome combatTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  final previousOwnership = snapshotBy(
    acc.game.worldState.allProvinces(),
    (prov) => prov.id,
    (prov) => prov.ownerId,
  );
  final afterCombat = runCombatPhase(
    acc.game,
    config.orders,
    acc.landFeedingCoverageByPlayerId,
    config.topology,
    config.tileMapByRegion,
    topologyByRegion: config.topologyByRegion,
    onDialogue: config.onDialogue,
    onGameEvent: config.onGameEvent,
  );
  emitProvinceCapturedEvents(
    previousOwnership,
    afterCombat,
    turn,
    config.eventSink,
  );
  return TurnPhaseStepContinue(acc.copyWith(game: afterCombat));
}
