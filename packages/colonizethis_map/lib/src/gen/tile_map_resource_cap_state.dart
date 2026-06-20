import 'package:colonizethis_data/colonizethis_data.dart';

/// Tracks both-count and total for multi-region resource cap (Pass 7).
/// SPEC/game/resource-terrain-region-rules.md.
class MultiRegionCapState {
  MultiRegionCapState(this.capFraction, this.rules, this.regionId);

  /// Rebuilds cap counts from an existing [resourceGrid].
  ///
  /// When [terrainGrid] is supplied, cells on forest terrain are skipped:
  /// guaranteed forest resource placements (R3, issue #3573) are excluded from
  /// the multi-region cap accounting, mirroring the bootstrap-grain exclusion.
  /// SPEC/program/tile-map-gen-resources.md.
  factory MultiRegionCapState.fromExisting(
    double capFraction,
    ResourceRules rules,
    String regionId,
    List<List<Resource?>> resourceGrid, {
    List<List<TerrainType?>>? terrainGrid,
  }) {
    var both = 0;
    var total = 0;
    for (var y = 0; y < resourceGrid.length; y++) {
      final row = resourceGrid[y];
      for (var x = 0; x < row.length; x++) {
        final r = row[x];
        if (r == null) continue;
        final terrain = terrainGrid?[y][x];
        if (terrain != null && isForestTerrain(terrain)) continue;
        total++;
        if (rules.regionRule[r] == ResourceRegionRule.both) both++;
      }
    }
    final state = MultiRegionCapState(capFraction, rules, regionId);
    state.bothCount = both;
    state.totalCount = total;
    return state;
  }

  int bothCount = 0;
  int totalCount = 0;
  final double capFraction;
  final ResourceRules rules;
  final String regionId;

  bool shouldRestrictToRegionOnly(List<Resource> allowed) {
    if (totalCount == 0) return false;
    if (bothCount / totalCount < capFraction) return false;
    final hasBoth = allowed.any(
      (resource) => rules.regionRule[resource] == ResourceRegionRule.both,
    );
    final hasRegionOnly = allowed.any(
      (resource) => rules.regionRule[resource] != ResourceRegionRule.both,
    );
    return hasBoth && hasRegionOnly;
  }

  List<Resource> filterToRegionOnly(List<Resource> allowed) => allowed
      .where(
        (resource) => rules.regionRule[resource] != ResourceRegionRule.both,
      )
      .toList();

  void record(Resource resource) {
    totalCount++;
    if (rules.regionRule[resource] == ResourceRegionRule.both) {
      bothCount++;
    }
  }
}
