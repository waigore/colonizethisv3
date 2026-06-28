/// Canonical generic old/new-world dispatch by map region id for the
/// `colonizethis_map` package.
///
/// All region-keyed selection in the package — region data, ownership colour
/// palettes, capital-marker scope, port-tile bucketing, and view-data
/// assembly — routes through [selectByMapRegionId] (or its non-throwing sibling
/// [selectByMapRegionIdOrNull]) so old/new branching lives in one place instead
/// of scattered `regionId == kRegionOldWorld ? ... : ...` ternaries across the
/// colour, capital, visualizer, and view-builder paths (Refs #3574). The
/// repo-lint rule `repo.map_region_dispatch_central` forbids re-introducing
/// inline `regionId == kRegionOldWorld` / `kRegionNewWorld` comparisons
/// elsewhere in the package lib.
/// SPEC/program/map-visualization.md, SPEC/game/world-model.md.
library;

import 'map_validation_exception.dart';
import 'region_constants.dart';

/// Resolves a value for map [regionId] by selecting the Old World or New World
/// branch.
///
/// Single source of truth for the package's old/new-world dispatch so callers
/// read `selectByMapRegionId(regionId, oldWorld: ..., newWorld: ...)` instead of
/// branching on the region directly. Throws [MapValidationException] for any id
/// other than [kRegionOldWorld] or [kRegionNewWorld] so an unexpected region
/// surfaces loudly rather than silently defaulting to one world.
T selectByMapRegionId<T>(
  String regionId, {
  required T Function() oldWorld,
  required T Function() newWorld,
}) {
  if (regionId == kRegionOldWorld) return oldWorld();
  if (regionId == kRegionNewWorld) return newWorld();
  throw MapValidationException(
    'map: unknown region id "$regionId" (expected $kRegionOldWorld or $kRegionNewWorld)',
  );
}

/// Like [selectByMapRegionId] but returns `null` for any id other than
/// [kRegionOldWorld] or [kRegionNewWorld] instead of throwing.
///
/// For callers that intentionally ignore unrecognized regions (for example
/// bucketing parsed tile keys, where a foreign region id is silently skipped
/// rather than treated as a hard error).
T? selectByMapRegionIdOrNull<T>(
  String regionId, {
  required T Function() oldWorld,
  required T Function() newWorld,
}) {
  if (regionId == kRegionOldWorld) return oldWorld();
  if (regionId == kRegionNewWorld) return newWorld();
  return null;
}

/// True when [regionId] is the Old World region constant; `false` for the New
/// World or any other id (no throw — callers that require validation use
/// [selectByMapRegionId]).
bool isOldWorldRegionId(String regionId) => regionId == kRegionOldWorld;
