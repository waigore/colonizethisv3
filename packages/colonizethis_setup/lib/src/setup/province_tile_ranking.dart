// SPEC/game/tile-map-and-generation.md § Great Power starting grain;
// SPEC/game/factions.md § Starting developed resources;
// SPEC/program/game-setup-pipeline.md.
//
// Package-internal source of truth for ranking the tiles of a single capital
// province by Manhattan distance from the capital. Both the Great Power
// starting-grain selection (gp_starting_grain.dart) and the Minor Nation /
// Tribe starting-development selection (minor_tribe_starting_development.dart)
// previously carried a byte-identical `for (y) for (x)` walk that filtered to
// one local province, built `(int dist, int y, int x, String key)` tuples, and
// sorted with the same `dist → y → x` comparator before `take(n)`. Only the
// per-tile eligibility predicate differed. Centralising the walk and sort here
// keeps the deterministic selection order identical across both consumers.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Decides whether the cell at ([x], [y]) — whose canonical tile key is
/// [tileKey] — is eligible for selection. The shared ranking helper computes
/// the distance and ordering; callers supply only this predicate.
typedef ProvinceTileEligibility =
    bool Function(int x, int y, String tileKey);

/// Returns the tile keys of [capital]'s province in [map] ranked by Manhattan
/// distance from the capital ascending, then `y` ascending, then `x`
/// ascending. Only cells in the capital's local province for which [accept]
/// returns `true` are included.
///
/// Returns at most [maxTiles] keys when [maxTiles] is non-null; otherwise all
/// eligible tiles in ranked order.
List<String> rankProvinceTileKeysByDistance({
  required TileMapResult map,
  required CapitalTile capital,
  required ProvinceTileEligibility accept,
  int? maxTiles,
}) {
  final regionId = capital.regionId;
  final localId = ProvinceId.isPrefixed(capital.provinceId)
      ? ProvinceId.localIdFrom(capital.provinceId)
      : capital.provinceId;
  final ranked = <(int dist, int y, int x, String key)>[];
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      if (map.cell(x, y) != localId) continue;
      final key = CapitalTile.tileKey(regionId, capital.provinceId, x, y);
      if (!accept(x, y, key)) continue;
      final dist = (x - capital.x).abs() + (y - capital.y).abs();
      ranked.add((dist, y, x, key));
    }
  }
  ranked.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    if (c != 0) return c;
    final cy = a.$2.compareTo(b.$2);
    if (cy != 0) return cy;
    return a.$3.compareTo(b.$3);
  });
  final keys = ranked.map((e) => e.$4);
  return (maxTiles == null ? keys : keys.take(maxTiles)).toList();
}
