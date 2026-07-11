// Shared fixtures for boycott / revokeBoycott validator scenarios (Refs #3949
// wave 3, #3971 wave 4).
//
// Refs #3753 R6. SPEC/program/orders.md § Diplomatic orders;
// SPEC/game/diplomacy.md § GP–Tribe Rules (Boycott).

import 'package:colonizethis_models/colonizethis_models.dart';

import '../../common/game_graphs.dart';

Game boycottValidatorColonyHolderGame({
  bool holdsColony = true,
  RelationState state = RelationState.atPeace,
  List<BoycottState> boycotts = const [],
}) {
  final game = ordersTwoGpEmptyGame(
    turnNumber: 3,
    state: state,
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
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
