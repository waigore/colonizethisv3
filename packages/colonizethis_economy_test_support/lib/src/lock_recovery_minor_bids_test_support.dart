/// Shared fixtures for `computeLockRecoveryMinorAutoBids` unit tests (Refs #3856).
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// World market with grain activity sufficient for lock-recovery minor bids.
WorldMarketState lockRecoveryGrainMarket() {
  return WorldMarketState(
    prices: const {'grain': 10},
    lastTurnActivity: {
      'grain': const MarketActivity(
        totalBidQuantity: 1,
        totalOfferQuantity: 100,
      ),
      'meat': const MarketActivity(totalBidQuantity: 1, totalOfferQuantity: 50),
    },
  );
}

/// Minimal game with GPs whose treasuries are keyed by [treasuryByGpId].
///
/// When [minorNations] is omitted, two default minors (`minor1`, `minor2`)
/// are included.
Game lockRecoveryGameWithTreasury(
  Map<String, int> treasuryByGpId, {
  List<MinorNation>? minorNations,
}) {
  return TestFixtures.minimalGame(
    players: [
      for (final entry in treasuryByGpId.entries)
        Player(
          id: entry.key,
          displayName: entry.key,
          isHuman: false,
          treasury: entry.value,
        ),
    ],
    minorNations:
        minorNations ??
        const [
          MinorNation(id: 'minor1', displayName: 'M1'),
          MinorNation(id: 'minor2', displayName: 'M2'),
        ],
  );
}

/// Game with GPs but no minor nations (lock-recovery no-op path).
Game lockRecoveryGameWithoutMinors({required int gpTreasury}) {
  return TestFixtures.minimalGame(
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        treasury: gpTreasury,
      ),
    ],
    minorNations: const [],
  );
}
