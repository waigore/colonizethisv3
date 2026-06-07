import 'dart:collection' show UnmodifiableMapView;

import 'package:colonizethis_models/colonizethis_models.dart'
    show RegionData, Unit, WorldState;

import '../world_constants.dart';
import 'package:colonizethis_world/src/utils/expando_index.dart';

/// Central unit lookup. Units live in [WorldState.oldWorld] and [WorldState.newWorld];
/// lookup is by unit id. SPEC/game/world-model-identity.md.
///
/// Use [WorldStateUnitLookup.allUnitsById] for combined read-only access across
/// both regions; the result is cached per-[WorldState] and shared across callers.
/// Use [Map.from](world.allUnitsById) when a mutable copy is required.
/// Use [unitsByIdFromRegion] for a single region (e.g. combat, movement within region).

/// Returns a new map from unit id to unit for [region]. Callers that need to mutate
/// (add/update units) should use [Map.from](unitsByIdFromRegion(region)).
Map<String, Unit> unitsByIdFromRegion(RegionData region) {
  return {for (final u in region.units) u.id: u};
}

/// Returns a new map from unit id to unit for all units in [world] (both regions).
///
/// **Prefer [WorldStateUnitLookup.allUnitsById]** — it returns the same combined
/// view backed by a per-[WorldState] cache (see `_WorldUnitIndex`), so repeated
/// callers within one turn no longer rebuild the same map. This function is
/// retained for the canonical [unit_lookup] internals (building the cached
/// index) and for tests; callers under `lib/src/` must use [allUnitsById]
/// instead and is enforced by `repo.logic_units_by_id_rebuild` (Refs #2836).
/// Callers that need to mutate should use
/// `Map<String, Unit>.from(world.allUnitsById)`.
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
  void count(Iterable<Unit> units) {
    for (final u in units) {
      if (u.ownerId != playerId) continue;
      map.update(u.type, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  count(world.oldWorld.units);
  count(world.newWorld.units);
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

/// Precomputed military type counts for all players in a [WorldState].
///
/// Consumption uses this to avoid re-scanning all units and fleets once per
/// player.
final class MilitaryTypeCountsByPlayer {
  const MilitaryTypeCountsByPlayer({
    required this.regimentCountsByPlayerId,
    required this.shipCountsByPlayerId,
  });

  final Map<String, Map<String, int>> regimentCountsByPlayerId;
  final Map<String, Map<String, int>> shipCountsByPlayerId;
}

/// Builds regiment and ship type counts for all players in one pass.
MilitaryTypeCountsByPlayer militaryTypeCountsByPlayer(WorldState world) {
  final regimentCountsByPlayerId = <String, Map<String, int>>{};
  void countRegiments(Iterable<Unit> units) {
    for (final unit in units) {
      final perPlayer = regimentCountsByPlayerId.putIfAbsent(
        unit.ownerId,
        () => <String, int>{},
      );
      perPlayer.update(unit.type, (count) => count + 1, ifAbsent: () => 1);
    }
  }

  countRegiments(world.oldWorld.units);
  countRegiments(world.newWorld.units);

  final shipCountsByPlayerId = <String, Map<String, int>>{};
  for (final fleet in world.fleets) {
    final perPlayer = shipCountsByPlayerId.putIfAbsent(
      fleet.ownerId,
      () => <String, int>{},
    );
    for (final shipTypeId in fleet.shipTypeIds) {
      perPlayer.update(shipTypeId, (count) => count + 1, ifAbsent: () => 1);
    }
  }

  return MilitaryTypeCountsByPlayer(
    regimentCountsByPlayerId: regimentCountsByPlayerId,
    shipCountsByPlayerId: shipCountsByPlayerId,
  );
}

/// Old-world-first id → unit plus membership sets for O(1) region checks.
///
/// [byId] is the raw mutable backing map (used internally for build). The
/// unmodifiable view [byIdUnmodifiable] is the public surface exposed through
/// [WorldStateUnitLookup.allUnitsById]: it is allocated once per
/// [WorldState] and shared across all read-only callers (Refs #2836 AC 2).
final class _WorldUnitIndex {
  _WorldUnitIndex({
    required this.byId,
    required this.oldIds,
    required this.newIds,
  }) : byIdUnmodifiable = UnmodifiableMapView<String, Unit>(byId);

  final Map<String, Unit> byId;
  final UnmodifiableMapView<String, Unit> byIdUnmodifiable;
  final Set<String> oldIds;
  final Set<String> newIds;
}

/// Lazily built per [WorldState] instance (issue #2268 AC-3). A new
/// [WorldState] from [WorldState.copyWith] gets a fresh cache via identity.
final ExpandoIndex<WorldState, _WorldUnitIndex> _worldUnitIndexByState =
    ExpandoIndex<WorldState, _WorldUnitIndex>('worldUnitIndexByState', (world) {
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
      return _WorldUnitIndex(byId: byId, oldIds: oldIds, newIds: newIds);
    });

_WorldUnitIndex _unitIndexForWorld(WorldState world) =>
    _worldUnitIndexByState.get(world);

/// Cross-region unit lookup on [WorldState] (waigore/colonizethis#2071 Phase 1).
extension WorldStateUnitLookup on WorldState {
  /// Returns the unit with [unitId] in old world first, then new world, or null.
  Unit? tryGetUnitById(String unitId) => _unitIndexForWorld(this).byId[unitId];

  /// Cross-region unit-by-id map (old-world entries first, then new world).
  ///
  /// Returns an unmodifiable view of the cached [_WorldUnitIndex.byId], so the
  /// same object is reused across all read-only callers for the same
  /// [WorldState] (Refs #2836 AC 2). Mutating callers must take an explicit
  /// copy via `Map<String, Unit>.from(world.allUnitsById)` — direct mutation
  /// of the returned map throws [UnsupportedError].
  Map<String, Unit> get allUnitsById =>
      _unitIndexForWorld(this).byIdUnmodifiable;

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

  /// Returns fresh mutable copies of the unit lists for both regions, keyed
  /// by [kRegionOldWorld] and [kRegionNewWorld].
  ///
  /// Use this from `lib/src/**` callers that stage imperative bulk-mutation
  /// over both regions before applying via [WorldStateRegionMappers.mapBothRegionUnits],
  /// replacing hand-rolled `List<Unit>.from(worldState.oldWorld.units)` /
  /// `List<Unit>.from(worldState.newWorld.units)` pairs (setup bootstrap,
  /// army migration, civilian moves, orders application). Each returned
  /// list is an independent mutable copy; mutating one does not affect the
  /// other or the source [WorldState]. The map is mutable; callers may add
  /// region keys defensively but the canonical contract returns exactly
  /// the two keys above (Refs #2836 AC 5;
  /// SPEC/program/logic-dual-region-province-access.md).
  Map<String, List<Unit>> mutableUnitListsByRegion() {
    return <String, List<Unit>>{
      kRegionOldWorld: List<Unit>.from(oldWorld.units),
      kRegionNewWorld: List<Unit>.from(newWorld.units),
    };
  }
}
