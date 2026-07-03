// VM/desktop seed-42 [InitGameResult] loader (Refs #3656, #3847).

import 'dart:typed_data';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

import 'seed42_fixture_loader_vm.dart';
import 'seed42_tile_map_loader.dart';

InitGameResult? _cachedSeed42InitGameResult;

/// Builds an [InitGameResult] from committed seed-42 JSON fixtures instead of
/// the ~7-11s procedural `runInitGame` generator.
InitGameResult loadSeed42InitGameResult() {
  return _cachedSeed42InitGameResult ??= _buildSeed42InitGameResult();
}

InitGameResult _buildSeed42InitGameResult() {
  final mapViewData = loadSeed42MapViewData();
  final combinedTopology = mapViewData.combinedTopology;
  return InitGameResult(
    game: loadSeed42Game(),
    mapPngBytes: Uint8List(0),
    markdown: '',
    mapViewData: mapViewData,
    tileMapByRegion: loadSeed42TileMapByRegion(),
    topologyByRegion: _topologyByRegionFromCombined(combinedTopology),
    combinedTopology: combinedTopology,
  );
}

Map<String, MapTopology> _topologyByRegionFromCombined(MapTopology combined) {
  final nodesByRegion = <String, List<TopologyNode>>{};
  for (final node in combined.nodes) {
    nodesByRegion.putIfAbsent(node.regionId, () => []).add(
          TopologyNode(
            id: _localTopologyId(node.id),
            regionId: node.regionId,
            type: node.type,
          ),
        );
  }

  final edgesByRegion = <String, List<TopologyEdge>>{};
  for (final edge in combined.edges) {
    final regionId = _regionIdFromPrefixedTopologyId(edge.id1);
    if (regionId == null || regionId != _regionIdFromPrefixedTopologyId(edge.id2)) {
      continue;
    }
    edgesByRegion.putIfAbsent(regionId, () => []).add(
          TopologyEdge(
            id1: _localTopologyId(edge.id1),
            id2: _localTopologyId(edge.id2),
          ),
        );
  }

  final regionIds = <String>{
    ...nodesByRegion.keys,
    ...edgesByRegion.keys,
  };
  return <String, MapTopology>{
    for (final regionId in regionIds)
      regionId: MapTopology(
        nodes: nodesByRegion[regionId] ?? const [],
        edges: edgesByRegion[regionId] ?? const [],
      ),
  };
}

String _localTopologyId(String prefixedId) {
  final separator = prefixedId.indexOf('|');
  return separator < 0 ? prefixedId : prefixedId.substring(separator + 1);
}

String? _regionIdFromPrefixedTopologyId(String prefixedId) {
  final separator = prefixedId.indexOf('|');
  if (separator <= 0) {
    return null;
  }
  return prefixedId.substring(0, separator);
}
