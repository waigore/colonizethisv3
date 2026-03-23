import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../combat/naval_combat_resolver.dart';
import '../constants.dart';
import '../diplomacy/diplomacy_relation_lookup.dart';
import '../dossier/evidence_rules.dart';
import '../dossier/event_dialogue.dart';
import 'naval.dart';
import 'player_view.dart';
import 'province_lookup.dart';

final _log = logicLogger();

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
        final capitalProvinceId = game.players
            .where((p) => p.id == playerId)
            .map((p) => p.capitalProvinceId)
            .firstOrNull;
        if (capitalProvinceId == null ||
            fleet.inPortAtProvinceId != capitalProvinceId) continue;
        if (fleet.shipTypeIds.isEmpty) continue;
        final updatedHome = homeFleet.copyWith(
          shipTypeIds: [...homeFleet.shipTypeIds, ...fleet.shipTypeIds],
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
        final province = targetProvinceId != null &&
                targetProvinceId.isNotEmpty &&
                ProvinceId.isPrefixed(targetProvinceId)
            ? tryGetProvince(game.worldState, targetProvinceId)
            : null;
        final ownerId = province?.ownerId;
        final atWar =
            ownerId != null && ownerId != playerId && factionsAtWar(game, playerId, ownerId);
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
        ? tryGetProvince(game.worldState, targetProvinceId)
        : null;
    final ownerId = province?.ownerId;
    final atWar =
        ownerId != null && ownerId != f.ownerId && factionsAtWar(game, f.ownerId, ownerId);
    if (!atWar) {
      fleets = List<Fleet>.from(fleets)
        ..[i] = f.copyWith(
          mission: FleetMission.none,
          targetPortId: null,
          targetProvinceId: null,
        );
    }
  }

  return game.copyWith(
    worldState: game.worldState.copyWith(fleets: fleets),
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

  for (final entry in navalMoveOrdersByPlayerId.entries) {
    final playerId = entry.key;
    for (final order in entry.value) {
      final fleet = fleetById[order.fleetId];
      if (fleet == null || fleet.ownerId != playerId) continue;
      final homeFleetId = homeFleetIdFor(playerId);

      if (fleet.id == homeFleetId) continue;

      if (order.isDock) {
        // Dock: fleet at sea moves to in port at owned province. SPEC/game/ships-and-naval.md.
        final portProvinceId = order.destinationPortProvinceId!;
        if (!fleet.isAtSea || fleet.seaZoneId == null) continue;
        final fullProvinceId = toFullProvinceId(fleet.regionId, portProvinceId);
        final province = tryGetProvince(game.worldState, fullProvinceId);
        if (province == null || province.ownerId != playerId) continue;
        final adjacentSeaZones = seaZoneIdsAdjacentToProvince(topology, fullProvinceId);
        if (!adjacentSeaZones.contains(fleet.seaZoneId)) continue;
        final portRegionId = ProvinceId.regionIdFrom(fullProvinceId);
        final newFleet = Fleet(
          id: fleet.id,
          ownerId: fleet.ownerId,
          seaZoneId: null,
          inPortAtProvinceId: fullProvinceId,
          regionId: portRegionId,
          shipTypeIds: fleet.shipTypeIds,
          mission: fleet.mission,
          targetPortId: fleet.targetPortId,
          targetProvinceId: fleet.targetProvinceId,
        );
        final idx = fleets.indexWhere((f) => f.id == fleet.id);
        if (idx >= 0) {
          fleets = List<Fleet>.from(fleets)..[idx] = newFleet;
          fleetById[fleet.id] = newFleet;
        }
        continue;
      }

      // Move to sea zone (or undock from port).
      final String? currentSeaZoneId;
      if (fleet.isAtSea) {
        currentSeaZoneId = fleet.seaZoneId;
      } else {
        // Fleet in port: adjacency is from the port's sea zone.
        final inPortProvinceId = fleet.inPortAtProvinceId;
        if (inPortProvinceId == null) continue;
        final rl = regionAndLocalProvinceForFleetInPort(
          inPortProvinceId,
          fleet.regionId,
        );
        currentSeaZoneId = seaZoneIdForProvince(
          topology,
          rl.localId,
          regionId: rl.regionId,
        );
      }
      final destZoneId = order.destinationSeaZoneId;
      if (currentSeaZoneId == null || destZoneId == null || destZoneId.isEmpty) continue;
      if (currentSeaZoneId != destZoneId &&
          !isAdjacentSeaZone(topology, currentSeaZoneId, destZoneId)) continue;

      final destRegionId = regionIdForSeaZone(topology, destZoneId);
      // Moving to sea zone: fleet ends at sea (undock if was in port).
      final newFleet = Fleet(
        id: fleet.id,
        ownerId: fleet.ownerId,
        seaZoneId: destZoneId,
        inPortAtProvinceId: null,
        regionId: destRegionId ?? fleet.regionId,
        shipTypeIds: fleet.shipTypeIds,
        mission: fleet.mission,
        targetPortId: fleet.targetPortId,
        targetProvinceId: fleet.targetProvinceId,
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
        for (final localProvinceId in provinceIds) {
          final fullProvinceId = ProvinceId.full(destRegionId, localProvinceId);
          final tileKeys = game.worldState
                  .tileKeysByRegionAndProvince[destRegionId]?[fullProvinceId] ??
              [];
          for (final tk in tileKeys) {
            vis[tk] = VisibilityLevel.revealed.name;
          }
        }
        visibilityByTile =
            Map<String, Map<String, String>>.from(visibilityByTile)
              ..[playerId] = vis;
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
  void Function(DialogueEvent)? onDialogue,
}) {
  var battles = detectNavalConflicts(game);
  _log.d('logic: naval phase detected battles=${battles.length}');
  final movedFleetIds = <String>{
    for (final list in navalMoveOrdersByPlayerId.values)
      for (final order in list) order.fleetId,
  };
  var seed = (game.globalGameSeed ?? 0) ^
      (game.worldState.turnState.turnNumber * 0x9E3779B1);
  battles = filterBattlesByInterception(game, battles, movedFleetIds, seed);
  _log.d('logic: naval phase after interception battles=${battles.length}');
  seed = (seed * 1103515245 + 12345) & 0x7fffffff;
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
    );
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    final zoneRegionId = regionIdForSeaZone(topology, battle.seaZoneId);
    final fleetsInZone =
        state.worldState.fleets.where((f) => f.seaZoneId == battle.seaZoneId);
    final regionId = zoneRegionId ??
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
      'logic: naval phase battle zone=${battle.seaZoneId} outcome=${result.outcome.name} '
      'side1Retreated=${result.side1Retreated} side2Retreated=${result.side2Retreated}',
    );

    String? victorId;
    String? loserId;
    if (result.survivingShipTypeIdsSide1.isEmpty &&
        result.survivingShipTypeIdsSide2.isNotEmpty) {
      victorId = battle.side2.ownerId;
      loserId = battle.side1.ownerId;
    } else if (result.survivingShipTypeIdsSide2.isEmpty &&
        result.survivingShipTypeIdsSide1.isNotEmpty) {
      victorId = battle.side1.ownerId;
      loserId = battle.side2.ownerId;
    }
    if (victorId != null && loserId != null) {
      final evidence =
          evidenceForNavalBattleVictory(state, victorId, loserId, turn);
      if (evidence.isNotEmpty) {
        state = state.copyWith(dossierEvidenceEntries: [
          ...state.dossierEvidenceEntries,
          ...evidence
        ]);
      }
      final dialogueSeed = (seed ^ (battleIndex * 0x9E3779B1)) & 0x7fffffff;
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
    battleIndex++;
  }
  return state;
}
