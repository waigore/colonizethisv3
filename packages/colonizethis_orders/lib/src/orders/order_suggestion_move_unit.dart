part of 'order_suggestion_move_army.dart';

const int _kMaxMoveSuggestionsPerUnit = 24;
const int _kMaxMoveProbeAttemptsPerUnit = 160;

/// Land tile keys that may be valid [MoveOrder] destinations for [unit] under
/// [SPEC/program/movement.md]: owned provinces (any region), non-owned only when
/// adjacent in [topology]. Visibility applied. Sorted for deterministic probes
/// (Refs #2507).
List<String> sortedMoveDestinationCandidateTileKeys({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Unit unit,
}) {
  final playerId = view.playerId;
  final world = game.worldState;
  final tileKeysByRegion = world.tileKeysByRegionAndProvince;
  final unitRegion = regionIdForUnit(view, unit);
  final fromProvinceFull = resolveToFullProvinceId(
    world,
    unit.locationProvinceId,
  );
  final seen = <String>{};
  final out = <String>[];

  void addVisibleTiles(Iterable<String> tiles) {
    for (final tk in tiles) {
      if (!seen.add(tk)) continue;
      if (moveDestinationTileVisibilityOk(view, tk)) {
        out.add(tk);
      }
    }
  }

  addVisibleTiles(tileKeysByRegion[unitRegion]?[fromProvinceFull] ?? const []);

  for (final entry in view.provincesById.entries) {
    final fullId = entry.key;
    final prov = entry.value;
    if (prov.ownerId != playerId) continue;
    if (fullId == fromProvinceFull) continue;
    addVisibleTiles(tileKeysByRegion[prov.regionId]?[fullId] ?? const []);
  }

  final fromLocal = ProvinceId.localIdFrom(fromProvinceFull);
  for (final neighborLocal in neighborProvinceIdsInRegion(
    topology,
    unitRegion,
    fromLocal,
  )) {
    final neighborFull = ProvinceId.full(unitRegion, neighborLocal);
    final owner = view.provincesById[neighborFull]?.ownerId;
    if (owner == playerId) continue;
    addVisibleTiles(tileKeysByRegion[unitRegion]?[neighborFull] ?? const []);
  }

  out.sort();
  return out;
}

/// Suggests candidate move orders that are information-legal (per [PlayerView])
/// and rules-legal (per [OrderEngine]) for [view.playerId].
///
/// Throughput hook: callers that enumerate multiple suggestion families against
/// the same `(game, view.playerId, currentOrders)` may supply
/// [sharedCandidateValidator] to amortize `PlayerView` / units-by-id
/// construction across families (Refs #2394,
/// `SPEC/program/order-suggestions.md` § Throughput bounds). When omitted,
/// this function constructs its own validator. The shared instance must be
/// built with the same inputs as this call; observable suggestions must match
/// the default path.
List<MoveOrder> suggestMoveOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  orderSuggestionLog.d('suggestMoveOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <MoveOrder>[];

  // Build a convenience index of current move orders for this player to avoid
  // suggesting duplicate moves for the same unit + destination.
  final existingMoves = <String, Set<String>>{};
  final existingForPlayer =
      currentOrders.moveOrdersByPlayerId[playerId] ?? const [];
  for (final m in existingForPlayer) {
    existingMoves
        .putIfAbsent(m.unitId, () => <String>{})
        .add(m.destinationTileKey);
  }

  // Build the incremental candidate validator once per suggestion pass: the
  // per-player [PlayerView]/units-by-id work is amortized across every
  // candidate probe in the loop, instead of being rebuilt per probe via the
  // old [OrderEngine] full-pass path. SPEC/program/order-suggestions.md
  // § Incremental candidate validation. Refs #2237.
  assert(
    sharedCandidateValidator == null ||
        sharedCandidateValidator.playerId == playerId,
    'sharedCandidateValidator playerId must match view.playerId',
  );
  final candidateValidator =
      sharedCandidateValidator ??
      IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: playerId,
        basePrefix: currentOrders,
        factionMembership: DiplomacyFactionMembership.from(game),
        resolution: orderResolutionContextFromView(view, game),
      );

  for (final unit in view.ownUnits) {
    if (isMilitaryUnit(unit.type)) {
      // Land regiments move via [ArmyMoveOrder]; see [suggestArmyMoveOrders].
      continue;
    }
    final unitRegion = regionIdForUnit(view, unit);
    final fromProvinceId = unit.locationProvinceId;

    // Source province cannot be unknown; by definition the unit is in a known province.
    if (!moveSourceVisibilityOk(view, unitRegion, fromProvinceId)) {
      throw StateError(
        'Source province must be visible; unit ${unit.id} has source province $fromProvinceId with unknown visibility',
      );
    }

    final destinationCandidates = sortedMoveDestinationCandidateTileKeys(
      view: view,
      game: game,
      topology: topology,
      unit: unit,
    );

    var acceptedForUnit = 0;
    var probeAttemptsForUnit = 0;
    for (final destinationTileKey in destinationCandidates) {
      final already = existingMoves[unit.id];
      if (already != null && already.contains(destinationTileKey)) continue;
      probeAttemptsForUnit++;

      final candidate = MoveOrder(
        unitId: unit.id,
        destinationTileKey: destinationTileKey,
      );

      if (candidateValidator.isMoveAccepted(candidate)) {
        suggestions.add(candidate);
        acceptedForUnit++;
        if (acceptedForUnit >= _kMaxMoveSuggestionsPerUnit) {
          break;
        }
      }
      if (probeAttemptsForUnit >= _kMaxMoveProbeAttemptsPerUnit) {
        break;
      }
    }
  }

  suggestions.sort((a, b) {
    final unitCmp = a.unitId.compareTo(b.unitId);
    if (unitCmp != 0) return unitCmp;
    return a.destinationTileKey.compareTo(b.destinationTileKey);
  });

  orderSuggestionLog.d(
    'suggestMoveOrders player=$playerId candidates=${suggestions.length}',
  );
  if (suggestions.isEmpty) {
    orderSuggestionLog.w('suggestMoveOrders no candidates player=$playerId');
  }
  return suggestions;
}
