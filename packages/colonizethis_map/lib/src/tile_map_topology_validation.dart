// SPEC/program/tile-map-gen-resources.md § Topology inference.

import 'package:colonizethis_data/colonizethis_data.dart';

/// Result of comparing grid adjacencies to topology. SPEC/program/tile-map-gen-resources.md § Topology inference.
class TileMapTopologyValidationResult {
  TileMapTopologyValidationResult({
    required this.missing,
    required this.extra,
  });

  /// Required adjacencies (from topology) that are not present in the grid.
  final Set<String> missing;
  /// Grid adjacencies that are not in the topology.
  final Set<String> extra;

  /// True if any required pair is missing or any extra adjacency exists.
  bool get hasIssues => missing.isNotEmpty || extra.isNotEmpty;
}

/// Normalized pair key (same as TileMapResult.adjacentRegionPairs()).
String _pairKey(String a, String b) =>
    a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';

/// Compares grid adjacencies to topology edges. Returns missing and extra pairs.
/// SPEC/program/tile-map-gen-resources.md § Topology inference.
TileMapTopologyValidationResult validateTileMapTopology(
  MapTopology topology,
  TileMapResult result,
) {
  final required = <String>{};
  for (final e in topology.edges) {
    required.add(_pairKey(e.id1, e.id2));
  }
  final actual = result.adjacentRegionPairs();
  return TileMapTopologyValidationResult(
    missing: required.difference(actual),
    extra: actual.difference(required),
  );
}

