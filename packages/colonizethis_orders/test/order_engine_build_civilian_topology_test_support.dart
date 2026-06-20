import 'package:colonizethis_data/colonizethis_data.dart';

/// Single-province OW topology shared by civilian build validation tests.
///
/// Refs waigore/colonizethis#2216.
MapTopology civilianBuildSingleProvinceTopology({
  String regionId = 'oldWorld',
  String nodeId = 'P1',
}) => MapTopology(
  nodes: [
    TopologyNode(
      id: nodeId,
      regionId: regionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);
