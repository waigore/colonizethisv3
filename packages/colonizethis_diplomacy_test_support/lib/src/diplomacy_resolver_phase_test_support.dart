import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_game_fixtures.dart';

/// Shared fixture for [diplomacy_resolver_phase_test_part*_test.dart] (Refs #4028).
Game diplomacyResolverPhaseTestBaseGame() => diplomacyGame(
      id: 'g1',
      players: [
        const Player(
          id: 'gp1',
          displayName: 'GP1',
          isHuman: true,
          treasury: 2000,
        ).copyWith(techUnlocked: const {kTechIdDiplomaticExpertise: true}),
      ],
      minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
      tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
    );
