// Shared fixtures for order suggestion pass context scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

const orderSuggestionPassContextTopology = MapTopology(nodes: [], edges: []);

const orderSuggestionPassContextGp1Id = 'gp1';
const orderSuggestionPassContextGp2Id = 'gp2';

Game orderSuggestionPassContextOwnedProvincesGame() => Game(
      id: 'g-owned',
      worldState: WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'p1',
              regionId: kOldWorldRegionId,
              ownerId: orderSuggestionPassContextGp1Id,
            ),
            Province(
              id: 'p2',
              regionId: kOldWorldRegionId,
              ownerId: orderSuggestionPassContextGp2Id,
            ),
          ],
        ),
        newWorld: const RegionData(),
      ),
      players: const [
        Player(
          id: orderSuggestionPassContextGp1Id,
          displayName: 'P1',
          isHuman: true,
        ),
        Player(
          id: orderSuggestionPassContextGp2Id,
          displayName: 'P2',
          isHuman: true,
        ),
      ],
    );
