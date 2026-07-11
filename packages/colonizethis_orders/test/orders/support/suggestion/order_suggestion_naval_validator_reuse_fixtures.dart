// Naval validator-reuse fixtures (Refs #2394, #3949 wave 3, #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

const navalValidatorReuseTopology = MapTopology(nodes: [], edges: []);

Game navalValidatorReuseScenarioGame() => TestFixtures.minimalGame(
  id: 'g_naval_validator_reuse',
  players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
  fleets: [
    Fleet(
      id: 'f1',
      ownerId: 'gp1',
      seaZoneId: 'sea1',
      regionId: 'oldWorld',
      shipTypeIds: const ['carrack'],
    ),
  ],
);

PlayerView navalValidatorReuseViewFor(Game game) =>
    buildPlayerView(game, navalValidatorReuseTopology, 'gp1');
