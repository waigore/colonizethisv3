import 'package:colonizethis_models/colonizethis_models.dart' show RegionData, Unit, WorldState;

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
