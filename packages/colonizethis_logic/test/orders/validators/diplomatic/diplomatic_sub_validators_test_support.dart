/// Shared fixtures for the per-`DiplomaticOrderType` sub-validator tests
/// extracted under #2391 AC10.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/orders/validators/diplomatic/diplomatic_sub_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

DiplomaticSubValidatorContext diplomaticSubValidatorContext(
  Game game,
  String playerId, {
  DiplomacyFactionMembership? factionMembership,
}) => DiplomaticSubValidatorContext(
  game: game,
  playerId: playerId,
  factionMembership: factionMembership,
);

Game gpMinorGame({
  RelationState relationState = RelationState.atPeace,
  int relationScore = 50,
  OvertureStage overtureStage = OvertureStage.none,
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

Game twoGpGame({RelationState state = RelationState.atPeace}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: true),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
    ],
    diplomacyRelations: [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', state: state),
    ],
  );
}
