import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Shared fixture for [diplomacy_resolver_phase_test_part*_test.dart].
///
/// Built on the shared [TestFixtures.minimalGame] factory (Refs #3715): the
/// previous inline `Game`/`WorldState` builder was byte-equivalent to
/// `minimalGame` with empty regions on an orders-phase turn 1, so the only
/// per-fixture customisation kept here is the diplomacy-expertise GP plus the
/// minor nation / tribe rosters these phase tests exercise.
Game diplomacyResolverPhaseTestBaseGame() {
  return TestFixtures.minimalGame(
    id: 'g1',
    players: [
      const Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 2000)
          .copyWith(techUnlocked: const {kTechIdDiplomaticExpertise: true}),
    ],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Minor 1'),
    ],
    tribes: const [
      Tribe(id: 'tribe1', displayName: 'Tribe 1'),
    ],
  );
}
