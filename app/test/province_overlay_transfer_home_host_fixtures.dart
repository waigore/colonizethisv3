// Fixtures for MAP20001 Transfer host tests (Refs #4734 Slice D).

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

GameMapData adjacentSeaMapForTransferHome() {
  return (
    combinedTopology: const MapTopology(
      edges: [TopologyEdge(id1: 'oldWorld|cap1', id2: 'oldWorld|sea1')],
    ),
    tileMapByRegion: const {},
    topologyByRegion: const {},
    warpLinks: null,
  );
}

Fleet inPortPeerForTransferHome(String humanId, String id) {
  return Fleet(
    id: id,
    ownerId: humanId,
    regionId: 'oldWorld',
    inPortAtProvinceId: 'oldWorld|cap1',
    ships: [ShipInstance(id: '${id}_s', typeId: 'carrack')],
  );
}
