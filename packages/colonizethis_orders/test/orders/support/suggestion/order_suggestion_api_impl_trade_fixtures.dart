// Shared trade API impl suggestion fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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

Game tradeApiImplGameWithStockpile(Stockpile stockpile) => Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(
          phase: TurnPhase.orders,
          turnNumber: 1,
        ),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: '$tradeApiImplOw|p1',
              regionId: tradeApiImplOw,
              ownerId: tradeApiImplPlayerId,
            ),
          ],
        ),
        newWorld: const RegionData(),
      ),
      players: [
        Player(
          id: tradeApiImplPlayerId,
          displayName: 'A',
          isHuman: false,
          capitalProvinceId: '$tradeApiImplOw|p1',
          stockpile: stockpile,
        ),
      ],
    );

Game tradeApiImplGameWithoutStockpile() => Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(
          phase: TurnPhase.orders,
          turnNumber: 1,
        ),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: '$tradeApiImplOw|p1',
              regionId: tradeApiImplOw,
              ownerId: tradeApiImplPlayerId,
            ),
          ],
        ),
        newWorld: const RegionData(),
      ),
      players: const [
        Player(
          id: tradeApiImplPlayerId,
          displayName: 'A',
          isHuman: false,
          capitalProvinceId: 'oldWorld|p1',
        ),
      ],
    );

PlayerView tradeApiImplViewFor(Game game) => buildPlayerView(
      game,
      tradeApiImplBaseTopology,
      tradeApiImplPlayerId,
    );
