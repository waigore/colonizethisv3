import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:meta/meta.dart';

/// Batch topology adjacency for colonial naval scoring (Refs #4669 Slice A).
///
/// Builds the undirected adjacency map and node-type index once per
/// [MapTopology], then answers sea-zone queries without re-walking
/// [MapTopology.edges] for each candidate move.
class ColonialNavalTopologyContext {
  ColonialNavalTopologyContext._(MapTopology topology)
    : _adjacency = _buildAdjacency(topology.edges),
      _nodeType = {
        for (final n in topology.nodes) n.id: n.type,
      };

  factory ColonialNavalTopologyContext.fromTopology(MapTopology topology) {
    return ColonialNavalTopologyContext._(topology);
  }

  final Map<String, Set<String>> _adjacency;
  final Map<String, TopologyNodeType> _nodeType;

  @visibleForTesting
  static int contextBuildCountForTesting = 0;

  @visibleForTesting
  static void resetContextBuildCountForTesting() {
    contextBuildCountForTesting = 0;
  }

  static Map<String, Set<String>> _buildAdjacency(List<TopologyEdge> edges) {
    contextBuildCountForTesting++;
    final adj = <String, Set<String>>{};
    for (final e in edges) {
      adj.putIfAbsent(e.id1, () => <String>{}).add(e.id2);
      adj.putIfAbsent(e.id2, () => <String>{}).add(e.id1);
    }
    return adj;
  }

  Set<String> newWorldSeaZonesAdjacentToInvadableProvinces(
    List<String> invadableNewWorldProvinceIdsSorted,
  ) {
    if (invadableNewWorldProvinceIdsSorted.isEmpty) return const {};
    final invadable = invadableNewWorldProvinceIdsSorted.toSet();
    final out = <String>{};
    for (final provId in invadable) {
      for (final nb in _adjacency[provId] ?? const <String>{}) {
        if (_nodeType[nb] != TopologyNodeType.seaZone) continue;
        if (ProvinceId.regionIdFrom(nb) != kNewWorldRegionId) continue;
        out.add(nb);
      }
    }
    return out;
  }

  bool isOldWorldSeaAdjacentToNewWorldSea(String oldWorldSeaZoneId) {
    if (ProvinceId.regionIdFrom(oldWorldSeaZoneId) != kOldWorldRegionId) {
      return false;
    }
    for (final nb in _adjacency[oldWorldSeaZoneId] ?? const <String>{}) {
      if (ProvinceId.regionIdFrom(nb) == kNewWorldRegionId) return true;
    }
    return false;
  }
}
