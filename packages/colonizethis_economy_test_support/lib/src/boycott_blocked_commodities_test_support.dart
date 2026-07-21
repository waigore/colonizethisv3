// dart format off
// Shared fixtures for `boycottedColonySellableCommodityIds` tests (Refs #3758 S7/R12; #3831; #4108).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'extraction_fixture_support.dart';
export 'fixture_builders/game_builders.dart' show gameWithColonyTribeBoycottTest;
const boycottColonyTribeNwRegionId = 'newWorld';
const boycottColonyTribeProvinceId = 'newWorld|t1';
Map<String, TileMapResult> tileMapsForBoycottColonyTribeTest() => {
  boycottColonyTribeNwRegionId: nonGpProvMap(boycottColonyTribeProvinceId, const [
    [Resource.furs],
  ]),
};
MapTopology topologyForBoycottColonyTribeTest() => const MapTopology(
  nodes: [TopologyNode(id: 't1', regionId: boycottColonyTribeNwRegionId, type: TopologyNodeType.province)],
  edges: [],
);
// dart format on
