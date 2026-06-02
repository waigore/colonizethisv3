import 'package:colonizethis_models/colonizethis_models.dart';

import 'game_world_mutations.dart';

/// Merges [armyIds] into one army at the same province. Home army wins as target.
/// SPEC/ui/military-units-army-management.md.
Game applyArmyCombine({
  required Game game,
  required String playerId,
  required List<String> armyIds,
}) {
  if (armyIds.length < 2) return game;

  final idSet = armyIds.toSet();
  final selected = <Army>[];
  for (final a in game.worldState.armies) {
    if (a.ownerId == playerId && idSet.contains(a.id)) {
      selected.add(a);
    }
  }
  if (selected.length < 2) return game;

  final province = selected.first.stationedProvinceId;
  if (selected.any((a) => a.stationedProvinceId != province)) {
    return game;
  }

  Army target;
  Army? homeArmy;
  for (final a in selected) {
    if (a.isHomeArmy) {
      homeArmy = a;
      break;
    }
  }
  if (homeArmy != null) {
    target = homeArmy;
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

  return game.withArmies(nextArmies);
}

/// Splits [unitIdsToMove] from [sourceArmyId] into a new army in the same province.
Game applyArmySplit({
  required Game game,
  required String playerId,
  required String sourceArmyId,
  required List<String> unitIdsToMove,
}) {
  if (unitIdsToMove.isEmpty) return game;

  Army? found;
  for (final a in game.worldState.armies) {
    if (a.id == sourceArmyId) {
      found = a;
      break;
    }
  }
  if (found == null || found.ownerId != playerId) return game;
  final source = found;
  if (source.isHomeArmy) {
    // Home army may split per SPEC (naval parity).
  }
  final moveSet = unitIdsToMove.toSet();
  if (!moveSet.every(source.regimentUnitIds.contains)) return game;
  // Empty non-Home source armies are not created: reject moving every regiment.
  // Home Army may be left with zero regiments per SPEC/game/military-armies.md.
  if (moveSet.length >= source.regimentUnitIds.length && !source.isHomeArmy) {
    return game;
  }

  final remaining = source.regimentUnitIds
      .where((id) => !moveSet.contains(id))
      .toList();
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

  return game.updateWorldState(
    (ws) => ws.copyWith(armies: armies, nextArmySeq: ws.nextArmySeq + 1),
  );
}
