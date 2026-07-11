// Shared diplomacy-filter suggestion fixtures (Refs #3949 wave 3, #3971 wave 4).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import '../common/game_graphs.dart';

/// Dual-region game with two GPs and one unowned old-world province.
Game orderSuggestionDiplomacyFilterDualRegionGame() =>
    ordersDualRegionOwnerMapGame();

/// Old-world game with empty-string owner on one province.
Game orderSuggestionDiplomacyFilterEmptyStringOwnerGame() {
  const ow = 'oldWorld';
  return TestFixtures.minimalGame(
    players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
    oldWorld: RegionData(
      provinces: const [
        Province(id: 'oldWorld|p1', regionId: ow, ownerId: 'gp1'),
        Province(id: 'oldWorld|p2', regionId: ow, ownerId: ''),
      ],
      units: const [],
    ),
  );
}

/// Two-GP old-world game with unprefixed local province ids.
Game orderSuggestionDiplomacyFilterOldWorldTwoGpGame() =>
    ordersTwoProvinceOwnedGame(
      prefixedIds: false,
      players: ordersCommonTwoGpAb,
    );

/// Two-GP new-world game with prefixed province ids.
Game orderSuggestionDiplomacyFilterNewWorldTwoGpGame() =>
    ordersTwoProvinceOwnedGame(
      regionId: 'newWorld',
      p1Local: 'n1',
      p2Local: 'n2',
      inNewWorld: true,
      players: ordersCommonTwoGpAb,
    );

/// Two-GP old-world game at peace for diplomacy filter probes.
Game orderSuggestionDiplomacyFilterPeacefulTwoGpGame() =>
    ordersTwoProvinceOwnedGame(
      prefixedIds: false,
      players: ordersCommonTwoGpAb,
      includeDefaultDiplomacy: true,
      state: RelationState.atPeace,
      score: 50,
    );

/// Two-GP old-world game at war for diplomacy filter probes.
Game orderSuggestionDiplomacyFilterAtWarTwoGpGame() =>
    ordersTwoProvinceOwnedGame(
      prefixedIds: false,
      players: ordersCommonTwoGpAb,
      includeDefaultDiplomacy: true,
      state: RelationState.atWar,
      score: 0,
    );
