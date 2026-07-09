// Shared fixtures for order suggestion context helper scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final oschMinimalGame = Game(
  id: 'g1',
  worldState: WorldState(
    turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  ),
  players: const [Player(id: 'gp1', displayName: 'P1', isHuman: true)],
);

const oschEmptyTopology = MapTopology(nodes: [], edges: []);

Game oschDiplomacyGame() {
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
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        state: RelationState.atPeace,
        level: RelationLevel.neutral,
      ),
    ],
  );
}

const oschAllianceCandidate = DiplomaticOrder(
  type: DiplomaticOrderType.alliance,
  targetFactionId: 'gp2',
);
