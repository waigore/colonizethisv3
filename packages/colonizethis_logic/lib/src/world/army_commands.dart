import 'package:colonizethis_models/colonizethis_models.dart';

import 'army_ids.dart';

/// Merges [armyIds] into one army at the same province. Home army wins as target.
/// SPEC/ui/military-units-army-management.md.
Game applyArmyCombine({
  required Game game,
  required String playerId,
  required List<String> armyIds,
}) {
  if (armyIds.length < 2) return game;

  final selected = game.worldState.armies
      .where((a) => armyIds.contains(a.id) && a.ownerId == playerId)
      .toList();
  if (selected.length < 2) return game;

  final province = selected.first.stationedProvinceId;
  if (selected.any((a) => a.stationedProvinceId != province)) {
    return game;
  }

  Army target;
  final home = selected.where((a) => a.isHomeArmy).toList();
  if (home.isNotEmpty) {
    target = home.first;
  } else {
    final sorted = [...selected]..sort((a, b) => a.id.compareTo(b.id));
    target = sorted.first;
  }

  final mergedIds = <String>[];
  for (final a in selected) {
    mergedIds.addAll(a.regimentUnitIds);
  }
  final unique = mergedIds.toSet().toList()..sort();

  final removeIds = selected.map((a) => a.id).toSet();
  final nextArmies = <Army>[
    for (final a in game.worldState.armies)
      if (!removeIds.contains(a.id)) a,
    target.copyWith(regimentUnitIds: unique),
  ]..sort((a, b) => a.id.compareTo(b.id));

  return game.copyWith(
    worldState: game.worldState.copyWith(armies: nextArmies),
  );
}

/// Splits [unitIdsToMove] from [sourceArmyId] into a new army in the same province.
Game applyArmySplit({
  required Game game,
  required String playerId,
  required String sourceArmyId,
  required List<String> unitIdsToMove,
}) {
  if (unitIdsToMove.isEmpty) return game;

  final sourceList =
      game.worldState.armies.where((a) => a.id == sourceArmyId).toList();
  final source = sourceList.isEmpty ? null : sourceList.first;
  if (source == null || source.ownerId != playerId) return game;
  if (source.isHomeArmy) {
    // Home army may split per SPEC (naval parity).
  }
  final moveSet = unitIdsToMove.toSet();
  if (!moveSet.every(source.regimentUnitIds.contains)) return game;
  if (moveSet.length >= source.regimentUnitIds.length) return game;

  final remaining =
      source.regimentUnitIds.where((id) => !moveSet.contains(id)).toList();
  final newId = 'army_${game.worldState.nextArmySeq}';
  final newArmy = Army(
    id: newId,
    ownerId: source.ownerId,
    regionId: source.regionId,
    stationedProvinceId: source.stationedProvinceId,
    regimentUnitIds: unitIdsToMove.toList()..sort(),
    isHomeArmy: false,
  );

  final updatedSource = source.copyWith(regimentUnitIds: remaining);
  var armies = game.worldState.armies
      .map((a) => a.id == source.id ? updatedSource : a)
      .toList();
  armies = [...armies, newArmy]..sort((a, b) => a.id.compareTo(b.id));

  return game.copyWith(
    worldState: game.worldState.copyWith(
      armies: armies,
      nextArmySeq: game.worldState.nextArmySeq + 1,
    ),
  );
}
