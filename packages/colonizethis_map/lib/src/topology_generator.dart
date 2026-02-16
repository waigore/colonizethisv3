// SPEC/program/map-data.md § Topology generation.

import 'package:colonizethis_data/colonizethis_data.dart';

/// Parameters for generating a region topology. CLI restricts numContinents to 2–4.
class TopologyGeneratorParams {
  const TopologyGeneratorParams({
    required this.numProvinces,
    required this.numContinents,
    this.regionId = 'oldWorld',
    this.seed,
  })  : assert(numProvinces >= 1),
        assert(numContinents >= 1);

  final int numProvinces;
  final int numContinents;
  final String regionId;
  final int? seed;
}

/// Generates a [MapTopology] from province count, continent count, and region.
/// Each continent is a connected land subgraph; each has at least one coastal province (P–S edge).
MapTopology generateTopology(TopologyGeneratorParams params) {
  final regionId = params.regionId;
  final n = params.numProvinces;
  final c = params.numContinents;

  final nodes = <TopologyNode>[];
  for (var i = 1; i <= n; i++) {
    nodes.add(TopologyNode(
      id: 'p$i',
      regionId: regionId,
      type: TopologyNodeType.province,
    ));
  }
  nodes.add(TopologyNode(
    id: 's1',
    regionId: regionId,
    type: TopologyNodeType.seaZone,
  ));

  final edges = <TopologyEdge>[];

  // Partition provinces into numContinents groups (by index, roughly equal size).
  final continentSize = n ~/ c;
  final remainder = n % c;
  var start = 0;
  final continentStarts = <int>[];
  for (var i = 0; i < c; i++) {
    continentStarts.add(start);
    final size = continentSize + (i < remainder ? 1 : 0);
    start += size;
  }
  continentStarts.add(n); // end index

  for (var cont = 0; cont < c; cont++) {
    final lo = continentStarts[cont];
    final hi = continentStarts[cont + 1];
    if (lo >= hi) continue;

    // Land edges: chain p_lo+1 .. p_hi (1-based: p(lo+1) .. p(hi))
    for (var i = lo; i < hi - 1; i++) {
      edges.add(TopologyEdge(id1: 'p${i + 1}', id2: 'p${i + 2}'));
    }

    // Coastal: first and last province of this continent get P–S edge
    edges.add(TopologyEdge(id1: 'p${lo + 1}', id2: 's1'));
    if (hi - lo > 1) {
      edges.add(TopologyEdge(id1: 'p$hi', id2: 's1'));
    }
  }

  return MapTopology(nodes: nodes, edges: edges);
}

