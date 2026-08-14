// Shared fixtures for diplomacy_intervention_diplomacy_phase_test
// (Refs #4342 Slice C).
import 'package:colonizethis_models/colonizethis_models.dart';

const interventionOw = 'oldWorld';
const interventionMinorProvId = '$interventionOw|M1';
const interventionNw = 'newWorld';
const interventionTribeProvId = '$interventionNw|T1';
const interventionTribeTileKey = '$interventionNw|T1|0|0';

Orders interventionDeclareWarOrders(String targetFactionId) => Orders(
  diplomaticOrdersByPlayerId: {
    'gp2': [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: targetFactionId,
      ),
    ],
  },
);

Game interventionEmbassyMinorGame({
  required bool gp1Human,
  int turnNumber = 2,
  int gp1MinorScore = 50,
  RelationLevel gp1MinorLevel = RelationLevel.neutral,
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: interventionMinorProvId,
            regionId: interventionOw,
            ownerId: 'minor1',
          ),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: gp1Human ? 'Human' : 'AI friend',
        isHuman: gp1Human,
      ),
      const Player(id: 'gp2', displayName: 'Aggressor', isHuman: false),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'minor1',
        score: gp1MinorScore,
        level: gp1MinorLevel,
        state: RelationState.atPeace,
      ),
      const DiplomacyRelation(
        factionId1: 'gp2',
        factionId2: 'minor1',
        state: RelationState.atPeace,
      ),
    ],
    overtureStates: const [
      OvertureState(
        gpId: 'gp1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
}

Game interventionTribePurchasedLandGame() {
  return const Game(
    id: 'g1',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(
        provinces: [
          Province(
            id: interventionTribeProvId,
            regionId: interventionNw,
            ownerId: 'tribe1',
          ),
        ],
        units: [],
      ),
      purchasedTilesByTileKey: {interventionTribeTileKey: 'gp1'},
    ),
    players: [
      Player(id: 'gp1', displayName: 'Human', isHuman: true),
      Player(id: 'gp2', displayName: 'Aggressor', isHuman: false),
    ],
    tribes: [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'tribe1',
        state: RelationState.atPeace,
      ),
      DiplomacyRelation(
        factionId1: 'gp2',
        factionId2: 'tribe1',
        state: RelationState.atPeace,
      ),
    ],
  );
}
