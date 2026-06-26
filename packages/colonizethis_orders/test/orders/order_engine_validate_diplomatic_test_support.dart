import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const emptyTopology = MapTopology(nodes: [], edges: []);

Game gpMinorBaseGame({
  RelationState relationState = RelationState.atPeace,
  int relationScore = 50,
  OvertureStage overtureStage = OvertureStage.none,
  int treasury = 5000,
  Map<String, bool>? techUnlocked,
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: true,
        treasury: treasury,
        techUnlocked: techUnlocked ?? const {kTechIdDiplomaticExpertise: true},
      ),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'minor1',
        state: relationState,
        score: relationScore,
      ),
    ],
    overtureStates: [
      OvertureState(
        gpId: 'gp1',
        targetId: 'minor1',
        stage: overtureStage,
        sinceTurn: 0,
      ),
    ],
  );
}
