import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomacy/diplomacy_resolver.dart';
import '../world/naval.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import '../world/topology_helpers.dart';
import 'order_suggestion_context.dart';
import 'orders_application_helpers.dart';

void _addAcceptedSeaZoneCandidates({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders currentOrders,
  required Fleet fleet,
  required String cur,
  required Map<String, Set<String>> existingByFleet,
  required List<NavalMoveOrder> suggestions,
}) {
  for (final node in topology.nodes) {
    if (node.type != TopologyNodeType.seaZone) continue;
    final destId = node.id;
    if (cur != destId && !isAdjacentSeaSeaZone(topology, cur, destId)) {
      continue;
    }
    if (existingByFleet[fleet.id]?.contains(destId) ?? false) continue;
    final candidate = NavalMoveOrder(
      fleetId: fleet.id,
      destinationSeaZoneId: destId,
    );
    if (isNavalMoveOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
    )) {
      suggestions.add(candidate);
    }
  }
}

void _addAcceptedDockCandidatesForSeaFleet({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders currentOrders,
  required Fleet fleet,
  required String cur,
  required Map<String, Set<String>> existingByFleet,
  required List<NavalMoveOrder> suggestions,
}) {
  final zoneRegionId = regionIdForSeaZone(topology, cur);
  if (zoneRegionId == null) return;
  final adjacentLocalIds = provinceIdsAdjacentToSeaZone(
    topology,
    cur,
    regionId: zoneRegionId,
  );
  for (final localId in adjacentLocalIds) {
    final fullProvinceId = ProvinceId.isPrefixed(localId)
        ? localId
        : ProvinceId.full(zoneRegionId, localId);
    if (existingByFleet[fleet.id]?.contains('port:$fullProvinceId') ?? false) {
      continue;
    }
    final province = game.worldState.tryGetProvince(fullProvinceId);
    if (province?.ownerId != playerId) continue;
    final candidate = NavalMoveOrder(
      fleetId: fleet.id,
      destinationPortProvinceId: fullProvinceId,
    );
    if (isNavalMoveOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
    )) {
      suggestions.add(candidate);
    }
  }
}

void _addAcceptedMovesFromPortFleet({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders currentOrders,
  required Fleet fleet,
  required Map<String, Set<String>> existingByFleet,
  required List<NavalMoveOrder> suggestions,
}) {
  final inPortProvinceId = fleet.inPortAtProvinceId;
  if (inPortProvinceId == null) return;
  final rl = regionAndLocalProvinceForFleetInPort(
    inPortProvinceId,
    fleet.regionId,
  );
  final pNode = provinceTopologyNodeId(topology, rl.localId, rl.regionId);
  if (pNode == null) return;
  for (final destId in seaZonesAdjacentToProvince(topology, pNode)) {
    if (existingByFleet[fleet.id]?.contains(destId) ?? false) continue;
    final candidate = NavalMoveOrder(
      fleetId: fleet.id,
      destinationSeaZoneId: destId,
    );
    if (isNavalMoveOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
    )) {
      suggestions.add(candidate);
    }
  }
}

/// Suggests naval move orders for fleets owned by [view.playerId]. SPEC/program/naval-movement-resolution.md.
List<NavalMoveOrder> suggestNavalMoveOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  orderSuggestionLog.d('suggestNavalMoveOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <NavalMoveOrder>[];
  final existingByFleet = <String, Set<String>>{};
  for (final o
      in currentOrders.navalMoveOrdersByPlayerId[playerId] ?? const []) {
    final key = o.isDock
        ? 'port:${o.destinationPortProvinceId}'
        : (o.destinationSeaZoneId ?? '');
    if (key.isNotEmpty) {
      existingByFleet.putIfAbsent(o.fleetId, () => <String>{}).add(key);
    }
  }

  final homeFleetId = homeFleetIdFor(playerId);
  for (final fleet in game.worldState.fleets) {
    if (fleet.ownerId != playerId || fleet.id == homeFleetId) continue;
    if (fleet.isAtSea) {
      final cur = fleet.seaZoneId;
      if (cur == null) continue;
      _addAcceptedSeaZoneCandidates(
        game: game,
        topology: topology,
        playerId: playerId,
        currentOrders: currentOrders,
        fleet: fleet,
        cur: cur,
        existingByFleet: existingByFleet,
        suggestions: suggestions,
      );
      _addAcceptedDockCandidatesForSeaFleet(
        game: game,
        topology: topology,
        playerId: playerId,
        currentOrders: currentOrders,
        fleet: fleet,
        cur: cur,
        existingByFleet: existingByFleet,
        suggestions: suggestions,
      );
    } else {
      _addAcceptedMovesFromPortFleet(
        game: game,
        topology: topology,
        playerId: playerId,
        currentOrders: currentOrders,
        fleet: fleet,
        existingByFleet: existingByFleet,
        suggestions: suggestions,
      );
    }
  }

  suggestions.sort((a, b) {
    final c = a.fleetId.compareTo(b.fleetId);
    if (c != 0) return c;
    final keyA = a.isDock
        ? 'port:${a.destinationPortProvinceId}'
        : (a.destinationSeaZoneId ?? '');
    final keyB = b.isDock
        ? 'port:${b.destinationPortProvinceId}'
        : (b.destinationSeaZoneId ?? '');
    return keyA.compareTo(keyB);
  });
  orderSuggestionLog.d(
    'suggestNavalMoveOrders player=$playerId candidates=${suggestions.length}',
  );
  orderSuggestionLog.d(
    'suggestNavalMoveOrders full list ${suggestions.map((o) => "fleetId=${o.fleetId} destSea=${o.destinationSeaZoneId} destPort=${o.destinationPortProvinceId}").join(", ")}',
  );
  return suggestions;
}

/// Suggests naval mission orders for fleets owned by [view.playerId]. Phase 6.
List<NavalMissionOrder> suggestNavalMissionOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  orderSuggestionLog.d('suggestNavalMissionOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <NavalMissionOrder>[];
  final existingByFleet = <String>{};
  for (final o
      in currentOrders.navalMissionOrdersByPlayerId[playerId] ?? const []) {
    existingByFleet.add(o.fleetId);
  }

  for (final fleet in game.worldState.fleets) {
    if (fleet.ownerId != playerId) continue;
    if (existingByFleet.contains(fleet.id)) continue;
    for (final mission in FleetMission.values) {
      final candidate = NavalMissionOrder(
        fleetId: fleet.id,
        mission: mission.name,
      );
      if (isNavalMissionOrderAccepted(
        game,
        topology,
        playerId,
        currentOrders,
        candidate,
      )) {
        suggestions.add(candidate);
      }
    }
  }

  suggestions.sort((a, b) {
    final c = a.fleetId.compareTo(b.fleetId);
    if (c != 0) return c;
    return a.mission.compareTo(b.mission);
  });
  orderSuggestionLog.d(
    'suggestNavalMissionOrders player=$playerId candidates=${suggestions.length}',
  );
  orderSuggestionLog.d(
    'suggestNavalMissionOrders full list ${suggestions.map((o) => "fleetId=${o.fleetId} mission=${o.mission}").join(", ")}',
  );
  return suggestions;
}

/// Trial append for suggestion enumeration. SPEC/program/order-suggestions.md.
Orders _appendDiplomaticOrderForTrial(
  Orders orders,
  String playerId,
  DiplomaticOrder order,
) {
  final prev =
      orders.diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[];
  return orders.copyWith(
    diplomaticOrdersByPlayerId: {
      ...orders.diplomaticOrdersByPlayerId,
      playerId: [...prev, order],
    },
  );
}

/// Next overture stage for suggestion (none→tradeConsulate→embassy→nap→joinEmpire).
OvertureStage? _nextOvertureStage(OvertureStage current) {
  switch (current) {
    case OvertureStage.none:
      return OvertureStage.tradeConsulate;
    case OvertureStage.tradeConsulate:
      return OvertureStage.embassy;
    case OvertureStage.embassy:
      return OvertureStage.nap;
    case OvertureStage.nap:
      return OvertureStage.joinEmpire;
    case OvertureStage.joinEmpire:
      return null;
  }
}

/// Per-target suggestion order: first candidate that passes the order engine wins.
/// SPEC/program/order-suggestions.md § Diplomatic orders.
List<DiplomaticOrder> _diplomaticCandidatesForTargetOrdered({
  required Game game,
  required String playerId,
  required Player player,
  required String targetId,
  required Set<String> knownTargetIds,
  required Set<String> knownFactionIds,
}) {
  final treasury = player.treasury;
  final out = <DiplomaticOrder>[];
  if (targetId == playerId) return out;

  final rel = getRelation(game, playerId, targetId);
  final atWar = rel?.atWar ?? false;
  final atPeace = rel == null || rel.atPeace;
  final isGpTarget = game.players.any((p) => p.id == targetId);
  final isMinorOrTribe =
      game.minorNations.any((m) => m.id == targetId) ||
      game.tribes.any((t) => t.id == targetId);

  if (knownTargetIds.contains(targetId) && atWar) {
    out.add(
      DiplomaticOrder(
        type: DiplomaticOrderType.offerPeace,
        targetFactionId: targetId,
      ),
    );
  }
  if (isGpTarget &&
      rel != null &&
      rel.atPeace &&
      rel.level != RelationLevel.allied) {
    out.add(
      DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: targetId,
      ),
    );
  }
  if (isMinorOrTribe && knownFactionIds.contains(targetId)) {
    final overtureOrder = _establishOvertureSuggestionOrder(
      game: game,
      playerId: playerId,
      targetId: targetId,
      treasury: treasury,
    );
    if (overtureOrder != null) out.add(overtureOrder);
  }

  OvertureState? overtureRow;
  for (final o in game.overtureStates) {
    if (o.gpId == playerId && o.targetId == targetId) {
      overtureRow = o;
      break;
    }
  }
  if (overtureRow != null) {
    if (overtureRow.hasEmbassy && treasury >= grantAidDefaultAmount) {
      out.add(
        DiplomaticOrder(
          type: DiplomaticOrderType.grantAid,
          targetFactionId: targetId,
          amount: grantAidDefaultAmount,
        ),
      );
    }
    if (overtureRow.hasConsulate && treasury >= setSubsidyDefaultAmount) {
      out.add(
        DiplomaticOrder(
          type: DiplomaticOrderType.setSubsidy,
          targetFactionId: targetId,
          amount: setSubsidyDefaultAmount,
        ),
      );
    }
  }

  if (knownTargetIds.contains(targetId) && atPeace) {
    out.add(
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: targetId,
      ),
    );
  }

  return out;
}

DiplomaticOrder? _establishOvertureSuggestionOrder({
  required Game game,
  required String playerId,
  required String targetId,
  required int treasury,
}) {
  final rel = getRelation(game, playerId, targetId);
  final atWar = rel?.atWar ?? false;
  if (atWar) return null;

  final existing = getOverture(game, playerId, targetId);
  final current = existing?.stage ?? OvertureStage.none;
  final next = _nextOvertureStage(current);
  if (next == null) return null;
  if (next == OvertureStage.tradeConsulate || next == OvertureStage.embassy) {
    final cost = next == OvertureStage.tradeConsulate
        ? overtureConsulateCost
        : overtureEmbassyCost;
    if (treasury < cost) return null;
  }
  if (next == OvertureStage.tradeConsulate ||
      next == OvertureStage.embassy ||
      next == OvertureStage.nap) {
    Player? submitter;
    for (final p in game.players) {
      if (p.id == playerId) {
        submitter = p;
        break;
      }
    }
    if (submitter?.techUnlocked?[kTechIdDiplomaticExpertise] != true) {
      return null;
    }
  }
  if (next == OvertureStage.joinEmpire) {
    final score = rel?.score ?? relationScoreNeutral;
    if (score < relationScoreMinFriendly) return null;
    final cost = joinEmpireCostForMinorOrTribe(game, targetId);
    if (treasury < cost) return null;
  }
  return DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: targetId,
    overtureStage: next,
  );
}

/// Suggests candidate diplomatic orders that are valid and visible for [view.playerId].
/// SPEC/program/order-suggestions.md; SPEC/program/ai-systems-impl.md.
List<DiplomaticOrder> suggestDiplomaticOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  orderSuggestionLog.d('suggestDiplomaticOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <DiplomaticOrder>[];
  final player = view.player;

  // Determine which factions are actually "known" to this player per SPEC:
  // - Any faction with an existing DiplomacyRelation to the player.
  // - Any faction that owns at least one province with a tile visible to the player.
  // Self is never a diplomatic target.
  final knownFactionIds = <String>{};

  for (final rel in game.diplomacyRelations) {
    if (rel.factionId1 == playerId) {
      knownFactionIds.add(rel.factionId2);
    } else if (rel.factionId2 == playerId) {
      knownFactionIds.add(rel.factionId1);
    }
  }

  for (final entry in view.visibilityByTile.entries) {
    if (entry.value == VisibilityLevel.unknown) continue;
    final parsed = parseTileKeyCoordinates(entry.key);
    if (parsed == null) continue;
    final regionId = parsed.regionId;
    final provinceLocalId = parsed.provinceLocalId;
    final provinceId = ProvinceId.full(regionId, provinceLocalId);
    final province = view.provinceByRegionAndId(regionId, provinceId);
    final ownerId = province?.ownerId;
    if (ownerId != null && ownerId != playerId) {
      knownFactionIds.add(ownerId);
    }
  }

  final otherGps = game.players
      .where((p) => p.id != playerId)
      .map((p) => p.id)
      .toSet();
  final minorIds = game.minorNations.map((m) => m.id).toSet();
  final tribeIds = game.tribes.map((t) => t.id).toSet();
  final knownTargets = <String>{
    ...otherGps.where(knownFactionIds.contains),
    ...minorIds.where(knownFactionIds.contains),
    ...tribeIds.where(knownFactionIds.contains),
  };
  final knownTargetIds = knownTargets.toSet();

  final unionTargets = <String>{
    ...knownTargets,
    ...otherGps,
    for (final o in game.overtureStates)
      if (o.gpId == playerId) o.targetId,
  };

  final sortedTargetIds = unionTargets.toList()..sort();
  var workingOrders = currentOrders;
  for (final targetId in sortedTargetIds) {
    if (targetId == playerId) continue;

    final candidates = _diplomaticCandidatesForTargetOrdered(
      game: game,
      playerId: playerId,
      player: player,
      targetId: targetId,
      knownTargetIds: knownTargetIds,
      knownFactionIds: knownFactionIds,
    );
    var trialOrders = workingOrders;

    for (final candidate in candidates) {
      if (candidate.type == DiplomaticOrderType.grantAid ||
          candidate.type == DiplomaticOrderType.setSubsidy) {
        continue;
      }
      if (!isDiplomaticOrderAccepted(
        game,
        topology,
        playerId,
        trialOrders,
        candidate,
        tileMapByRegion: tileMapByRegion,
      )) {
        continue;
      }
      suggestions.add(candidate);
      trialOrders = _appendDiplomaticOrderForTrial(
        trialOrders,
        playerId,
        candidate,
      );
      break;
    }

    for (final candidate in candidates) {
      if (candidate.type != DiplomaticOrderType.grantAid &&
          candidate.type != DiplomaticOrderType.setSubsidy) {
        continue;
      }
      if (!isDiplomaticOrderAccepted(
        game,
        topology,
        playerId,
        trialOrders,
        candidate,
        tileMapByRegion: tileMapByRegion,
      )) {
        continue;
      }
      suggestions.add(candidate);
      trialOrders = _appendDiplomaticOrderForTrial(
        trialOrders,
        playerId,
        candidate,
      );
    }

    workingOrders = trialOrders;
  }

  suggestions.sort((a, b) {
    final t = a.type.index.compareTo(b.type.index);
    if (t != 0) return t;
    final idCmp = a.targetFactionId.compareTo(b.targetFactionId);
    if (idCmp != 0) return idCmp;
    final stageCmp = (a.overtureStage?.index ?? -1).compareTo(
      b.overtureStage?.index ?? -1,
    );
    if (stageCmp != 0) return stageCmp;
    return (a.amount ?? 0).compareTo(b.amount ?? 0);
  });
  orderSuggestionLog.d(
    'suggestDiplomaticOrders player=$playerId candidates=${suggestions.length}',
  );
  orderSuggestionLog.d(
    'suggestDiplomaticOrders full list ${suggestions.map((o) => "${o.type.name}:${o.targetFactionId}").join(", ")}',
  );
  return suggestions;
}
