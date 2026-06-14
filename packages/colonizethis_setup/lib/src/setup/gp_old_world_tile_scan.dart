// SPEC/game/tile-map-and-generation.md; SPEC/program/game-setup-pipeline.md (§7d).
//
// Package-internal source of truth for Great Power Old World land tile scanning
// shared by the resource redistribution (§7d.redist) and terrain redistribution
// (§7d.terrain) concerns (Refs #3449). Both concerns previously carried verbatim
// private copies of the owner map, the tile-key builder, the GP-id predicate, and
// nearly identical `for (y) for (x)` grid walks. Centralising them here keeps the
// owner mapping, deterministic (y, x) iteration order, and tile-key shape
// byte-identical across both consumers and any future GP OW tile scan.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Canonical Old World tile key for the GP-owned grid cell at ([x], [y]) in
/// province [localProvinceId]. Single source of truth for both redistribution
/// concerns (previously duplicated as private `_owTileKey`).
String gpOwTileKey(String localProvinceId, int x, int y) => CapitalTile.tileKey(
  kRegionOldWorld,
  ProvinceId.full(kRegionOldWorld, localProvinceId),
  x,
  y,
);

/// Maps local Old World province grid id → owning faction id (empty string when
/// unowned). Single source of truth (previously duplicated as private
/// `_ownerByLocalProvinceId`).
Map<String, String> gpOwnerByLocalProvinceId(Game game) {
  final m = <String, String>{};
  for (final p in game.worldState.provincesForRegion(kRegionOldWorld)) {
    m[ProvinceId.localIdFrom(p.id)] = p.ownerId ?? '';
  }
  return m;
}

/// Whether [id] is one of the Great Power ids in [gpIds] (previously duplicated
/// as private `_isGpId`).
bool isGpOwner(String id, Set<String> gpIds) => gpIds.contains(id);

/// Callback invoked for each GP-owned Old World land tile during a grid scan.
/// [tileKey] is the canonical [gpOwTileKey] for ([x], [y]).
typedef GpOwLandTileVisitor =
    void Function(
      int x,
      int y,
      String localProvinceId,
      String ownerId,
      String tileKey,
    );

/// Visits every GP-owned Old World land tile (terrain present) in deterministic
/// (y outer, x inner) order, invoking [visit] with the cell's coordinates,
/// local province id, owner id, and canonical tile key.
///
/// This is the single grid-walk skeleton shared by the resource and terrain
/// redistribution scans; callers apply their own per-tile predicates
/// (forbidden/used/resource/terrain) inside [visit].
void visitGpOwLandTiles({
  required TileMapResult map,
  required Map<String, String> ownerByLocal,
  required Set<String> gpIds,
  required GpOwLandTileVisitor visit,
}) {
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      final local = map.cell(x, y);
      final owner = ownerByLocal[local];
      if (owner == null || !isGpOwner(owner, gpIds)) continue;
      if (map.terrainAt(x, y) == null) continue;
      visit(x, y, local, owner, gpOwTileKey(local, x, y));
    }
  }
}

/// A GP-owned Old World land tile eligible for redistribution (town/capital
/// tiles excluded). Sorted by player slot order, then [y], then [x].
class GpOwLandTile {
  const GpOwLandTile({required this.x, required this.y, required this.gpId});

  final int x;
  final int y;
  final String gpId;
}

/// Collects GP-owned Old World land tiles (excluding [forbidden] town/capital
/// keys) sorted by player slot order in [gpIdsSorted], then [y], then [x] —
/// the deterministic eligible-tile ordering shared by GP OW redistribution.
List<GpOwLandTile> collectGpOwEligibleTilesSorted({
  required TileMapResult map,
  required List<String> gpIdsSorted,
  required Set<String> gpIds,
  required Map<String, String> ownerByLocal,
  required Set<String> forbidden,
}) {
  final gpIndex = <String, int>{
    for (var i = 0; i < gpIdsSorted.length; i++) gpIdsSorted[i]: i,
  };
  final out = <GpOwLandTile>[];
  visitGpOwLandTiles(
    map: map,
    ownerByLocal: ownerByLocal,
    gpIds: gpIds,
    visit: (x, y, local, owner, key) {
      if (forbidden.contains(key)) return;
      out.add(GpOwLandTile(x: x, y: y, gpId: owner));
    },
  );
  out.sort((a, b) {
    final ia = gpIndex[a.gpId] ?? 999;
    final ib = gpIndex[b.gpId] ?? 999;
    final c = ia.compareTo(ib);
    if (c != 0) return c;
    final cy = a.y.compareTo(b.y);
    if (cy != 0) return cy;
    return a.x.compareTo(b.x);
  });
  return out;
}
