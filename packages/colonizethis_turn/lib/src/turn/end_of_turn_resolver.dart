// End-of-turn phase: victory check, era dialogue, Spy 5-turn fog decay, Explorer/Spy fog decay,
// coastal sea zone full visibility. SPEC/program/turn-resolution-phase-details.md § End-of-turn.
// Called from turn_resolver.resolveTurnForGame.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'turn_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_world/src/world/fog_resolution.dart';
import 'turn_resolution_seeds.dart';

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
    turnLog.i('military victory set winner=$winnerId turn=$turnNumber');
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
      !game.infiniteMode && tStop != null && currentTurn == tStop;

  if (!haltAfterCalendar) {
    _emitEraChangeDialogue(game, onDialogue);
  }

  final (visibilityByTile, nextSpyTimers) = applySpyRevealTimerDecay(game);
  var stateForFog = game.updateWorldState(
    (ws) => ws.copyWith(
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
    turnLog.i(
      'calendar campaign halt at turn=$currentTurn '
      '(year ${mapping.yearAtTurn(currentTurn)})',
    );
    return game
        .copyWith(calendarCampaignHalted: true)
        .updateWorldState(
          (ws) => ws
              .updateTurnState((ts) => ts.copyWith(phase: TurnPhase.orders))
              .copyWith(
                playerVisibilityByTile: nextVisibility,
                spyRevealTurnsByPlayer: nextSpyTimers,
              ),
        );
  }

  return game.updateWorldState(
    (ws) => ws
        .updateTurnState(
          (ts) => ts.copyWith(
            turnNumber: ts.turnNumber + 1,
            phase: TurnPhase.orders,
          ),
        )
        .copyWith(
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
  final seed = mixTurnSeed(game, nextTurn);
  final events = dialogueEventsForEraChange(game, previousEra, newEra, seed);
  for (final e in events) {
    onDialogue(e);
  }
}

/// Returns the id of a Great Power that controls 31+ Old World provinces, or null.
String? findMilitaryVictoryWinner(Game game) {
  const int requiredProvinces = 31;
  final ownerCache = ProvinceOwnerCache.of(game.worldState);
  String? winnerId;
  for (final player in game.players) {
    if (ownerCache.countOwnedByInRegion(player.id, kRegionOldWorld) <
        requiredProvinces) {
      continue;
    }
    if (winnerId == null || player.id.compareTo(winnerId) < 0) {
      winnerId = player.id;
    }
  }
  return winnerId;
}
