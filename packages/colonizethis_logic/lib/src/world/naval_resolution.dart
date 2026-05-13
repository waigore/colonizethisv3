import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../combat/naval_combat_resolver.dart';
import '../constants.dart';
import '../diplomacy/diplomacy_relation_lookup.dart';
import '../dossier/evidence_rules.dart';
import '../dossier/event_dialogue.dart';
import '../event_bus/game_event_bus.dart';
import '../game_events.dart';
import '../turn/turn_seed_constants.dart';
import 'naval.dart';
import 'naval_coastal_visibility.dart';
import 'province_lookup.dart' hide landTileKeysForProvinceBucket;
import 'topology_helpers.dart';

export 'naval_coastal_visibility.dart'
    show
        canonicalSeaZoneTileBucketKey,
        coastalLandTileKeysFromNavalPresenceAtSea,
        landTileKeysForProvinceBucket,
        revealProvinceTilesForPlayer,
        revealTilesAfterMoveToSeaZone;
export 'naval_mission_orders.dart' show applyNavalMissionOrders;

final _log = packageLogger();

List<String> _adjacentSeaZones(MapTopology topology, String seaZoneId) {
  final out = <String>[];
  for (final e in topology.edges) {
    if (e.id1 == seaZoneId) {
      out.add(e.id2);
    } else if (e.id2 == seaZoneId) {
      out.add(e.id1);
    }
  }
  return out;
}

String? _firstFriendlyOrNeutralRetreatZone(
  Game game,
  MapTopology topology,
  String fromSeaZoneId,
  String ownerId,
) {
  final hostileByOwner = hostileFactionsByFaction(game);
  for (final adj in _adjacentSeaZones(topology, fromSeaZoneId)) {
    final hostileOwnersPresent = game.worldState.fleets.any(
      (fleet) =>
          fleet.isAtSea &&
          fleet.seaZoneId == adj &&
          fleet.ownerId != ownerId &&
          (hostileByOwner[ownerId]?.contains(fleet.ownerId) ?? false),
    );
    if (!hostileOwnersPresent) return adj;
  }
  return null;
}

String? _firstFleetRegionIdForSeaZone(Game game, String seaZoneId) {
  for (final f in game.worldState.fleets) {
    if (f.seaZoneId == seaZoneId) {
      return f.regionId;
    }
  }
  return null;
}

bool _navalMoveDestinationIsReachable({
  required MapTopology topology,
  required Fleet fleet,
  required String destZoneId,
}) {
  if (fleet.isAtSea) {
    final cur = fleet.seaZoneId;
    if (cur == null) return false;
    if (cur == destZoneId) return true;
    return isAdjacentSeaSeaZone(topology, cur, destZoneId);
  }
  final inPortProvinceId = fleet.inPortAtProvinceId;
  if (inPortProvinceId == null) return false;
  final rl = regionAndLocalProvinceForFleetInPort(
    inPortProvinceId,
    fleet.regionId,
  );
  final provinceNodeId = provinceTopologyNodeId(
    topology,
    rl.localId,
    rl.regionId,
  );
  if (provinceNodeId == null) return false;
  return seaZonesAdjacentToProvince(
    topology,
    provinceNodeId,
  ).contains(destZoneId);
}

({
  List<Fleet> fleets,
  Map<String, Fleet> fleetById,
  Map<String, Map<String, String>> visibilityByTile,
})
_applyDockNavalMoveOrder({
  required Game game,
  required MapTopology topology,
  required List<Fleet> fleets,
  required Map<String, Fleet> fleetById,
  required String playerId,
  required String homeFleetId,
  required Fleet fleet,
  required NavalMoveOrder order,
  required Map<String, Map<String, String>> visibilityByTile,
}) {
  final portProvinceId = order.destinationPortProvinceId!;
  if (!fleet.isAtSea || fleet.seaZoneId == null) {
    return (
      fleets: fleets,
      fleetById: fleetById,
      visibilityByTile: visibilityByTile,
    );
  }
  final fullProvinceId = toFullProvinceId(fleet.regionId, portProvinceId);
  final province = game.worldState.tryGetProvince(fullProvinceId);
  if (province == null || province.ownerId != playerId) {
    return (
      fleets: fleets,
      fleetById: fleetById,
      visibilityByTile: visibilityByTile,
    );
  }
  final adjacentSeaZones = seaZoneIdsAdjacentToProvince(
    topology,
    fullProvinceId,
  );
  if (!adjacentSeaZones.contains(fleet.seaZoneId)) {
    return (
      fleets: fleets,
      fleetById: fleetById,
      visibilityByTile: visibilityByTile,
    );
  }

  var nextVis = revealProvinceTilesForPlayer(
    game,
    visibilityByTile,
    playerId,
    fullProvinceId,
  );

  if (dockOrderTargetsPlayerCapital(game, playerId, fullProvinceId)) {
    final homeFleet = fleetById[homeFleetId];
    if (homeFleet == null) {
      return (fleets: fleets, fleetById: fleetById, visibilityByTile: nextVis);
    }
    final updatedHome = Fleet(
      id: homeFleet.id,
      ownerId: homeFleet.ownerId,
      seaZoneId: null,
      inPortAtProvinceId: homeFleet.inPortAtProvinceId,
      regionId: homeFleet.regionId,
      ships: [...homeFleet.ships, ...fleet.ships],
      mission: FleetMission.none,
      targetPortId: null,
      targetProvinceId: null,
    );
    final nextFleets = fleets
        .where((f) => f.id != fleet.id)
        .map((f) => f.id == homeFleetId ? updatedHome : f)
        .toList();
    fleetById[homeFleetId] = updatedHome;
    fleetById.remove(fleet.id);
    return (
      fleets: nextFleets,
      fleetById: fleetById,
      visibilityByTile: nextVis,
    );
  }

  final portRegionId = ProvinceId.regionIdFrom(fullProvinceId);
  final newFleet = Fleet(
    id: fleet.id,
    ownerId: fleet.ownerId,
    seaZoneId: null,
    inPortAtProvinceId: fullProvinceId,
    regionId: portRegionId,
    ships: fleet.ships,
    mission: FleetMission.none,
    targetPortId: null,
    targetProvinceId: null,
  );
  var replacedDockFleet = false;
  final nextFleets = <Fleet>[];
  for (final f in fleets) {
    if (f.id == fleet.id) {
      nextFleets.add(newFleet);
      replacedDockFleet = true;
    } else {
      nextFleets.add(f);
    }
  }
  if (replacedDockFleet) {
    fleetById[fleet.id] = newFleet;
    return (
      fleets: nextFleets,
      fleetById: fleetById,
      visibilityByTile: nextVis,
    );
  }
  return (fleets: fleets, fleetById: fleetById, visibilityByTile: nextVis);
}

({
  List<Fleet> fleets,
  Map<String, Fleet> fleetById,
  Map<String, Map<String, String>> visibilityByTile,
})
_applySeaNavalMoveOrder({
  required Game game,
  required MapTopology topology,
  required List<Fleet> fleets,
  required Map<String, Fleet> fleetById,
  required String playerId,
  required Fleet fleet,
  required NavalMoveOrder order,
  required Map<String, Map<String, String>> visibilityByTile,
}) {
  final destZoneId = order.destinationSeaZoneId;
  if (destZoneId == null || destZoneId.isEmpty) {
    return (
      fleets: fleets,
      fleetById: fleetById,
      visibilityByTile: visibilityByTile,
    );
  }
  if (!seaZoneNodeIds(topology).contains(destZoneId)) {
    return (
      fleets: fleets,
      fleetById: fleetById,
      visibilityByTile: visibilityByTile,
    );
  }
  if (!_navalMoveDestinationIsReachable(
    topology: topology,
    fleet: fleet,
    destZoneId: destZoneId,
  )) {
    return (
      fleets: fleets,
      fleetById: fleetById,
      visibilityByTile: visibilityByTile,
    );
  }

  final destRegionId = regionIdForSeaZone(topology, destZoneId);
  final newFleet = Fleet(
    id: fleet.id,
    ownerId: fleet.ownerId,
    seaZoneId: destZoneId,
    inPortAtProvinceId: null,
    regionId: destRegionId ?? fleet.regionId,
    ships: fleet.ships,
    mission: FleetMission.none,
    targetPortId: null,
    targetProvinceId: null,
  );
  var nextFleets = fleets;
  var replacedAtSea = false;
  final rebuiltAtSea = <Fleet>[];
  for (final f in fleets) {
    if (f.id == fleet.id) {
      rebuiltAtSea.add(newFleet);
      replacedAtSea = true;
    } else {
      rebuiltAtSea.add(f);
    }
  }
  if (replacedAtSea) {
    nextFleets = rebuiltAtSea;
    fleetById[fleet.id] = newFleet;
  }

  var nextVis = visibilityByTile;
  if (destRegionId != null) {
    nextVis = revealTilesAfterMoveToSeaZone(
      game: game,
      topology: topology,
      visibilityByTile: nextVis,
      playerId: playerId,
      destRegionId: destRegionId,
      destZoneId: destZoneId,
    );
  }
  return (fleets: nextFleets, fleetById: fleetById, visibilityByTile: nextVis);
}

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
          playerId: playerId,
          homeFleetId: homeFleetId,
          fleet: fleet,
          order: order,
          visibilityByTile: visibilityByTile,
        );
        fleets = docked.fleets;
        visibilityByTile = docked.visibilityByTile;
        continue;
      }

      final moved = _applySeaNavalMoveOrder(
        game: game,
        topology: topology,
        fleets: fleets,
        fleetById: fleetById,
        playerId: playerId,
        fleet: fleet,
        order: order,
        visibilityByTile: visibilityByTile,
      );
      fleets = moved.fleets;
      visibilityByTile = moved.visibilityByTile;
    }
  }

  return game.copyWith(
    worldState: game.worldState.copyWith(
      fleets: fleets,
      playerVisibilityByTile: visibilityByTile,
    ),
  );
}

String? _navalBattleWinnerOwnerId(
  NavalBattleOutcome outcome,
  BattleContextSea battle,
) {
  switch (outcome) {
    case NavalBattleOutcome.side1Victory:
      return battle.side1.ownerId;
    case NavalBattleOutcome.side2Victory:
      return battle.side2.ownerId;
    case NavalBattleOutcome.stalemate:
    case NavalBattleOutcome.mutualDestruction:
      return null;
  }
}

Game _applyNavalBattleVictoryDossierAndDialogue({
  required Game state,
  required BattleContextSea battle,
  required NavalBattleResult result,
  required int turn,
  required int battleIndex,
  required int seedAfterBattle,
  void Function(DialogueEvent)? onDialogue,
}) {
  String? victorId;
  String? loserId;
  if (result.survivingShipsSide1.isEmpty &&
      result.survivingShipsSide2.isNotEmpty) {
    victorId = battle.side2.ownerId;
    loserId = battle.side1.ownerId;
  } else if (result.survivingShipsSide2.isEmpty &&
      result.survivingShipsSide1.isNotEmpty) {
    victorId = battle.side1.ownerId;
    loserId = battle.side2.ownerId;
  }
  if (victorId == null || loserId == null) return state;

  var next = state;
  final evidence = evidenceForNavalBattleVictory(next, victorId, loserId, turn);
  if (evidence.isNotEmpty) {
    next = next.copyWith(
      dossierEvidenceEntries: [...next.dossierEvidenceEntries, ...evidence],
    );
  }
  final dialogueSeed =
      (seedAfterBattle ^ (battleIndex * kTurnResolutionSeedMix)) &
      kTurnResolutionLcgMask;
  final events = dialogueEventsForNavalBattleResult(
    next,
    victorId,
    loserId,
    turn,
    dialogueSeed,
  );
  if (onDialogue != null && events.isNotEmpty) {
    for (final e in events) {
      onDialogue(e);
    }
  }
  return next;
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
  _log.d('naval phase detected battles=${battles.length}');
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
  _log.d('naval phase after interception battles=${battles.length}');
  seed =
      (seed * kTurnResolutionLcgMultiplier + kTurnResolutionLcgIncrement) &
      kTurnResolutionLcgMask;
  var state = game;
  final turn = game.worldState.turnState.turnNumber;
  var battleIndex = 0;
  for (final battle in battles) {
    final retreatZoneSide1 = _firstFriendlyOrNeutralRetreatZone(
      state,
      topology,
      battle.seaZoneId,
      battle.side1.ownerId,
    );
    final retreatZoneSide2 = _firstFriendlyOrNeutralRetreatZone(
      state,
      topology,
      battle.seaZoneId,
      battle.side2.ownerId,
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
    final zoneRegionId = regionIdForSeaZone(topology, battle.seaZoneId);
    // Single-pass first-match over fleets (Refs #2394): avoids the
    // `.where(...)` lazy chain plus `isEmpty`/`first` re-iteration and bounds
    // the per-battle scan cost regardless of fleet count when the topology
    // resolves the zone region directly. Lookup is extracted to keep nesting
    // within repo.control_flow_nesting_depth limits.
    final regionId =
        zoneRegionId ??
        _firstFleetRegionIdForSeaZone(state, battle.seaZoneId) ??
        kRegionOldWorld;
    state = applyNavalBattleResults(
      state,
      battle,
      result,
      regionId,
      retreatDestinationSide1: retreatZoneSide1,
      retreatDestinationSide2: retreatZoneSide2,
    );
    _log.d(
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
