/// Terrain type for a land tile.
/// Minimal set for Phase 1; extend per ruleset later. See SPEC/game/resource-terrain-region-rules.md for terrain types and SPEC/game/tile-map-and-generation.md for map generation.
///
/// Forest is split into [hardwoodForest] (high-quality timber, rarer; may also
/// host furs in the New World) and [scrubForest] (low-quality timber, common;
/// timber extraction hard-capped at level 1). See issue #3573 and
/// SPEC/game/resource-terrain-region-rules.md.
enum TerrainType {
  plains,
  hardwoodForest,
  scrubForest,
  hills,
  mountain,
  swamp,
  desert,
}

/// Whether [terrain] is a forest terrain (hardwood or scrub). Both forest
/// variants share timber rules, L2 feature rendering, and the guaranteed
/// forest resource spawn. See issue #3573, SPEC/game/resource-terrain-region-rules.md.
bool isForestTerrain(TerrainType terrain) =>
    terrain == TerrainType.hardwoodForest ||
    terrain == TerrainType.scrubForest;
