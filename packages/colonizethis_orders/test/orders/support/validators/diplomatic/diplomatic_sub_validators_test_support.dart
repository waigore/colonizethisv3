/// Shared fixtures for the per-`DiplomaticOrderType` sub-validator tests
/// extracted under #2391 AC10.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/diplomatic_sub_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../common/game_graphs.dart';

export '../../diplomatic/diplomatic_orders_test_fixtures.dart' show gpMinorGame;

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
  final game = ordersTwoGpEmptyGame(
    turnNumber: turnNumber,
    state: state,
    formalAlliance: formalAlliance,
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: true,
        techUnlocked:
            gp1TechUnlocked ?? const {kTechIdDiplomaticExpertise: true},
      ),
      ordersCommonGp2,
    ],
  );
  if (allianceBreakCooldowns.isEmpty) {
    return game;
  }
  return game.copyWith(allianceBreakCooldowns: allianceBreakCooldowns);
}
