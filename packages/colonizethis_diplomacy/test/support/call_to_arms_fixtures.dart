import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared three-power game fixture for call-to-arms (alliance mutual defence)
/// tests. Extracted so the call-to-arms suites stay within the split
/// domain-package test file size cap (Refs #3625).
Game threePowerCallToArmsGame({
  required bool gp1Human,
  required bool gp2Human,
  required int gp1gp2Score,
  RelationLevel gp1gp2Level = RelationLevel.allied,
  bool gp1gp2FormalAlliance = true,
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < kObserverConquestMinOwProvincesPerGp; i++)
            Province(
              id: 'oldWorld|gp3_$i',
              regionId: 'oldWorld',
              ownerId: 'gp3',
            ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: gp1Human,
      ),
      Player(
        id: 'gp2',
        displayName: 'GP2',
        isHuman: gp2Human,
      ),
      Player(
        id: 'gp3',
        displayName: 'GP3',
        isHuman: false,
      ),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: gp1gp2Score,
        level: gp1gp2Level,
        state: RelationState.atPeace,
        sinceTurn: 0,
        lastInteractionTurn: 0,
        formalAlliance: gp1gp2FormalAlliance,
      ),
      DiplomacyRelation(
        factionId1: 'gp2',
        factionId2: 'gp3',
        score: 50,
        level: RelationLevel.neutral,
        state: RelationState.atPeace,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp3',
        score: 50,
        level: RelationLevel.neutral,
        state: RelationState.atPeace,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
    ],
  );
}
