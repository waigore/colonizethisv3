// Naval validator-reuse fixtures (Refs #2394, #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const navalValidatorReuseTopology = MapTopology(nodes: [], edges: []);

Game navalValidatorReuseScenarioGame() {
  return Game(
    id: 'g_naval_validator_reuse',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: 'f1',
          ownerId: 'gp1',
          seaZoneId: 'sea1',
          regionId: 'oldWorld',
          shipTypeIds: const ['carrack'],
        ),
      ],
    ),
    players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
  );
}

PlayerView navalValidatorReuseViewFor(Game game) =>
    buildPlayerView(game, navalValidatorReuseTopology, 'gp1');
