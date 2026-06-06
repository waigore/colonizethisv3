part of 'order_suggestion_naval_diplomatic.dart';

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
  OrderResolutionContext? resolution,
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
  final effectiveResolution = _effectiveOrderResolutionContext(
    view: view,
    game: game,
    resolution: resolution,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  final candidateValidator =
      sharedCandidateValidator ??
      IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: playerId,
        basePrefix: currentOrders,
        resolution: effectiveResolution,
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
  OrderResolutionContext? resolution,
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
  final effectiveResolution = _effectiveOrderResolutionContext(
    view: view,
    game: game,
    resolution: resolution,
    sharedCandidateValidator: sharedCandidateValidator,
  );
  final candidateValidator =
      sharedCandidateValidator ??
      IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: playerId,
        basePrefix: currentOrders,
        resolution: effectiveResolution,
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
