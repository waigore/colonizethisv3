import 'package:colonizethis_models/colonizethis_models.dart'
    show RegionData, Unit, WorldState;

import '../constants.dart';

/// Central unit lookup. Units live in [WorldState.oldWorld] and [WorldState.newWorld];
/// lookup is by unit id. SPEC/game/world-model-identity.md.
///
/// Use [unitsByIdFromWorld] for combined read-only or mutable copy across both regions.
/// Use [unitsByIdFromRegion] for a single region (e.g. combat, movement within region).

/// Returns a new map from unit id to unit for [region]. Callers that need to mutate
/// (add/update units) should use [Map.from](unitsByIdFromRegion(region)).
Map<String, Unit> unitsByIdFromRegion(RegionData region) {
  return {for (final u in region.units) u.id: u};
}

/// Returns a new map from unit id to unit for all units in [world] (both regions).
/// Callers that need to mutate should use [Map.from](unitsByIdFromWorld(world)).
Map<String, Unit> unitsByIdFromWorld(WorldState world) {
  return <String, Unit>{
    ...unitsByIdFromRegion(world.oldWorld),
    ...unitsByIdFromRegion(world.newWorld),
  };
}

/// Returns all units from both regions in [world]. For iteration over every unit.
List<Unit> allUnitsFromWorld(WorldState world) {
  return [...world.oldWorld.units, ...world.newWorld.units];
}

/// Unit type id → count of land units owned by [playerId] (both regions).
/// Used for military food upkeep during Consumption. SPEC/program/turn-resolution-phase-details.md.
Map<String, int> regimentTypeCountsForPlayer(
  WorldState world,
  String playerId,
) {
  final map = <String, int>{};
  for (final u in allUnitsFromWorld(world)) {
    if (u.ownerId != playerId) continue;
    map.update(u.type, (v) => v + 1, ifAbsent: () => 1);
  }
  return map;
}

/// Ship type id → count of ships in that player's fleets.
/// Used for navy food upkeep during Consumption. SPEC/program/turn-resolution-phase-details.md.
Map<String, int> shipTypeCountsForPlayer(WorldState world, String playerId) {
  final map = <String, int>{};
  for (final fleet in world.fleets) {
    if (fleet.ownerId != playerId) continue;
    for (final shipTypeId in fleet.shipTypeIds) {
      map.update(shipTypeId, (v) => v + 1, ifAbsent: () => 1);
    }
  }
  return map;
}

/// Lazily built per [WorldState] instance (issue #2268 AC-3). A new
/// [WorldState] from [WorldState.copyWith] gets a fresh cache via identity.
final Expando<_WorldUnitIndex> _worldUnitIndexByState =
    Expando<_WorldUnitIndex>('worldUnitIndexByState');

/// Old-world-first id → unit plus membership sets for O(1) region checks.
final class _WorldUnitIndex {
  _WorldUnitIndex({
    required this.byId,
    required this.oldIds,
    required this.newIds,
  });

  final Map<String, Unit> byId;
  final Set<String> oldIds;
  final Set<String> newIds;
}

_WorldUnitIndex _unitIndexForWorld(WorldState world) {
  var index = _worldUnitIndexByState[world];
  if (index != null) return index;

  final byId = <String, Unit>{};
  final oldIds = <String>{};
  for (final u in world.oldWorld.units) {
    oldIds.add(u.id);
    byId.putIfAbsent(u.id, () => u);
  }
  final newIds = <String>{};
  for (final u in world.newWorld.units) {
    newIds.add(u.id);
    byId.putIfAbsent(u.id, () => u);
  }
  index = _WorldUnitIndex(byId: byId, oldIds: oldIds, newIds: newIds);
  _worldUnitIndexByState[world] = index;
  return index;
}

/// Cross-region unit lookup on [WorldState] (waigore/colonizethis#2071 Phase 1).
extension WorldStateUnitLookup on WorldState {
  /// Returns the unit with [unitId] in old world first, then new world, or null.
  Unit? tryGetUnitById(String unitId) => _unitIndexForWorld(this).byId[unitId];

  /// [kRegionOldWorld] or [kRegionNewWorld] based on which regional unit list
  /// contains [unit]'s id (old world checked first). Null if absent from both.
  String? tryGetRegionIdForUnit(Unit unit) {
    final index = _unitIndexForWorld(this);
    if (index.oldIds.contains(unit.id)) {
      return kRegionOldWorld;
    }
    if (index.newIds.contains(unit.id)) {
      return kRegionNewWorld;
    }
    return null;
  }
}
