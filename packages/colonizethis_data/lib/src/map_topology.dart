import 'topology_node.dart';
import 'data_validation_exception.dart';

/// Static map topology: nodes (provinces, sea zones) and undirected edges. SPEC/program/map-data.md.
class MapTopology {
  const MapTopology({this.nodes = const [], this.edges = const []});

  final List<TopologyNode> nodes;
  final List<TopologyEdge> edges;

  static const String _keyNodes = 'nodes';
  static const String _keyEdges = 'edges';

  Map<String, dynamic> toJson() => {
    _keyNodes: nodes.map((e) => e.toJson()).toList(),
    _keyEdges: edges.map((e) => e.toJson()).toList(),
  };

  static MapTopology fromJson(Map<String, dynamic> json) {
    final nodesList = json[_keyNodes] as List<dynamic>? ?? [];
    final edgesList = json[_keyEdges] as List<dynamic>? ?? [];
    final edges = edgesList.map<TopologyEdge>((e) {
      if (e is List<dynamic>) return TopologyEdge.fromJsonList(e);
      return TopologyEdge.fromJson(
        Map<String, dynamic>.from(e as Map<Object?, Object?>),
      );
    }).toList();
    return MapTopology(
      nodes: nodesList
          .map(
            (e) => TopologyNode.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList(),
      edges: edges,
    );
  }
}

/// Undirected edge between two topology nodes (by id). P<->P, P<->S, or S<->S.
class TopologyEdge {
  const TopologyEdge({required this.id1, required this.id2});

  final String id1;
  final String id2;

  static const String _keyId1 = 'id1';
  static const String _keyId2 = 'id2';

  Map<String, dynamic> toJson() => {_keyId1: id1, _keyId2: id2};

  static TopologyEdge fromJson(Map<String, dynamic> json) {
    return TopologyEdge(
      id1: json[_keyId1] as String,
      id2: json[_keyId2] as String,
    );
  }

  /// From a two-element list [id1, id2] (e.g. JSON array edge).
  static TopologyEdge fromJsonList(List<dynamic> list) {
    if (list.length < 2) throw DataValidationException('Edge needs two ids');
    return TopologyEdge(id1: list[0] as String, id2: list[1] as String);
  }
}
