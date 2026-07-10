// Fixtures for explorer Consulate-gate predicate scenarios (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

const ecgPlayerId = 'gp1';

Game ecgGameWith({List<OvertureState> overtures = const []}) {
  return TestFixtures.minimalGame(
    id: 'g1',
    players: const [
      Player(id: ecgPlayerId, displayName: 'GP One', isHuman: false),
      Player(id: 'gp2', displayName: 'GP Two', isHuman: false),
    ],
    tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe One')],
    overtureStates: overtures,
  );
}
