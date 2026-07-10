// Shared diplomatic GP API impl suggestion fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const diplomaticApiImplTopology = MapTopology(nodes: [], edges: []);

const diplomaticApiImplTwoGpPlayers = [
  Player(id: 'gp1', displayName: 'A', isHuman: false),
  Player(id: 'gp2', displayName: 'B', isHuman: false),
];

Game diplomaticApiImplGame({
  required List<DiplomacyRelation> diplomacyRelations,
}) =>
    Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: diplomaticApiImplTwoGpPlayers,
      diplomacyRelations: diplomacyRelations,
    );

PlayerView diplomaticApiImplViewFor(Game game) => buildPlayerView(
      game,
      diplomaticApiImplTopology,
      'gp1',
    );
