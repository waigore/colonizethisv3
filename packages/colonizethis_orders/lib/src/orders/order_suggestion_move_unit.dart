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
  final pass = SuggestionPassContext.forPlayerView(
    view: view,
    game: game,
    topology: topology,
    currentOrders: currentOrders,
    familyLabel: 'suggestMoveOrders',
    sharedCandidateValidator: sharedCandidateValidator,
    useBuildIncrementalWrapper: false,
  );
  final playerId = pass.playerId;
  final suggestions = <MoveOrder>[];
  final candidateValidator = pass.candidateValidator;

  // Build a convenience index of current move orders for this player to avoid
  // suggesting duplicate moves for the same unit + destination.
  final existingMoves = indexExistingTargetsByEntityId(
    currentOrders.moveOrdersByPlayerId[playerId],
    (m) => m.unitId,
    (m) => m.destinationTileKey,
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

    runCappedSuggestionProbeLoop<String>(
      candidates: destinationCandidates,
      shouldSkip: (destinationTileKey) {
        final already = existingMoves[unit.id];
        return already != null && already.contains(destinationTileKey);
      },
      probe: (destinationTileKey) {
        final candidate = MoveOrder(
          unitId: unit.id,
          destinationTileKey: destinationTileKey,
        );
        return candidateValidator.isMoveAccepted(candidate);
      },
      onAccepted: (destinationTileKey) {
        suggestions.add(
          MoveOrder(
            unitId: unit.id,
            destinationTileKey: destinationTileKey,
          ),
        );
      },
      maxAccepted: _kMaxMoveSuggestionsPerUnit,
      maxProbes: _kMaxMoveProbeAttemptsPerUnit,
    );
  }

  suggestions.sort((a, b) {
    final unitCmp = a.unitId.compareTo(b.unitId);
    if (unitCmp != 0) return unitCmp;
    return a.destinationTileKey.compareTo(b.destinationTileKey);
  });

  pass.logExit(candidateCount: suggestions.length, warnIfEmpty: true);
  return suggestions;
}
