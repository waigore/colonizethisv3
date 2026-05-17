import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
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

/// Single-pass index: sea zone id → fleets whose [Fleet.seaZoneId] equals that
/// zone. Preserves world fleet list order within each bucket (Refs #2394).
Map<String, List<Fleet>> _fleetsBySeaZoneId(List<Fleet> fleets) {
  final out = <String, List<Fleet>>{};
  for (final f in fleets) {
    final z = f.seaZoneId;
    if (z == null) continue;
    out.putIfAbsent(z, () => <Fleet>[]).add(f);
  }
  return out;
}

String? _firstFriendlyOrNeutralRetreatZone(
  MapTopology topology,
  String fromSeaZoneId,
  String ownerId,
  Map<String, Set<String>> hostileByOwner,
  Map<String, List<Fleet>> fleetsBySeaZoneId,
) {
  for (final adj in _adjacentSeaZones(topology, fromSeaZoneId)) {
    var hostileOwnersPresent = false;
    for (final fleet in fleetsBySeaZoneId[adj] ?? const <Fleet>[]) {
      if (!fleet.isAtSea) continue;
      if (fleet.ownerId == ownerId) continue;
      if (hostileByOwner[ownerId]?.contains(fleet.ownerId) ?? false) {
        hostileOwnersPresent = true;
        break;
      }
    }
    if (!hostileOwnersPresent) return adj;
  }
  return null;
}

String? _firstFleetRegionIdForSeaZone(
  String seaZoneId,
  Map<String, List<Fleet>> fleetsBySeaZoneId,
) {
  final inZone = fleetsBySeaZoneId[seaZoneId];
  if (inZone == null || inZone.isEmpty) return null;
  return inZone.first.regionId;
}

Map<String, int> _fleetIndexById(List<Fleet> fleets) => {
  for (var i = 0; i < fleets.length; i++) fleets[i].id: i,
};

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
  Map<String, int> fleetIndexById,
  Map<String, Map<String, String>> visibilityByTile,
})
_applyDockNavalMoveOrder({
  required Game game,
  required MapTopology topology,
  required List<Fleet> fleets,
  required Map<String, Fleet> fleetById,
  required Map<String, int> fleetIndexById,
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
      fleetIndexById: fleetIndexById,
      visibilityByTile: visibilityByTile,
    );
  }
  final fullProvinceId = toFullProvinceId(fleet.regionId, portProvinceId);
  final province = game.worldState.tryGetProvince(fullProvinceId);
  if (province == null || province.ownerId != playerId) {
    return (
      fleets: fleets,
      fleetById: fleetById,
      fleetIndexById: fleetIndexById,
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
      fleetIndexById: fleetIndexById,
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
      return (
        fleets: fleets,
        fleetById: fleetById,
        fleetIndexById: fleetIndexById,
        visibilityByTile: nextVis,
      );
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
    // Single-pass list build (Refs #2394): avoids intermediate lazy chains from
    // `.where` / `.map` when merging a docking fleet into the capital home fleet.
    final nextFleets = <Fleet>[
      for (final f in fleets)
        if (f.id != fleet.id) f.id == homeFleetId ? updatedHome : f,
    ];
    final nextFleetIndexById = _fleetIndexById(nextFleets);
    fleetById[homeFleetId] = updatedHome;
    fleetById.remove(fleet.id);
    return (
      fleets: nextFleets,
      fleetById: fleetById,
      fleetIndexById: nextFleetIndexById,
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
      fleetIndexById: fleetIndexById,
      visibilityByTile: nextVis,
    );
  }
  return (
    fleets: fleets,
    fleetById: fleetById,
    fleetIndexById: fleetIndexById,
    visibilityByTile: nextVis,
  );
}

({
  List<Fleet> fleets,
  Map<String, Fleet> fleetById,
  Map<String, int> fleetIndexById,
  Map<String, Map<String, String>> visibilityByTile,
})
_applySeaNavalMoveOrder({
  required Game game,
  required MapTopology topology,
  required List<Fleet> fleets,
  required Map<String, Fleet> fleetById,
  required Map<String, int> fleetIndexById,
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
      fleetIndexById: fleetIndexById,
      visibilityByTile: visibilityByTile,
    );
  }
  if (!seaZoneNodeIds(topology).contains(destZoneId)) {
    return (
      fleets: fleets,
      fleetById: fleetById,
      fleetIndexById: fleetIndexById,
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
      fleetIndexById: fleetIndexById,
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
  return (
    fleets: nextFleets,
    fleetById: fleetById,
    fleetIndexById: fleetIndexById,
    visibilityByTile: nextVis,
  );
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
  logicLog.d('naval phase detected battles=${battles.length}');
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
  logicLog.d('naval phase after interception battles=${battles.length}');
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
    final zoneRegionId = regionIdForSeaZone(topology, battle.seaZoneId);
    // Single-pass first-match over fleets (Refs #2394): avoids the
    // `.where(...)` lazy chain plus `isEmpty`/`first` re-iteration and bounds
    // the per-battle scan cost regardless of fleet count when the topology
    // resolves the zone region directly. Lookup is extracted to keep nesting
    // within repo.control_flow_nesting_depth limits.
    final regionId =
        zoneRegionId ??
        _firstFleetRegionIdForSeaZone(battle.seaZoneId, fleetsBySeaZoneId) ??
        kRegionOldWorld;
    state = applyNavalBattleResults(
      state,
      battle,
      result,
      regionId,
      retreatDestinationSide1: retreatZoneSide1,
      retreatDestinationSide2: retreatZoneSide2,
    );
    logicLog.d(
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
