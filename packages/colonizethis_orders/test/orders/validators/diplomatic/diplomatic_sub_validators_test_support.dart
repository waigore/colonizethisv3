/// Shared fixtures for the per-`DiplomaticOrderType` sub-validator tests
/// extracted under #2391 AC10.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/diplomatic_sub_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

export '../../diplomatic_orders_test_fixtures.dart' show gpMinorGame;

DiplomaticSubValidatorContext diplomaticSubValidatorContext(
  Game game,
  String playerId, {
  DiplomacyFactionMembership? factionMembership,
}) => DiplomaticSubValidatorContext(
  game: game,
  playerId: playerId,
  factionMembership: factionMembership,
);

Game twoGpGame({
  RelationState state = RelationState.atPeace,
  bool formalAlliance = false,
  int turnNumber = 0,
  List<AllianceBreakCooldownState> allianceBreakCooldowns = const [],
  Map<String, bool>? gp1TechUnlocked,
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: true,
        techUnlocked:
            gp1TechUnlocked ?? const {kTechIdDiplomaticExpertise: true},
      ),
      const Player(id: 'gp2', displayName: 'GP2', isHuman: false),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        state: state,
        formalAlliance: formalAlliance,
      ),
    ],
    allianceBreakCooldowns: allianceBreakCooldowns,
  );
}
