import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/validators/naval_order_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

/// Shared region id for [NavalOrderValidator] test topologies.
const kNavalOrderValidatorTestRegionId = 'oldWorld';

/// Default human player id in naval validator tests.
const kNavalOrderValidatorTestPlayerId = 'p1';

const _defaultHumanPlayer = Player(
  id: kNavalOrderValidatorTestPlayerId,
  displayName: 'P1',
  isHuman: true,
);

TopologyNode navalOrderValidatorTestSeaNode(String localId) => TopologyNode(
  id: localId,
  regionId: kNavalOrderValidatorTestRegionId,
  type: TopologyNodeType.seaZone,
);

TopologyNode navalOrderValidatorTestProvinceNode(String localId) =>
    TopologyNode(
      id: localId,
      regionId: kNavalOrderValidatorTestRegionId,
      type: TopologyNodeType.province,
    );

MapTopology navalOrderValidatorTestTopology({
  required List<TopologyNode> nodes,
  List<TopologyEdge> edges = const [],
}) => MapTopology(nodes: nodes, edges: edges);

Province navalOrderValidatorTestOwnedProvince(
  String localId, {
  String ownerId = kNavalOrderValidatorTestPlayerId,
}) => Province(
  id: ProvinceId.full(kNavalOrderValidatorTestRegionId, localId),
  regionId: kNavalOrderValidatorTestRegionId,
  ownerId: ownerId,
);

Fleet navalOrderValidatorTestFleetAtSea({
  String fleetId = 'f1',
  String ownerId = kNavalOrderValidatorTestPlayerId,
  String seaZoneId = 'sea1',
}) => Fleet(
  id: fleetId,
  ownerId: ownerId,
  seaZoneId: seaZoneId,
  regionId: kNavalOrderValidatorTestRegionId,
  shipTypeIds: const ['carrack'],
);

Fleet navalOrderValidatorTestFleetInPort({
  String fleetId = 'f1',
  String ownerId = kNavalOrderValidatorTestPlayerId,
  String portLocalId = 'P1',
  String? inPortAtProvinceId,
}) {
  final portId =
      inPortAtProvinceId ??
      ProvinceId.full(kNavalOrderValidatorTestRegionId, portLocalId);
  return Fleet(
    id: fleetId,
    ownerId: ownerId,
    seaZoneId: null,
    inPortAtProvinceId: portId,
    regionId: kNavalOrderValidatorTestRegionId,
    shipTypeIds: const ['carrack'],
  );
}

Fleet navalOrderValidatorTestFleetBrokenInPort({
  String fleetId = 'f1',
  String ownerId = kNavalOrderValidatorTestPlayerId,
}) => Fleet(
  id: fleetId,
  ownerId: ownerId,
  seaZoneId: null,
  inPortAtProvinceId: null,
  regionId: kNavalOrderValidatorTestRegionId,
  shipTypeIds: const ['carrack'],
);

Game navalOrderValidatorTestGame({
  List<Fleet> fleets = const [],
  List<Province> oldWorldProvinces = const [],
  List<Player> players = const [_defaultHumanPlayer],
  String gameId = 'g1',
}) => ordersOwRegionGame(
  id: gameId,
  players: players,
  oldWorld: RegionData(provinces: oldWorldProvinces),
  fleets: fleets,
);

NavalOrderValidator navalOrderValidatorForTest({
  required Game game,
  required MapTopology topology,
  String playerId = kNavalOrderValidatorTestPlayerId,
}) => NavalOrderValidator(game: game, topology: topology, playerId: playerId);
