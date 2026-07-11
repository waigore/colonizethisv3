// Fixtures for diplomatic boycott suggestion scenarios (Refs #3949 wave 3,
// #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const orderSuggestionDiplomaticBoycottEmptyTopology = MapTopology(
  nodes: [],
  edges: [],
);

Game orderSuggestionDiplomaticBoycottTwoGpGame({
  bool holdsColony = true,
  RelationState state = RelationState.atPeace,
  RelationLevel level = RelationLevel.neutral,
  List<BoycottState> boycotts = const [],
  List<MinorNation> minors = const [],
}) {
  final game = ordersTwoGpEmptyGame(
    players: ordersCommonTwoGpAb,
    state: state,
    level: level,
    minorNations: minors,
  );
  return game.copyWith(
    colonyStates: holdsColony
        ? const [
            ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 1),
          ]
        : const [],
    boycottStates: boycotts,
  );
}
