/// Canonical old/new-world region selection for the colonizethis_map package.
///
/// All map view-building and visualizer paths must resolve a region's
/// [RegionData] through [regionDataForMapRegionId] instead of repeating
/// `regionId == kRegionOldWorld ? world.oldWorld : world.newWorld` (or the
/// equivalent `isOldWorld` ternary) branches across the orchestration,
/// cell/unit, and ownership-overlay passes (Refs #3459 AC3). The repo-lint
/// rule `repo.map_region_data_access_central` forbids re-introducing scattered
/// inline `worldState.oldWorld.provinces` / `.newWorld.units` (and sibling)
/// region branches in the package lib.
/// SPEC/program/map-visualization.md, SPEC/game/world-model.md.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'map_region_dispatch.dart';

/// Returns the [RegionData] for a map [regionId] (`kRegionOldWorld` or
/// `kRegionNewWorld`).
///
/// Single source of truth for the package's old/new-world data selection so
/// callers read `regionDataForMapRegionId(world, regionId).provinces` (or
/// `.units`) instead of branching on the region directly. Throws
/// `MapValidationException` (via [selectByMapRegionId]) for any other id so an
/// unexpected region surfaces loudly rather than silently defaulting to one
/// world.
RegionData regionDataForMapRegionId(WorldState world, String regionId) =>
    selectByMapRegionId(
      regionId,
      oldWorld: () => world.oldWorld,
      newWorld: () => world.newWorld,
    );
