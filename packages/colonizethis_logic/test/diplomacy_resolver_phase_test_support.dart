import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared fixture for [diplomacy_resolver_phase_test_part*_test.dart].
Game diplomacyResolverPhaseTestBaseGame() {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
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
