import 'package:colonizethis_models/colonizethis_models.dart';

import 'game_world_mutations.dart';
import 'military_list_helpers.dart';

/// Merges [armyIds] into one army at the same province. Home army wins as target.
/// SPEC/ui/military-units-army-management.md.
Game applyArmyCombine({
  required Game game,
  required String playerId,
  required List<String> armyIds,
}) {
  if (armyIds.length < 2) return game;

  final idSet = armyIds.toSet();
  final partitioned = partitionBySelectedIds(
    items: game.worldState.armies.where((a) => a.ownerId == playerId),
    selectedIds: idSet,
    idOf: (a) => a.id,
  );
  final selected = partitioned.selected;
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

  final source = armiesByIdForWorld(game.worldState)[sourceArmyId];
  if (source == null || source.ownerId != playerId) return game;
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

  final remaining = idsNotIn(source.regimentUnitIds, moveSet);
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
  var armies = replaceById(
    items: game.worldState.armies,
    id: source.id,
    replacement: updatedSource,
    idOf: (a) => a.id,
  );
  armies = [...armies, newArmy]..sort((a, b) => a.id.compareTo(b.id));

  return game.updateWorldState(
    (ws) => ws.copyWith(armies: armies, nextArmySeq: ws.nextArmySeq + 1),
  );
}
