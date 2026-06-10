import 'package:colonizethis_data/colonizethis_data.dart';
import 'turn_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_combat/src/combat/naval_combat_resolver.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'turn_resolution_seeds.dart';
export 'package:colonizethis_world/src/world/naval_coastal_visibility.dart'
    show
        canonicalSeaZoneTileBucketKey,
        coastalLandTileKeysFromNavalPresenceAtSea,
        landTileKeysForProvinceBucket,
        revealProvinceTilesForPlayer,
        revealTilesAfterMoveToSeaZone;
export 'package:colonizethis_world/src/world/naval_mission_orders.dart'
    show applyNavalMissionOrders;

// Naval resolution concern fragments (Refs #3290 Phase-0 file-split). Each
// `part of` fragment shares this library's imports and library-private scope,
// so the move is behaviour-preserving — symbols, visibility, and helper
// sharing (e.g. [_NavalMoveOutcome], [_fleetIndexById]) are unchanged.
//
// This library lives under `turn/` (not `world/`) because it orchestrates
// naval combat and dossier/dialogue side-effects: it depends on `combat/`
// (`naval_combat_resolver.dart`) and `dossier/` which sit above the
// `colonizethis_world` leaf layer. Hosting it here eliminates the
// `world -> combat` and `world -> dossier` wrong-direction edges enumerated in
// #3290 Phase-0 ahead of the `colonizethis_world` leaf-package extraction
// (Phase 1); leaf-layer fog code reaches the re-exported coastal-visibility
// helpers directly via `world/naval_coastal_visibility.dart`.
part 'naval_resolution_helpers.dart';
part 'naval_resolution_move.dart';
part 'naval_resolution_battle.dart';

/// Outcome of a single naval-move order application. Returned by both the
/// dock and at-sea move handlers and consumed by [applyNavalMovesAndShipReveal]
/// to thread the mutating fleet/visibility state across each player's orders.
/// Refs #2560.
typedef _NavalMoveOutcome = ({
  List<Fleet> fleets,
  Map<String, Fleet> fleetById,
  Map<String, int> fleetIndexById,
  Map<String, Map<String, String>> visibilityByTile,
});

Game applyNavalMovesAndShipReveal(
  Game game,
  MapTopology topology,
  Map<String, List<NavalMoveOrder>> navalMoveOrdersByPlayerId,
) {
  var fleets = List<Fleet>.from(game.worldState.fleets);
  var visibilityByTile = Map<String, Map<String, String>>.from(
    game.worldState.playerVisibilityByTile,
  );
  final fleetById = {for (final f in fleets) f.id: f};
  var fleetIndexById = _fleetIndexById(fleets);

  for (final entry in navalMoveOrdersByPlayerId.entries) {
    final playerId = entry.key;
    for (final order in entry.value) {
      final fleet = fleetById[order.fleetId];
      if (fleet == null || fleet.ownerId != playerId) continue;
      final homeFleetId = homeFleetIdFor(playerId);

      if (fleet.id == homeFleetId) continue;

      if (order.isDock) {
        final docked = _applyDockNavalMoveOrder(
          game: game,
          topology: topology,
          fleets: fleets,
          fleetById: fleetById,
          fleetIndexById: fleetIndexById,
          playerId: playerId,
          homeFleetId: homeFleetId,
          fleet: fleet,
          order: order,
          visibilityByTile: visibilityByTile,
        );
        fleets = docked.fleets;
        fleetIndexById = docked.fleetIndexById;
        visibilityByTile = docked.visibilityByTile;
        continue;
      }

      final moved = _applySeaNavalMoveOrder(
        game: game,
        topology: topology,
        fleets: fleets,
        fleetById: fleetById,
        fleetIndexById: fleetIndexById,
        playerId: playerId,
        fleet: fleet,
        order: order,
        visibilityByTile: visibilityByTile,
      );
      fleets = moved.fleets;
      fleetIndexById = moved.fleetIndexById;
      visibilityByTile = moved.visibilityByTile;
    }
  }

  return game.updateWorldState(
    (ws) =>
        ws.copyWith(fleets: fleets, playerVisibilityByTile: visibilityByTile),
  );
}

Game runNavalInterceptionCombatPhase(
  Game game,
  MapTopology topology,
  Map<String, List<NavalMoveOrder>> navalMoveOrdersByPlayerId, {
  Map<String, double> navalFeedingCoverageByPlayerId = const {},
  void Function(DialogueEvent)? onDialogue,
  void Function(GameEvent)? onGameEvent,
  GameEventBus? eventBus,
}) {
  var battles = detectNavalConflicts(game);
  turnLog.d('naval phase detected battles=${battles.length}');
  final movedFleetIds = <String>{
    for (final list in navalMoveOrdersByPlayerId.values)
      for (final order in list) order.fleetId,
  };
  battles = [
    for (final b in battles)
      normalizeNavalBattleSidesForAttacker(b, game, movedFleetIds),
  ];
  var seed =
      (game.globalGameSeed ?? 0) ^
      (game.worldState.turnState.turnNumber * kTurnResolutionSeedMix);
  battles = filterBattlesByInterception(game, battles, movedFleetIds, seed);
  turnLog.d('naval phase after interception battles=${battles.length}');
  seed =
      (seed * kTurnResolutionLcgMultiplier + kTurnResolutionLcgIncrement) &
      kTurnResolutionLcgMask;
  var state = game;
  final turn = game.worldState.turnState.turnNumber;
  var battleIndex = 0;
  for (final battle in battles) {
    final hostileByOwner = hostileFactionsByFaction(state);
    final fleetsBySeaZoneId = _fleetsBySeaZoneId(state.worldState.fleets);
    final retreatZoneSide1 = _firstFriendlyOrNeutralRetreatZone(
      topology,
      battle.seaZoneId,
      battle.side1.ownerId,
      hostileByOwner,
      fleetsBySeaZoneId,
    );
    final retreatZoneSide2 = _firstFriendlyOrNeutralRetreatZone(
      topology,
      battle.seaZoneId,
      battle.side2.ownerId,
      hostileByOwner,
      fleetsBySeaZoneId,
    );
    final result = resolveSeaBattle(
      battle,
      seed,
      side1CanRetreat: retreatZoneSide1 != null,
      side2CanRetreat: retreatZoneSide2 != null,
      navalFeedingCoverageByPlayerId: navalFeedingCoverageByPlayerId,
    );
    seed =
        (seed * kTurnResolutionLcgMultiplier + kTurnResolutionLcgIncrement) &
        kTurnResolutionLcgMask;
    // Single-pass first-match (Refs #2394): topology lookup first; otherwise
    // fall back to the first fleet bucketed under `battle.seaZoneId` via the
    // pre-built fleets-by-sea-zone index (still single-pass; no `.where` or
    // `.first` re-iteration on the global fleet list).
    final regionId =
        regionIdForSeaZone(topology, battle.seaZoneId) ??
        fleetsBySeaZoneId[battle.seaZoneId]?.firstOrNull?.regionId ??
        kRegionOldWorld;
    state = applyNavalBattleResults(
      state,
      battle,
      result,
      regionId,
      retreatDestinationSide1: retreatZoneSide1,
      retreatDestinationSide2: retreatZoneSide2,
    );
    turnLog.d(
      'naval phase battle zone=${battle.seaZoneId} outcome=${result.outcome.name} '
      'side1Retreated=${result.side1Retreated} side2Retreated=${result.side2Retreated}',
    );

    state = _applyNavalBattleVictoryDossierAndDialogue(
      state: state,
      battle: battle,
      result: result,
      turn: turn,
      battleIndex: battleIndex,
      seedAfterBattle: seed,
      onDialogue: onDialogue,
    );

    final winnerOwnerId = _navalBattleWinnerOwnerId(result.outcome, battle);
    final navalEv = NavalCombatResultEvent(
      seaZoneId: battle.seaZoneId,
      side1OwnerId: battle.side1.ownerId,
      side2OwnerId: battle.side2.ownerId,
      outcomeName: result.outcome.name,
      turnNumber: turn,
      winnerOwnerId: winnerOwnerId,
      side1Retreated: result.side1Retreated,
      side2Retreated: result.side2Retreated,
    );
    deliverGameEvent(navalEv, eventBus: eventBus, onGameEvent: onGameEvent);

    battleIndex++;
  }
  return state;
}
