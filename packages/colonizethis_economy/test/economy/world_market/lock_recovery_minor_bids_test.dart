import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('computeLockRecoveryMinorAutoBids', () {
    test('returns empty when no GP is broke', () {
      final game = _gameWithTreasury(const {'gp1': 5000, 'gp2': 5000});
      final bids = computeLockRecoveryMinorAutoBids(
        game: game,
        worldMarketState: _marketWithGrainActivity(),
      );
      expect(bids, isEmpty);
    });

    test('returns empty when no minors exist', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 0, phase: TurnPhase.orders),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: [
          Player(id: 'gp1', displayName: 'GP1', isHuman: false, treasury: 100),
        ],
      );
      final bids = computeLockRecoveryMinorAutoBids(
        game: game,
        worldMarketState: _marketWithGrainActivity(),
      );
      expect(bids, isEmpty);
    });

    test('emits urgent grain bid per minor when a GP is broke', () {
      final game = _gameWithTreasury(const {'gp1': 100, 'gp2': 5000});
      final bids = computeLockRecoveryMinorAutoBids(
        game: game,
        worldMarketState: _marketWithGrainActivity(),
      );
      expect(bids.keys, containsAll(['minor1', 'minor2']));
      for (final orders in bids.values) {
        expect(orders, hasLength(1));
        expect(orders.first.type, TradeOrderType.bid);
        expect(orders.first.commodityId, 'grain');
        expect(orders.first.priority, kLockRecoveryMinorBidPriority);
        expect(orders.first.quantity, kLockRecoveryMinorBidQuantityPerMinor);
      }
    });
  });
}

WorldMarketState _marketWithGrainActivity() {
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

Game _gameWithTreasury(Map<String, int> treasuryByGp) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 0, phase: TurnPhase.orders),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      for (final entry in treasuryByGp.entries)
        Player(
          id: entry.key,
          displayName: entry.key,
          isHuman: false,
          treasury: entry.value,
        ),
    ],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'M1'),
      MinorNation(id: 'minor2', displayName: 'M2'),
    ],
  );
}
