// Shared GP shell fixtures for advanced-start unit tests.
// SPEC/game/advanced-starts.md (Refs #4086 Slice D).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Minimal GP game with optional OW units, fleets, and minors.
Game advancedStartGpGame({
  required Player player,
  List<Unit> oldWorldUnits = const [],
  List<Fleet> fleets = const [],
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  int turnNumber = 0,
}) {
  return TestFixtures.minimalGame(
    id: 'g1',
    turnNumber: turnNumber,
    oldWorld: RegionData(provinces: [], units: oldWorldUnits),
    newWorld: const RegionData(provinces: []),
    fleets: fleets,
    players: [player],
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// Default England human GP used across advanced-start slice tests.
const advancedStartDefaultPlayer = Player(
  id: 'gp1',
  displayName: 'England',
  isHuman: true,
  capitalProvinceId: 'oldWorld|p_cap',
);
