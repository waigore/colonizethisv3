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
import 'player_view.dart';
import 'province_lookup.dart';
import 'sea_zone_identity.dart';
import 'tile_key_coordinates.dart';
import 'topology_helpers.dart';

final _log = packageLogger();

({int x, int y})? _xyFromTileKey(String tileKey) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return null;
  return (x: coords.x, y: coords.y);
}

/// Canonical key used for sea-zone buckets in
/// `tileKeysByRegionAndProvince[regionId][bucketKey]`.
///
/// Buckets must be keyed by prefixed sea-zone id (`regionId|localSeaId`) so
/// topology ids from both per-region and combined topologies resolve through one
/// contract.
String canonicalSeaZoneTileBucketKey(
  String regionId,
  String seaZoneTopologyId,
) => canonicalizeSeaZoneId(regionId: regionId, seaZoneId: seaZoneTopologyId);

/// [tileKeysByRegionAndProvince] normally keys land provinces by full id
/// (`regionId|localId`); some fixtures or legacy maps key by **local** id only.
/// Ship reveal and dock visibility must resolve tiles using whichever bucket exists.
List<String> landTileKeysForProvinceBucket(
  WorldState ws,
  String regionId,
  String fullProvinceId,
) {
  final byProv = ws.tileKeysByRegionAndProvince[regionId];
  if (byProv == null) return const [];
  final byFull = byProv[fullProvinceId];
  if (byFull != null && byFull.isNotEmpty) {
    return byFull;
  }
  final localId = ProvinceId.localIdFrom(fullProvinceId);
  return byProv[localId] ?? const [];
}

Set<String> _coastalTileKeysAdjacentToSeaZone({
  required List<String> provinceTileKeys,
  required List<String> seaWaterTileKeys,
}) {
  if (provinceTileKeys.isEmpty || seaWaterTileKeys.isEmpty) return const {};
  final seaCoords = <String>{};
  for (final seaTileKey in seaWaterTileKeys) {
    final xy = _xyFromTileKey(seaTileKey);
    if (xy == null) continue;
    seaCoords.add('${xy.x}|${xy.y}');
  }
  if (seaCoords.isEmpty) return const {};
  final coastal = <String>{};
  const deltas = [(0, -1), (1, 0), (0, 1), (-1, 0)];
  for (final provinceTileKey in provinceTileKeys) {
    final xy = _xyFromTileKey(provinceTileKey);
    if (xy == null) continue;
    final isCoastal = deltas.any(
      (delta) => seaCoords.contains('${xy.x + delta.$1}|${xy.y + delta.$2}'),
    );
    if (isCoastal) coastal.add(provinceTileKey);
  }
  return coastal;
}

Map<String, Map<String, String>> _revealProvinceTilesForPlayer(
  Game game,
  Map<String, Map<String, String>> visibilityByTile,
  String playerId,
  String fullProvinceId,
) {
  final regionId = ProvinceId.regionIdFrom(fullProvinceId);
  final tileKeys = landTileKeysForProvinceBucket(
    game.worldState,
    regionId,
    fullProvinceId,
  );
  if (tileKeys.isEmpty) return visibilityByTile;
  final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
  for (final tk in tileKeys) {
    vis[tk] = VisibilityLevel.fullyVisible.name;
  }
  return Map<String, Map<String, String>>.from(visibilityByTile)
    ..[playerId] = vis;
}

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

FleetMission _fleetMissionFromOrderName(String name) {
  for (final m in FleetMission.values) {
    if (m.name == name) return m;
  }
  return FleetMission.none;
}

List<Fleet> _applySingleNavalMissionOrder({
  required Game game,
  required List<Fleet> fleets,
  required Map<String, Fleet> fleetById,
  required String playerId,
  required NavalMissionOrder order,
}) {
  final fleet = fleetById[order.fleetId];
  if (fleet == null || fleet.ownerId != playerId) return fleets;
  final homeFleetId = homeFleetIdFor(playerId);

  if (order.mission == 'join_home_fleet') {
    final homeFleet = fleetById[homeFleetId];
    if (homeFleet == null) return fleets;
    final capitalProvinceId = game.playerById(playerId)?.capitalProvinceId;
    if (capitalProvinceId == null ||
        fleet.inPortAtProvinceId != capitalProvinceId) {
      return fleets;
    }
    if (fleet.shipTypeIds.isEmpty) return fleets;
    final updatedHome = homeFleet.copyWith(
      ships: [...homeFleet.ships, ...fleet.ships],
    );
    final next = fleets
        .where((f) => f.id != fleet.id)
        .map((f) => f.id == homeFleetId ? updatedHome : f)
        .toList();
    fleetById[homeFleetId] = updatedHome;
    return next;
  }

  if (fleet.id == homeFleetId) {
    return fleets;
  }
  final mission = _fleetMissionFromOrderName(order.mission);

  if (mission == FleetMission.blockade) {
    final targetProvinceId = order.targetProvinceId;
    final province =
        targetProvinceId != null &&
            targetProvinceId.isNotEmpty &&
            ProvinceId.isPrefixed(targetProvinceId)
        ? game.worldState.tryGetProvince(targetProvinceId)
        : null;
    final ownerId = province?.ownerId;
    final atWar =
        ownerId != null &&
        ownerId != playerId &&
        factionsAtWar(game, playerId, ownerId);
    if (!atWar) {
      final cleared = fleet.copyWith(
        mission: FleetMission.none,
        targetPortId: null,
        targetProvinceId: null,
      );
      final idx = fleets.indexWhere((f) => f.id == fleet.id);
      if (idx >= 0) {
        final next = List<Fleet>.from(fleets)..[idx] = cleared;
        fleetById[fleet.id] = cleared;
        return next;
      }
      return fleets;
    }
  }

  final newFleet = fleet.copyWith(
    mission: mission,
    targetPortId: order.targetPortId,
    targetProvinceId: order.targetProvinceId,
  );
  final idx = fleets.indexWhere((f) => f.id == fleet.id);
  if (idx >= 0) {
    final next = List<Fleet>.from(fleets)..[idx] = newFleet;
    fleetById[fleet.id] = newFleet;
    return next;
  }
  return fleets;
}

Game applyNavalMissionOrders(
  Game game,
  Map<String, List<NavalMissionOrder>> navalMissionOrdersByPlayerId,
) {
  var fleets = List<Fleet>.from(game.worldState.fleets);
  final fleetById = {for (final f in fleets) f.id: f};

  for (final entry in navalMissionOrdersByPlayerId.entries) {
    final playerId = entry.key;
    for (final order in entry.value) {
      fleets = _applySingleNavalMissionOrder(
        game: game,
        fleets: fleets,
        fleetById: fleetById,
        playerId: playerId,
        order: order,
      );
    }
  }

  for (var i = 0; i < fleets.length; i++) {
    final f = fleets[i];
    if (f.mission != FleetMission.blockade) continue;
    final targetProvinceId = f.targetProvinceId;
    if (targetProvinceId == null || targetProvinceId.isEmpty) continue;
    final province = ProvinceId.isPrefixed(targetProvinceId)
        ? game.worldState.tryGetProvince(targetProvinceId)
        : null;
    final ownerId = province?.ownerId;
    final atWar =
        ownerId != null &&
        ownerId != f.ownerId &&
        factionsAtWar(game, f.ownerId, ownerId);
    if (!atWar) {
      fleets = List<Fleet>.from(fleets)
        ..[i] = f.copyWith(
          mission: FleetMission.none,
          targetPortId: null,
          targetProvinceId: null,
        );
    }
  }

  return game.copyWith(worldState: game.worldState.copyWith(fleets: fleets));
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

Map<String, Map<String, String>> _revealTilesAfterMoveToSeaZone({
  required Game game,
  required MapTopology topology,
  required Map<String, Map<String, String>> visibilityByTile,
  required String playerId,
  required String destRegionId,
  required String destZoneId,
}) {
  final provinceIds = provinceIdsAdjacentToSeaZone(
    topology,
    destZoneId,
    regionId: destRegionId,
  );
  final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
  final seaZoneKeyForTiles = canonicalSeaZoneTileBucketKey(
    destRegionId,
    destZoneId,
  );
  final seaWaterKeys = game
      .worldState
      .tileKeysByRegionAndProvince[destRegionId]?[seaZoneKeyForTiles];
  for (final provinceNodeId in provinceIds) {
    final fullProvinceId = toFullProvinceId(destRegionId, provinceNodeId);
    final provinceTileKeys = landTileKeysForProvinceBucket(
      game.worldState,
      destRegionId,
      fullProvinceId,
    );
    final coastalTileKeys = _coastalTileKeysAdjacentToSeaZone(
      provinceTileKeys: provinceTileKeys,
      seaWaterTileKeys: seaWaterKeys ?? const [],
    );
    for (final tk in coastalTileKeys) {
      vis[tk] = VisibilityLevel.fullyVisible.name;
    }
  }
  if (seaWaterKeys != null) {
    for (final tk in seaWaterKeys) {
      vis[tk] = VisibilityLevel.fullyVisible.name;
    }
  }
  return Map<String, Map<String, String>>.from(visibilityByTile)
    ..[playerId] = vis;
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

  var nextVis = _revealProvinceTilesForPlayer(
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
  final idx = fleets.indexWhere((f) => f.id == fleet.id);
  if (idx >= 0) {
    final nextFleets = List<Fleet>.from(fleets)..[idx] = newFleet;
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
  final idx = fleets.indexWhere((f) => f.id == fleet.id);
  if (idx >= 0) {
    nextFleets = List<Fleet>.from(fleets)..[idx] = newFleet;
    fleetById[fleet.id] = newFleet;
  }

  var nextVis = visibilityByTile;
  if (destRegionId != null) {
    nextVis = _revealTilesAfterMoveToSeaZone(
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

/// Land tile keys orthogonally adjacent to water in sea zones where [playerId] has
/// a non–home fleet **at sea**. Same geometry as ship reveal in this file; used so
/// [applyFogDecay] does not strip that coastal intel while the fleet remains offshore.
Set<String> coastalLandTileKeysFromNavalPresenceAtSea(
  Game game,
  MapTopology topology,
  String playerId,
) {
  final out = <String>{};
  final ws = game.worldState;
  final homeFleetId = homeFleetIdFor(playerId);
  for (final f in ws.fleets) {
    if (f.ownerId != playerId) continue;
    if (f.id == homeFleetId) continue;
    if (!f.isAtSea || f.seaZoneId == null) continue;
    final destRegionId = f.regionId;
    final destZoneId = f.seaZoneId!;
    final provinceIds = provinceIdsAdjacentToSeaZone(
      topology,
      destZoneId,
      regionId: destRegionId,
    );
    final seaZoneKeyForTiles = canonicalSeaZoneTileBucketKey(
      destRegionId,
      destZoneId,
    );
    final seaWaterKeys =
        ws.tileKeysByRegionAndProvince[destRegionId]?[seaZoneKeyForTiles] ??
        const <String>[];
    for (final provinceNodeId in provinceIds) {
      final fullProvinceId = toFullProvinceId(destRegionId, provinceNodeId);
      final provinceTileKeys = landTileKeysForProvinceBucket(
        ws,
        destRegionId,
        fullProvinceId,
      );
      out.addAll(
        _coastalTileKeysAdjacentToSeaZone(
          provinceTileKeys: provinceTileKeys,
          seaWaterTileKeys: seaWaterKeys,
        ),
      );
    }
  }
  return out;
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
    final fleetsInZone = state.worldState.fleets.where(
      (f) => f.seaZoneId == battle.seaZoneId,
    );
    final regionId =
        zoneRegionId ??
        (fleetsInZone.isEmpty ? null : fleetsInZone.first.regionId) ??
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
