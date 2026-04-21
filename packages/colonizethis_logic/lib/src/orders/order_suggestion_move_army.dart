part of 'order_suggestion.dart';

/// Suggests candidate move orders that are information-legal (per [PlayerView])
/// and rules-legal (per [OrderEngine]) for [view.playerId].
List<MoveOrder> suggestMoveOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  _log.d('suggestMoveOrders player=${view.playerId}');
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

  final landTiles = sortedLandTileKeys(game.worldState);

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

    for (final destinationTileKey in landTiles) {
      final already = existingMoves[unit.id];
      if (already != null && already.contains(destinationTileKey)) continue;

      if (!moveDestinationTileVisibilityOk(view, destinationTileKey)) {
        continue;
      }

      final candidate = MoveOrder(
        unitId: unit.id,
        destinationTileKey: destinationTileKey,
      );

      if (_isMoveOrderAccepted(
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
    final unitCmp = a.unitId.compareTo(b.unitId);
    if (unitCmp != 0) return unitCmp;
    return a.destinationTileKey.compareTo(b.destinationTileKey);
  });

  _log.d('suggestMoveOrders player=$playerId candidates=${suggestions.length}');
  _log.d(
    'suggestMoveOrders full list ${suggestions.map((m) => "${m.unitId}->${m.destinationTileKey}").toList()}',
  );
  if (suggestions.isEmpty) {
    _log.w('suggestMoveOrders no candidates player=$playerId');
  }
  return suggestions;
}

/// Destination province ids for army moves (Military Units picker parity): adjacent
/// land provinces in the army's region plus every province owned by [playerId]
/// in any region; excludes the army's current province.
List<String> armyMoveCandidateDestinationProvinceIds({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Army army,
}) {
  final fromFull = army.stationedProvinceId;
  final regionId = ProvinceId.regionIdFrom(fromFull);
  final fromLocal = ProvinceId.localIdFrom(fromFull);
  final out = <String>{};

  for (final n in neighborProvinceIdsInRegion(topology, regionId, fromLocal)) {
    out.add(ProvinceId.full(regionId, n));
  }
  for (final p in allProvinces(game.worldState)) {
    if (p.ownerId == playerId) {
      out.add(toFullProvinceId(p.regionId, p.id));
    }
  }
  out.remove(fromFull);
  final sorted = out.toList()..sort();
  return sorted;
}

/// One destination row for the Move Army picker (Military Units).
/// Only entries produced by [armyMovePickerDestinations] are selectable; each
/// corresponds to a draft that passes [OrderEngine] validation.
class ArmyMovePickerDestination {
  const ArmyMovePickerDestination({
    required this.fullProvinceId,
    required this.provinceLabel,
    required this.regionId,
    required this.ownerFactionId,
    required this.isPlayerOwned,
    required this.requiresDeclareWarOnConfirm,
  });

  final String fullProvinceId;
  final String provinceLabel;
  final String regionId;

  /// Province owner (same as [playerId] when [isPlayerOwned]).
  final String ownerFactionId;
  final bool isPlayerOwned;

  /// When true, confirm must run invasion flow and the shell should set
  /// [ArmyMoveRequestedEvent.declareWarTargetFactionId] to [ownerFactionId].
  final bool requiresDeclareWarOnConfirm;
}

bool _armyMoveNeedsDeclareWarTrial(
  Game game,
  String playerId,
  String? destOwnerId,
  List<DiplomaticOrder> diplo,
) {
  if (destOwnerId == null || destOwnerId.isEmpty || destOwnerId == playerId) {
    return false;
  }
  if (!isGreatPower(game, destOwnerId) && !isMinorOrTribe(game, destOwnerId)) {
    return false;
  }
  return !canAttackWithWarOrDeclaring(game, playerId, destOwnerId, diplo);
}

/// Valid, sorted destinations for the Move Army dialog: player-owned and
/// invasion targets only if the merged draft (with optional same-turn declare
/// war) passes [OrderEngine] validation. SPEC/ui/military-units-panel.md.
List<ArmyMovePickerDestination> armyMovePickerDestinations({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Army army,
  required Orders currentOrders,
}) {
  final diplo =
      currentOrders.diplomaticOrdersByPlayerId[playerId] ??
      const <DiplomaticOrder>[];
  final raw = armyMoveCandidateDestinationProvinceIds(
    game: game,
    topology: topology,
    playerId: playerId,
    army: army,
  );
  final out = <ArmyMovePickerDestination>[];
  for (final fullId in raw) {
    final province = game.worldState.tryGetProvince(fullId);
    final ownerId = province?.ownerId ?? '';
    final move = ArmyMoveOrder(armyId: army.id, destinationProvinceId: fullId);
    final acceptedBase = _isArmyMoveOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      move,
    );
    var requiresDeclare = false;
    if (acceptedBase) {
      requiresDeclare = false;
    } else {
      if (!_armyMoveNeedsDeclareWarTrial(game, playerId, ownerId, diplo)) {
        continue;
      }
      final trial = ordersWithAppendedDiplomaticOrder(
        currentOrders,
        playerId,
        DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: ownerId,
        ),
      );
      if (!_isArmyMoveOrderAccepted(game, topology, playerId, trial, move)) {
        continue;
      }
      requiresDeclare = true;
    }
    final label = province?.displayName ?? ProvinceId.localIdFrom(fullId);
    final isOwn = ownerId == playerId;
    final ownerKey = ownerId.isEmpty ? '__unowned__' : ownerId;
    out.add(
      ArmyMovePickerDestination(
        fullProvinceId: fullId,
        provinceLabel: label,
        regionId: ProvinceId.regionIdFrom(fullId),
        ownerFactionId: ownerKey,
        isPlayerOwned: isOwn,
        requiresDeclareWarOnConfirm: requiresDeclare,
      ),
    );
  }
  out.sort((a, b) {
    if (a.isPlayerOwned != b.isPlayerOwned) {
      return a.isPlayerOwned ? -1 : 1;
    }
    final o = a.ownerFactionId.compareTo(b.ownerFactionId);
    if (o != 0) return o;
    final r = a.regionId.compareTo(b.regionId);
    if (r != 0) return r;
    final l = a.provinceLabel.compareTo(b.provinceLabel);
    if (l != 0) return l;
    return a.fullProvinceId.compareTo(b.fullProvinceId);
  });
  return out;
}

/// Suggests candidate [ArmyMoveOrder]s for non-home armies owned by [view.playerId].
List<ArmyMoveOrder> suggestArmyMoveOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  final playerId = view.playerId;
  final suggestions = <ArmyMoveOrder>[];
  final existingArmyMoves = <String, Set<String>>{};
  final existingForPlayer =
      currentOrders.armyMoveOrdersByPlayerId[playerId] ?? const [];
  for (final m in existingForPlayer) {
    existingArmyMoves
        .putIfAbsent(m.armyId, () => <String>{})
        .add(m.destinationProvinceId);
  }

  for (final army in game.worldState.armies) {
    if (army.ownerId != playerId) continue;
    if (army.isHomeArmy) continue;

    final fromProvinceId = army.stationedProvinceId;
    final unitRegion = ProvinceId.regionIdFrom(fromProvinceId);

    if (!moveSourceVisibilityOk(view, unitRegion, fromProvinceId)) continue;

    final destIds = armyMoveCandidateDestinationProvinceIds(
      game: game,
      topology: topology,
      playerId: playerId,
      army: army,
    );

    for (final destinationProvinceId in destIds) {
      final already = existingArmyMoves[army.id];
      if (already != null && already.contains(destinationProvinceId)) continue;

      final candidate = ArmyMoveOrder(
        armyId: army.id,
        destinationProvinceId: destinationProvinceId,
      );

      if (_isArmyMoveOrderAccepted(
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
    final idCmp = a.armyId.compareTo(b.armyId);
    if (idCmp != 0) return idCmp;
    return a.destinationProvinceId.compareTo(b.destinationProvinceId);
  });
  return suggestions;
}
