// Shared trade API impl suggestion fixtures (Refs #3949 wave 3, #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const tradeApiImplPlayerId = 'gp1';
const tradeApiImplOw = 'oldWorld';

final tradeApiImplBaseTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'p1',
      regionId: tradeApiImplOw,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

Game tradeApiImplGameWithStockpile(Stockpile stockpile) => ordersOwRegionGame(
  turnNumber: 1,
  players: [
    Player(
      id: tradeApiImplPlayerId,
      displayName: 'A',
      isHuman: false,
      capitalProvinceId: '$tradeApiImplOw|p1',
      stockpile: stockpile,
    ),
  ],
  oldWorld: RegionData(
    provinces: [
      Province(
        id: '$tradeApiImplOw|p1',
        regionId: tradeApiImplOw,
        ownerId: tradeApiImplPlayerId,
      ),
    ],
  ),
);

Game tradeApiImplGameWithoutStockpile() => ordersOwRegionGame(
  turnNumber: 1,
  players: const [
    Player(
      id: tradeApiImplPlayerId,
      displayName: 'A',
      isHuman: false,
      capitalProvinceId: 'oldWorld|p1',
    ),
  ],
  oldWorld: RegionData(
    provinces: [
      Province(
        id: '$tradeApiImplOw|p1',
        regionId: tradeApiImplOw,
        ownerId: tradeApiImplPlayerId,
      ),
    ],
  ),
);

PlayerView tradeApiImplViewFor(Game game) =>
    buildPlayerView(game, tradeApiImplBaseTopology, tradeApiImplPlayerId);
