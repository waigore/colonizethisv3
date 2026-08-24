// Shared naval combat test fixtures (Refs #3865).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Standard two-player setup for naval conflict and resolution tests.
const navalTestPlayers = [
  Player(id: 'p1', displayName: 'A', isHuman: true),
  Player(id: 'p2', displayName: 'B', isHuman: true),
];

/// Diplomacy relation between [p1] and [p2] with the given [state].
DiplomacyRelation navalDiplomacyRelation(RelationState state) =>
    DiplomacyRelation(factionId1: 'p1', factionId2: 'p2', state: state);

/// Two-player game with optional fleets and diplomacy for naval suites.
Game navalTwoPlayerGame({
  List<Fleet> fleets = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
}) => TestFixtures.minimalGame(
  id: 'g1',
  players: navalTestPlayers,
  fleets: fleets,
  diplomacyRelations: diplomacyRelations,
);

/// Two at-war fleets in the same sea zone (normalize / detection helpers).
Game navalGameTwoFleetsAtWar({required Fleet fleet1, required Fleet fleet2}) =>
    navalTwoPlayerGame(
      fleets: [fleet1, fleet2],
      diplomacyRelations: [navalDiplomacyRelation(RelationState.atWar)],
    );
