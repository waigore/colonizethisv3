// Shared diplomatic GP API impl suggestion fixtures (Refs #3949 wave 3,
// #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const diplomaticApiImplTopology = MapTopology(nodes: [], edges: []);

const diplomaticApiImplTwoGpPlayers = ordersCommonTwoGpAb;

Game diplomaticApiImplGame({
  required List<DiplomacyRelation> diplomacyRelations,
}) => ordersTwoGpEmptyGame(
  players: diplomaticApiImplTwoGpPlayers,
  diplomacyRelations: diplomacyRelations,
);

PlayerView diplomaticApiImplViewFor(Game game) =>
    buildPlayerView(game, diplomaticApiImplTopology, 'gp1');
