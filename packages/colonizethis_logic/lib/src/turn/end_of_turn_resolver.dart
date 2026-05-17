// End-of-turn phase: victory check, era dialogue, Spy 5-turn fog decay, Explorer/Spy fog decay,
// coastal sea zone full visibility. SPEC/program/turn-resolution-phase-details.md § End-of-turn.
// Called from turn_resolver.resolveTurnForGame.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../dossier/event_dialogue.dart';
import '../world/fog_resolution.dart';
import 'turn_seed_constants.dart';

/// Runs the end-of-turn phase: victory check, era-change dialogue, Spy timers, fog decay,
/// coastal sea zone full visibility, advance turn.
Game runEndOfTurnPhase(
  Game game, {
  required MapTopology topology,
  Map<String, MapTopology>? topologyByRegion,
  void Function(DialogueEvent)? onDialogue,
}) {
  if (game.victory != null) return game;

  final winnerId = findMilitaryVictoryWinner(game);
  if (winnerId != null) {
    final turnNumber = game.worldState.turnState.turnNumber;
    logicLog.i('military victory set winner=$winnerId turn=$turnNumber');
    return game.copyWith(
      victory: VictoryState(
        winnerPlayerId: winnerId,
        type: VictoryType.military,
        turnNumber: turnNumber,
      ),
    );
  }

  final mapping = game.turnTimeMapping ?? TurnTimeMapping.gdd01;
  final currentTurn = game.worldState.turnState.turnNumber;
  final tStop = mapping.turnNumberForStartCalendarYear(
    TurnTimeMapping.campaignCalendarStopStartYear,
  );
  final haltAfterCalendar =
      tStop != null && currentTurn == tStop;

  if (!haltAfterCalendar) {
    _emitEraChangeDialogue(game, onDialogue);
  }

  final (visibilityByTile, nextSpyTimers) = applySpyRevealTimerDecay(game);
  var stateForFog = game.copyWith(
    worldState: game.worldState.copyWith(
      playerVisibilityByTile: visibilityByTile,
      spyRevealTurnsByPlayer: nextSpyTimers,
    ),
  );
  var nextVisibility = applyFogDecay(
    stateForFog,
    navalCoastalIntelTopology: topology,
  );
  nextVisibility = applyDistantSeaZoneFogRevert(
    stateForFog,
    nextVisibility,
    topology,
    topologyByRegion: topologyByRegion,
  );
  nextVisibility = applyCoastalSeaZoneFullVisibility(
    stateForFog,
    nextVisibility,
    topology,
    topologyByRegion: topologyByRegion,
  );

  if (haltAfterCalendar) {
    logicLog.i(
      'calendar campaign halt at turn=$currentTurn '
      '(year ${mapping.yearAtTurn(currentTurn)})',
    );
    return game.copyWith(
      calendarCampaignHalted: true,
      worldState: game.worldState.copyWith(
        turnState: game.worldState.turnState.copyWith(
          phase: TurnPhase.orders,
        ),
        playerVisibilityByTile: nextVisibility,
        spyRevealTurnsByPlayer: nextSpyTimers,
      ),
    );
  }

  return game.copyWith(
    worldState: game.worldState.copyWith(
      turnState: game.worldState.turnState.copyWith(
        turnNumber: game.worldState.turnState.turnNumber + 1,
        phase: TurnPhase.orders,
      ),
      playerVisibilityByTile: nextVisibility,
      spyRevealTurnsByPlayer: nextSpyTimers,
    ),
  );
}

void _emitEraChangeDialogue(
  Game game,
  void Function(DialogueEvent)? onDialogue,
) {
  if (onDialogue == null) return;
  final currentTurn = game.worldState.turnState.turnNumber;
  final nextTurn = currentTurn + 1;
  final mapping = game.turnTimeMapping ?? TurnTimeMapping.gdd01;
  final previousEra = eraFromYear(mapping.yearAtTurn(currentTurn));
  final newEra = eraFromYear(mapping.yearAtTurn(nextTurn));
  if (previousEra == newEra) return;
  final seed = (game.globalGameSeed ?? 0) ^ (nextTurn * kTurnResolutionSeedMix);
  final events = dialogueEventsForEraChange(game, previousEra, newEra, seed);
  for (final e in events) {
    onDialogue(e);
  }
}

/// Returns the id of a Great Power that controls 31+ Old World provinces, or null.
String? findMilitaryVictoryWinner(Game game) {
  const int requiredProvinces = 31;
  final countsByOwner = <String, int>{};
  for (final province in game.worldState.oldWorld.provinces) {
    final ownerId = province.ownerId;
    if (ownerId == null || ownerId.isEmpty) continue;
    countsByOwner.update(ownerId, (v) => v + 1, ifAbsent: () => 1);
  }

  final gpIds = game.players.map((p) => p.id).toSet();
  String? winnerId;
  for (final entry in countsByOwner.entries) {
    final ownerId = entry.key;
    final count = entry.value;
    if (!gpIds.contains(ownerId)) continue;
    if (count >= requiredProvinces) {
      if (winnerId == null || ownerId.compareTo(winnerId) < 0) {
        winnerId = ownerId;
      }
    }
  }
  return winnerId;
}
