// Shared Game fixtures for diplomacy_planner boycott/break/subsidy wiring pin
// (Refs #4310 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

Game diplomacyPlannerBoycottBreakSubsidyTwoGpAtPeaceGame({
  bool formalAlliance = false,
  bool holdsColony = false,
}) {
  return Game(
    id: 'g-diplomacy-planner-wiring',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: false),
      Player(id: 'gp2', displayName: 'B', isHuman: false),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: 50,
        level: RelationLevel.neutral,
        state: RelationState.atPeace,
        formalAlliance: formalAlliance,
      ),
    ],
    colonyStates: holdsColony
        ? const [
            ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 1),
          ]
        : const [],
    aiControlByGpId: const {'gp1': true},
  );
}
