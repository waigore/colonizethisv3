import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../world/naval.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import '../world/topology_helpers.dart';
import '../world/unit_lookup.dart';
import 'incremental_candidate_validator.dart';
import 'order_suggestion_context.dart';
import 'orders_application_helpers.dart';

void _addAcceptedSeaZoneCandidates({
  required IncrementalCandidateValidator candidateValidator,
  required MapTopology topology,
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
    if (candidateValidator.isNavalMoveAccepted(candidate)) {
      suggestions.add(candidate);
    }
  }
}

void _addAcceptedDockCandidatesForSeaFleet({
  required IncrementalCandidateValidator candidateValidator,
  required Game game,
  required MapTopology topology,
  required String playerId,
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
    if (candidateValidator.isNavalMoveAccepted(candidate)) {
      suggestions.add(candidate);
    }
  }
}

void _addAcceptedMovesFromPortFleet({
  required IncrementalCandidateValidator candidateValidator,
  required MapTopology topology,
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
    if (candidateValidator.isNavalMoveAccepted(candidate)) {
      suggestions.add(candidate);
    }
  }
}

/// Suggests naval move orders for fleets owned by [view.playerId]. SPEC/program/naval-movement-resolution.md.
///
/// Throughput hook: callers that enumerate multiple suggestion families against
/// the same `(game, view.playerId, currentOrders)` may supply
/// [sharedCandidateValidator] to amortize `PlayerView` / units-by-id
/// construction (Refs #2394, `SPEC/program/order-suggestions.md` § Throughput
/// bounds).
List<NavalMoveOrder> suggestNavalMoveOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  Map<String, Unit>? unitsById,
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
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

  // Single per-player validator: amortizes the per-player [PlayerView] /
  // units-by-id setup across every candidate probe in the loop.
  // SPEC/program/order-suggestions.md § Incremental candidate validation.
  // Refs #2237.
  //
  assert(
    sharedCandidateValidator == null ||
        sharedCandidateValidator.playerId == playerId,
    'sharedCandidateValidator playerId must match view.playerId',
  );
  // Reuse the caller-supplied [view] and a one-time units index so we do not
  // pay redundant `buildPlayerView` / `unitsByIdFromWorld` scans (Refs #2394).
  final effectiveUnits =
      unitsById ??
      sharedCandidateValidator?.unitsById ??
      unitsByIdFromWorld(game.worldState);
  final candidateValidator =
      sharedCandidateValidator ??
      IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: playerId,
        basePrefix: currentOrders,
        view: view,
        unitsById: effectiveUnits,
      );

  final homeFleetId = homeFleetIdFor(playerId);
  for (final fleet in game.worldState.fleets) {
    if (fleet.ownerId != playerId || fleet.id == homeFleetId) continue;
    if (fleet.isAtSea) {
      final cur = fleet.seaZoneId;
      if (cur == null) continue;
      _addAcceptedSeaZoneCandidates(
        candidateValidator: candidateValidator,
        topology: topology,
        fleet: fleet,
        cur: cur,
        existingByFleet: existingByFleet,
        suggestions: suggestions,
      );
      _addAcceptedDockCandidatesForSeaFleet(
        candidateValidator: candidateValidator,
        game: game,
        topology: topology,
        playerId: playerId,
        fleet: fleet,
        cur: cur,
        existingByFleet: existingByFleet,
        suggestions: suggestions,
      );
    } else {
      _addAcceptedMovesFromPortFleet(
        candidateValidator: candidateValidator,
        topology: topology,
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
  return suggestions;
}

/// Suggests naval mission orders for fleets owned by [view.playerId]. Phase 6.
///
/// Throughput hook: see [suggestNavalMoveOrders] [sharedCandidateValidator].
List<NavalMissionOrder> suggestNavalMissionOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  Map<String, Unit>? unitsById,
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  orderSuggestionLog.d('suggestNavalMissionOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <NavalMissionOrder>[];
  final existingByFleet = <String>{};
  for (final o
      in currentOrders.navalMissionOrdersByPlayerId[playerId] ?? const []) {
    existingByFleet.add(o.fleetId);
  }

  // Single per-player validator amortizes per-player setup across every
  // candidate probe (mission × fleet). SPEC/program/order-suggestions.md
  // § Incremental candidate validation. Refs #2237.
  //
  assert(
    sharedCandidateValidator == null ||
        sharedCandidateValidator.playerId == playerId,
    'sharedCandidateValidator playerId must match view.playerId',
  );
  // Reuse [view] and one units snapshot (Refs #2394).
  final effectiveUnits =
      unitsById ??
      sharedCandidateValidator?.unitsById ??
      unitsByIdFromWorld(game.worldState);
  final candidateValidator =
      sharedCandidateValidator ??
      IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: playerId,
        basePrefix: currentOrders,
        view: view,
        unitsById: effectiveUnits,
      );

  for (final fleet in game.worldState.fleets) {
    if (fleet.ownerId != playerId) continue;
    if (existingByFleet.contains(fleet.id)) continue;
    for (final mission in FleetMission.values) {
      final candidate = NavalMissionOrder(
        fleetId: fleet.id,
        mission: mission.name,
      );
      if (candidateValidator.isNavalMissionAccepted(candidate)) {
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
  return suggestions;
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
  required DiplomacyFactionMembership factionMembership,
  required Map<String, OvertureState> playerOverturesByTargetId,
}) {
  final treasury = player.treasury;
  final out = <DiplomaticOrder>[];
  if (targetId == playerId) return out;

  final rel = getRelation(game, playerId, targetId);
  final atWar = rel?.atWar ?? false;
  final atPeace = rel == null || rel.atPeace;
  final isGpTarget = game.playerById(targetId) != null;
  final targetIsMinorOrTribe = isMinorOrTribe(
    game,
    targetId,
    factionMembership: factionMembership,
  );

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
  if (targetIsMinorOrTribe && knownFactionIds.contains(targetId)) {
    final overtureOrder = _establishOvertureSuggestionOrder(
      game: game,
      playerId: playerId,
      targetId: targetId,
      treasury: treasury,
    );
    if (overtureOrder != null) out.add(overtureOrder);
  }

  final overtureRow = playerOverturesByTargetId[targetId];
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
  final next = current.next;
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
    // O(1) player lookup (Refs #2394); minor/tribe overture stages require tech.
    final submitter = game.playerById(playerId);
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
///
/// Throughput hook: when [sharedCandidateValidator] is supplied for the same
/// `(game, topology, playerId, currentOrders)` tuple, the pass-level validator
/// setup is skipped (Refs #2394).
List<DiplomaticOrder> suggestDiplomaticOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  Map<String, TileMapResult>? tileMapByRegion,
  IncrementalCandidateValidator? sharedCandidateValidator,
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

  // One membership snapshot for this pass: O(1) minor/tribe checks per target
  // and GP id sets without repeated list scans (Refs #2394).
  final factionMembership = DiplomacyFactionMembership.from(game);
  final otherGps = factionMembership.greatPowerIds.difference({playerId});
  final knownTargets = <String>{
    ...otherGps.where(knownFactionIds.contains),
    ...factionMembership.minorOrTribeIds.where(knownFactionIds.contains),
  };
  final knownTargetIds = knownTargets.toSet();

  // First matching overture row per target (same order as legacy linear scan).
  final playerOverturesByTargetId = <String, OvertureState>{};
  for (final o in game.overtureStates) {
    if (o.gpId != playerId) continue;
    playerOverturesByTargetId.putIfAbsent(o.targetId, () => o);
  }

  assert(
    sharedCandidateValidator == null ||
        sharedCandidateValidator.playerId == playerId,
    'sharedCandidateValidator playerId must match view.playerId',
  );
  // One world scan for the suggestion pass: every diplomatic probe shares the
  // same `(game, topology, playerId)` view/units snapshot (Refs #2394).
  final unitsByIdForDiplomatic =
      sharedCandidateValidator?.unitsById ?? unitsByIdFromWorld(game.worldState);

  final unionTargets = <String>{
    ...knownTargets,
    ...otherGps,
    ...playerOverturesByTargetId.keys,
  };

  final sortedTargetIds = unionTargets.toList()..sort();
  var workingOrders = currentOrders;
  // Rebind [basePrefix] per target via [forBasePrefix]; pay view/units/membership
  // setup once for the whole suggestion pass (Refs #2394).
  var passValidator =
      sharedCandidateValidator != null
      ? (sharedCandidateValidator.basePrefix == workingOrders
            ? sharedCandidateValidator
            : sharedCandidateValidator.forBasePrefix(workingOrders))
      : buildIncrementalCandidateValidator(
          game: game,
          topology: topology,
          playerId: playerId,
          baseOrders: workingOrders,
          tileMapByRegion: tileMapByRegion,
          view: view,
          unitsById: unitsByIdForDiplomatic,
          factionMembership: factionMembership,
        );
  for (final targetId in sortedTargetIds) {
    if (targetId == playerId) continue;

    final candidates = _diplomaticCandidatesForTargetOrdered(
      game: game,
      playerId: playerId,
      player: player,
      targetId: targetId,
      knownTargetIds: knownTargetIds,
      knownFactionIds: knownFactionIds,
      factionMembership: factionMembership,
      playerOverturesByTargetId: playerOverturesByTargetId,
    );
    var trialOrders = workingOrders;

    // One incremental validator per trial prefix: amortizes validator setup
    // across all candidates in the pass (Refs #2394).
    final prefixPassValidator = passValidator.forBasePrefix(trialOrders);
    passValidator = prefixPassValidator;
    var prefixPassAcceptedOrder = false;
    for (final candidate in candidates) {
      if (candidate.type == DiplomaticOrderType.grantAid ||
          candidate.type == DiplomaticOrderType.setSubsidy) {
        continue;
      }
      if (!isDiplomaticOrderAcceptedWithValidator(
        prefixPassValidator,
        candidate,
      )) {
        continue;
      }
      suggestions.add(candidate);
      trialOrders = appendDiplomaticOrderForTrial(
        trialOrders,
        playerId,
        candidate,
      );
      prefixPassAcceptedOrder = true;
      break;
    }

    // Rebind only when the non-economic pass changed the trial prefix; when
    // it did not accept anything, economic probes share [prefixPassValidator].
    final economicPassValidator = prefixPassAcceptedOrder
        ? prefixPassValidator.forBasePrefix(trialOrders)
        : prefixPassValidator;
    if (prefixPassAcceptedOrder) {
      passValidator = economicPassValidator;
    }
    for (final candidate in candidates) {
      if (candidate.type != DiplomaticOrderType.grantAid &&
          candidate.type != DiplomaticOrderType.setSubsidy) {
        continue;
      }
      if (!isDiplomaticOrderAcceptedWithValidator(
        economicPassValidator,
        candidate,
      )) {
        continue;
      }
      suggestions.add(candidate);
      trialOrders = appendDiplomaticOrderForTrial(
        trialOrders,
        playerId,
        candidate,
      );
    }

    workingOrders = trialOrders;
    // Keep [passValidator] aligned with accumulated **workingOrders** before the
    // next target (including economic-only accepts that did not update
    // [passValidator] in the primary/economic split above). Refs #2394.
    passValidator = passValidator.forBasePrefix(workingOrders);
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
  return suggestions;
}
