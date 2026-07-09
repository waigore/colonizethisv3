// Fixtures for diplomatic boycott suggestion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const orderSuggestionDiplomaticBoycottEmptyTopology =
    MapTopology(nodes: [], edges: []);

Game orderSuggestionDiplomaticBoycottTwoGpGame({
  bool holdsColony = true,
  RelationState state = RelationState.atPeace,
  RelationLevel level = RelationLevel.neutral,
  List<BoycottState> boycotts = const [],
  List<MinorNation> minors = const [],
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: false),
      Player(id: 'gp2', displayName: 'B', isHuman: false),
    ],
    minorNations: minors,
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        state: state,
        level: level,
      ),
    ],
    colonyStates: holdsColony
        ? const [
            ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 1),
          ]
        : const [],
    boycottStates: boycotts,
  );
}
