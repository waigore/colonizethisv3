import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/world_market_test_support.dart';

/// Treasury-conservation coverage for the World Market phase (Refs #2924).
///
/// SPEC anchor: `SPEC/program/world-market-resolution.md`
/// § Treasury conservation invariant (Refs #2924) and § Step D / Treasury sink.
///
/// These tests pin the mechanical reason the treasury-planner lock-recovery
/// path (Refs #2924 F10–F14) cannot, by itself, lift a pool of broke Great
/// Powers above `cheapestRegimentBuildTreasuryCost()`: phase 13 only ever
/// redistributes the Great-Power treasury pool (GP↔GP fills) or leaks it to
/// the treasury sink (minor/tribe fills). It never creates net Great-Power
/// treasury, so the sum of all Great-Power treasuries is non-increasing across
/// the phase.
void main() {
  group('worldMarketTurnPhaseHandler — treasury conservation (Refs #2924)', () {
    test(
      'GP↔GP-only matching exactly conserves the total Great-Power treasury '
      'pool (every buyer debit is an equal GP-seller credit)',
      () {
        const prices = {'timber': 30, 'iron': 80};
        final players = <Player>[
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: false,
            stockpile: const Stockpile().applyDelta('timber', 10),
            treasury: 500,
          ),
          Player(
            id: 'gp2',
            displayName: 'GP2',
            isHuman: false,
            stockpile: const Stockpile().applyDelta('iron', 10),
            treasury: 500,
          ),
          Player(
            id: 'gp3',
            displayName: 'GP3',
            isHuman: false,
            stockpile: Stockpile.empty,
            treasury: 500,
          ),
        ];
        final before = _totalGpTreasury(players);

        final next = _runGpPhase(
          players: players,
          marketPrices: prices,
          orders: Orders(
            tradeOrdersByPlayerId: {
              'gp1': [
                _offer('timber', 5),
                _bid('iron', 2),
              ],
              'gp2': [
                _offer('iron', 5),
                _bid('timber', 5),
              ],
              'gp3': [
                _bid('timber', 1),
              ],
            },
          ),
        );

        final after = _totalGpTreasury(next.players);
        expect(after, equals(before),
            reason: 'GP↔GP trade only redistributes the pool — total unchanged');

        // Sanity: at least one deal actually filled, so the conservation
        // assertion is exercised against real transfers rather than a no-op.
        final gp2 = next.players.firstWhere((p) => p.id == 'gp2');
        expect(gp2.stockpile.quantityOf('timber'), greaterThan(0),
            reason: 'gp2 bought timber from gp1 (a real GP↔GP transfer)');
      },
    );

    test(
      'GP purchase from a minor/tribe auto-offer leaks treasury to the sink: '
      'the Great-Power pool strictly decreases by the uncredited deal value',
      () {
        final game = minorTimberAutoOfferPipelineGame(
          buyerTreasury: 1000,
          timberPrice: 30,
        );
        final before = _totalGpTreasury(game.players);

        final next = runWorldMarketPhase(
          game: game,
          orders: Orders(
            tradeOrdersByPlayerId: {
              'gpBuyer': [_bid('timber', 1)],
            },
          ),
          tileMapByRegion: {'oldWorld': minorTimberTileMapByRegion()['oldWorld']!},
        );

        final after = _totalGpTreasury(next.players);
        // One unit filled at price 30, credited to no faction (sink).
        expect(after, equals(before - 30),
            reason: 'minor sale value leaks out of the GP pool to the sink');
        expect(after, lessThan(before),
            reason: 'GP pool strictly decreases on minor/tribe purchases');
      },
    );

    test(
      'mixed GP↔GP and GP↔minor matching never increases the Great-Power pool '
      '(non-increasing invariant) and is deterministic across runs',
      () {
        Game freshGame() => mixedGpMinorTreasuryConservationGame();

        final orders = Orders(
          tradeOrdersByPlayerId: {
            'gpSeller': [_offer('timber', 5)],
            'gpBuyer': [_bid('timber', 8)],
          },
        );
        final tileMapByRegion = minorTimberTileMapByRegion();

        final beforeTotal = _totalGpTreasury(freshGame().players);

        final runA = runWorldMarketPhase(
          game: freshGame(),
          orders: orders,
          tileMapByRegion: tileMapByRegion,
        );
        final runB = runWorldMarketPhase(
          game: freshGame(),
          orders: orders,
          tileMapByRegion: tileMapByRegion,
        );

        expect(_totalGpTreasury(runA.players), lessThanOrEqualTo(beforeTotal),
            reason: 'the market never increases the Great-Power treasury pool');

        expect(_treasuryByGp(runA.players), equals(_treasuryByGp(runB.players)),
            reason: 'phase-13 treasury outcomes are deterministic');
      },
    );
  });
}

int _totalGpTreasury(List<Player> players) =>
    players.fold(0, (sum, p) => sum + p.treasury);

Map<String, int> _treasuryByGp(List<Player> players) => {
      for (final p in players) p.id: p.treasury,
    };

TradeOrder _offer(CommodityId id, int quantity) => TradeOrder(
      commodityId: id,
      type: TradeOrderType.offer,
      quantity: quantity,
      priority: 1,
    );

TradeOrder _bid(CommodityId id, int quantity) => TradeOrder(
      commodityId: id,
      type: TradeOrderType.bid,
      quantity: quantity,
      priority: 1,
    );

Game _runGpPhase({
  required List<Player> players,
  required Map<CommodityId, int> marketPrices,
  required Orders orders,
}) {
  return runWorldMarketPhase(
    game: worldMarketGpPoolGame(
      players: players,
      marketPrices: marketPrices,
    ),
    orders: orders,
  );
}
