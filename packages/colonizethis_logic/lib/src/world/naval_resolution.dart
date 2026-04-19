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
import 'topology_helpers.dart';

final _log = packageLogger();

({int x, int y})? _xyFromTileKey(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 4) return null;
  final x = int.tryParse(parts[parts.length - 2]);
  final y = int.tryParse(parts[parts.length - 1]);
  if (x == null || y == null) return null;
  return (x: x, y: y);
}

/// [tileKeysByRegionAndProvince] indexes sea zones by **local** sea id (raster cell id),
/// while turn resolution may use a **combined** topology whose sea node ids are prefixed
/// (`regionId|localSeaId`). Normalize for lookups only; fleet orders still use topology ids.
String _localSeaZoneIdForTileIndex(String seaZoneTopologyId) =>
    ProvinceId.isPrefixed(seaZoneTopologyId)
        ? ProvinceId.localIdFrom(seaZoneTopologyId)
        : seaZoneTopologyId;

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
  final tileKeys =
      game.worldState.tileKeysByRegionAndProvince[regionId]?[fullProvinceId] ??
      const [];
  if (tileKeys.isEmpty) return visibilityByTile;
  final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
  for (final tk in tileKeys) {
    vis[tk] = VisibilityLevel.fullyVisible.name;
  }
  return Map<String, Map<String, String>>.from(visibilityByTile)
    ..[playerId] = vis;
}

Map<String, Set<String>> _atWarByFaction(Game game) {
  final out = <String, Set<String>>{};
  for (final rel in game.diplomacyRelations) {
    if (rel.state != RelationState.atWar) continue;
    out.putIfAbsent(rel.factionId1, () => <String>{}).add(rel.factionId2);
    out.putIfAbsent(rel.factionId2, () => <String>{}).add(rel.factionId1);
  }
  return out;
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
  final hostileByOwner = _atWarByFaction(game);
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

Game applyNavalMissionOrders(
  Game game,
  Map<String, List<NavalMissionOrder>> navalMissionOrdersByPlayerId,
) {
  var fleets = List<Fleet>.from(game.worldState.fleets);
  final fleetById = {for (final f in fleets) f.id: f};

  for (final entry in navalMissionOrdersByPlayerId.entries) {
    final playerId = entry.key;
    for (final order in entry.value) {
      final fleet = fleetById[order.fleetId];
      if (fleet == null || fleet.ownerId != playerId) continue;
      final homeFleetId = homeFleetIdFor(playerId);

      if (order.mission == 'join_home_fleet') {
        final homeFleet = fleetById[homeFleetId];
        if (homeFleet == null) continue;
        // Only fleets in port at the player's capital province can join home fleet. SPEC/game/ships-and-naval.md.
        final capitalProvinceId = game.playerById(playerId)?.capitalProvinceId;
        if (capitalProvinceId == null ||
            fleet.inPortAtProvinceId != capitalProvinceId) {
          continue;
        }
        if (fleet.shipTypeIds.isEmpty) continue;
        final updatedHome = homeFleet.copyWith(
          ships: [...homeFleet.ships, ...fleet.ships],
        );
        fleets = fleets
            .where((f) => f.id != fleet.id)
            .map((f) => f.id == homeFleetId ? updatedHome : f)
            .toList();
        fleetById[homeFleetId] = updatedHome;
        continue;
      }

      if (fleet.id == homeFleetId) {
        continue;
      }
      FleetMission mission = FleetMission.none;
      for (final m in FleetMission.values) {
        if (m.name == order.mission) {
          mission = m;
          break;
        }
      }

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
            fleets = List<Fleet>.from(fleets)..[idx] = cleared;
            fleetById[fleet.id] = cleared;
          }
          continue;
        }
      }

      final newFleet = fleet.copyWith(
        mission: mission,
        targetPortId: order.targetPortId,
        targetProvinceId: order.targetProvinceId,
      );
      final idx = fleets.indexWhere((f) => f.id == fleet.id);
      if (idx >= 0) {
        fleets = List<Fleet>.from(fleets)..[idx] = newFleet;
        fleetById[fleet.id] = newFleet;
      }
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
        // Dock: fleet at sea moves to in port at owned province, or merges into Home Fleet
        // at capital. SPEC/game/ships-and-naval.md, SPEC/program/naval-movement-resolution.md.
        final portProvinceId = order.destinationPortProvinceId!;
        if (!fleet.isAtSea || fleet.seaZoneId == null) continue;
        final fullProvinceId = toFullProvinceId(fleet.regionId, portProvinceId);
        final province = game.worldState.tryGetProvince(fullProvinceId);
        if (province == null || province.ownerId != playerId) continue;
        final adjacentSeaZones = seaZoneIdsAdjacentToProvince(
          topology,
          fullProvinceId,
        );
        if (!adjacentSeaZones.contains(fleet.seaZoneId)) continue;

        visibilityByTile = _revealProvinceTilesForPlayer(
          game,
          visibilityByTile,
          playerId,
          fullProvinceId,
        );

        if (dockOrderTargetsPlayerCapital(game, playerId, fullProvinceId)) {
          final homeFleet = fleetById[homeFleetId];
          if (homeFleet == null) continue;
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
          fleets = fleets
              .where((f) => f.id != fleet.id)
              .map((f) => f.id == homeFleetId ? updatedHome : f)
              .toList();
          fleetById[homeFleetId] = updatedHome;
          fleetById.remove(fleet.id);
          continue;
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
          fleets = List<Fleet>.from(fleets)..[idx] = newFleet;
          fleetById[fleet.id] = newFleet;
        }
        continue;
      }

      // Move to sea zone (S–S) or undock (P–S): destination must be a sea-zone node.
      final destZoneId = order.destinationSeaZoneId;
      if (destZoneId == null || destZoneId.isEmpty) continue;
      if (!seaZoneNodeIds(topology).contains(destZoneId)) continue;

      if (fleet.isAtSea) {
        final cur = fleet.seaZoneId;
        if (cur == null) continue;
        if (cur != destZoneId &&
            !isAdjacentSeaSeaZone(topology, cur, destZoneId)) {
          continue;
        }
      } else {
        final inPortProvinceId = fleet.inPortAtProvinceId;
        if (inPortProvinceId == null) continue;
        final rl = regionAndLocalProvinceForFleetInPort(
          inPortProvinceId,
          fleet.regionId,
        );
        final provinceNodeId = provinceTopologyNodeId(
          topology,
          rl.localId,
          rl.regionId,
        );
        if (provinceNodeId == null) continue;
        if (!seaZonesAdjacentToProvince(
          topology,
          provinceNodeId,
        ).contains(destZoneId)) {
          continue;
        }
      }

      final destRegionId = regionIdForSeaZone(topology, destZoneId);
      // Moving to sea zone: fleet ends at sea (undock if was in port); move clears mission.
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
      final idx = fleets.indexWhere((f) => f.id == fleet.id);
      if (idx >= 0) {
        fleets = List<Fleet>.from(fleets)..[idx] = newFleet;
        fleetById[fleet.id] = newFleet;
      }

      if (destRegionId != null) {
        final provinceIds = provinceIdsAdjacentToSeaZone(
          topology,
          destZoneId,
          regionId: destRegionId,
        );
        final vis = Map<String, String>.from(visibilityByTile[playerId] ?? {});
        final seaZoneKeyForTiles = _localSeaZoneIdForTileIndex(destZoneId);
        final seaWaterKeys = game
            .worldState
            .tileKeysByRegionAndProvince[destRegionId]?[seaZoneKeyForTiles];
        for (final provinceNodeId in provinceIds) {
          final fullProvinceId = toFullProvinceId(destRegionId, provinceNodeId);
          final provinceTileKeys =
              game
                  .worldState
                  .tileKeysByRegionAndProvince[destRegionId]?[fullProvinceId] ??
              [];
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
        visibilityByTile = Map<String, Map<String, String>>.from(
          visibilityByTile,
        )..[playerId] = vis;
      }
    }
  }

  return game.copyWith(
    worldState: game.worldState.copyWith(
      fleets: fleets,
      playerVisibilityByTile: visibilityByTile,
    ),
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
    if (victorId != null && loserId != null) {
      final evidence = evidenceForNavalBattleVictory(
        state,
        victorId,
        loserId,
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
      final dialogueSeed =
          (seed ^ (battleIndex * kTurnResolutionSeedMix)) &
          kTurnResolutionLcgMask;
      final events = dialogueEventsForNavalBattleResult(
        state,
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
    }

    String? winnerOwnerId;
    switch (result.outcome) {
      case NavalBattleOutcome.side1Victory:
        winnerOwnerId = battle.side1.ownerId;
      case NavalBattleOutcome.side2Victory:
        winnerOwnerId = battle.side2.ownerId;
      case NavalBattleOutcome.stalemate:
      case NavalBattleOutcome.mutualDestruction:
        winnerOwnerId = null;
    }
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
