// Unit tests for `treasuryAvailableForBidsByPlayer` plus a SPEC
// composition group that reconstructs the UI treasury-bid-cap formula
// end-to-end (Refs #3093).
//
// SPEC/game/world-market.md § Treasury budget for bids,
// SPEC/ui/trade-screen.md § Market tab — treasury bid cap.

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'world_market_treasury_bid_budget_test_support.dart';

void main() {
  final data.ResourceRules rules = data.ResourceRules.defaultRules;

  group('treasuryAvailableForBidsByPlayer (Refs #3093)', () {
    test('returns the player\'s raw treasury for known players', () {
      final game = buildTreasuryBidBudgetGame(treasury: 250);
      expect(
        treasuryAvailableForBidsByPlayer(game: game, playerId: humanPlayerId),
        250,
      );
    });

    test('clamps negative treasury to 0 (defensive guard)', () {
      final game = buildTreasuryBidBudgetGame(treasury: -10);
      expect(
        treasuryAvailableForBidsByPlayer(game: game, playerId: humanPlayerId),
        0,
      );
    });

    test('returns 0 when playerId does not resolve to a player', () {
      final game = buildTreasuryBidBudgetGame(treasury: 100);
      expect(
        treasuryAvailableForBidsByPlayer(game: game, playerId: 'gp_ghost'),
        0,
      );
    });

    test('default projectedNonBidTreasuryDelta == 0 preserves the legacy '
        '"raw treasury" contract for callers without a projection', () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      // Equivalent to the previous group's "raw treasury" case — included
      // here to document that the new parameter defaults to zero so legacy
      // callers (AI suggestion, Widgetbook stories, isolated widget tests
      // without `treasurySummaryProvider` map data) keep working.
      expect(
        treasuryAvailableForBidsByPlayer(game: game, playerId: humanPlayerId),
        treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: humanPlayerId,
          projectedNonBidTreasuryDelta: 0,
        ),
      );
      expect(
        treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: humanPlayerId,
          projectedNonBidTreasuryDelta: 0,
        ),
        175,
      );
    });

    test('projectedNonBidTreasuryDelta < 0 subtracts the absolute deficit '
        'from raw treasury (positive AC #1)', () {
      final game = buildTreasuryBidBudgetGame(treasury: 100);
      expect(
        treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: humanPlayerId,
          // Player has 40 treasury of non-bid pending costs this turn
          // (build / recruit / civilian / subsidy commitments).
          projectedNonBidTreasuryDelta: -40,
        ),
        60,
      );
    });

    test('projectedNonBidTreasuryDelta > 0 leaves the budget at raw treasury '
        '(conservative — net non-bid income never raises the budget)', () {
      final game = buildTreasuryBidBudgetGame(treasury: 100);
      expect(
        treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: humanPlayerId,
          // Player has 50 treasury of net non-bid income projected (e.g.
          // extraction sales). The clamp ignores income — the budget stays
          // at raw treasury so the player cannot commit treasury they
          // only project to earn.
          projectedNonBidTreasuryDelta: 50,
        ),
        100,
        reason:
            'Net non-bid income must not raise the bid budget per SPEC § '
            'Treasury budget for bids (conservative clamp).',
      );
    });

    test(
      'projected deficit equal to treasury clamps the budget at exactly 0',
      () {
        final game = buildTreasuryBidBudgetGame(treasury: 80);
        expect(
          treasuryAvailableForBidsByPlayer(
            game: game,
            playerId: humanPlayerId,
            projectedNonBidTreasuryDelta: -80,
          ),
          0,
        );
      },
    );

    test(
      'projected deficit larger than treasury still clamps at 0 (not negative)',
      () {
        final game = buildTreasuryBidBudgetGame(treasury: 50);
        expect(
          treasuryAvailableForBidsByPlayer(
            game: game,
            playerId: humanPlayerId,
            projectedNonBidTreasuryDelta: -120,
          ),
          0,
        );
      },
    );

    test(
      'projectedNonBidTreasuryDelta is ignored when treasury is already 0',
      () {
        final game = buildTreasuryBidBudgetGame(treasury: 0);
        expect(
          treasuryAvailableForBidsByPlayer(
            game: game,
            playerId: humanPlayerId,
            projectedNonBidTreasuryDelta: 25,
          ),
          0,
        );
        expect(
          treasuryAvailableForBidsByPlayer(
            game: game,
            playerId: humanPlayerId,
            projectedNonBidTreasuryDelta: -25,
          ),
          0,
        );
      },
    );

    test('unknown playerId returns 0 even when a non-zero '
        'projectedNonBidTreasuryDelta is supplied', () {
      final game = buildTreasuryBidBudgetGame(treasury: 100);
      expect(
        treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: 'gp_ghost',
          projectedNonBidTreasuryDelta: -30,
        ),
        0,
      );
    });
  });

  group('composition: UI clamp budget math (Refs #3093)', () {
    test('treasury 100, market price timber 30, no staged bids → headroom for '
        'fresh row equals raw treasury (allows up to qty 3)', () {
      final game = buildTreasuryBidBudgetGame(
        treasury: 100,
        prices: const {'timber': 30},
      );
      final int budget = treasuryAvailableForBidsByPlayer(
        game: game,
        playerId: humanPlayerId,
      );
      final int currentSpend = stagedBidTotalSpendByPlayer(
        orders: const Orders(),
        playerId: humanPlayerId,
        game: game,
        resourceRules: rules,
      );
      final int? rowPrice = effectiveMarketPriceForCommodityId(
        commodityId: 'timber',
        worldMarket: game.worldMarketState,
        resourceRules: rules,
      );
      expect(rowPrice, 30);
      final int headroom = budget - currentSpend;
      expect(headroom ~/ rowPrice!, 3);
    });

    test('treasury 100, staged Bid timber qty 3 (spend 90) → adding a fresh bid '
        'for iron (price 80) is refused (headroom 10 < 80)', () {
      final game = buildTreasuryBidBudgetGame(
        treasury: 100,
        prices: const {'timber': 30, 'iron': 80},
      );
      final orders = humanOrdersWith([bidOrder('timber', 3)]);
      final int budget = treasuryAvailableForBidsByPlayer(
        game: game,
        playerId: humanPlayerId,
      );
      final int currentSpend = stagedBidTotalSpendByPlayer(
        orders: orders,
        playerId: humanPlayerId,
        game: game,
        resourceRules: rules,
      );
      final int? ironPrice = effectiveMarketPriceForCommodityId(
        commodityId: 'iron',
        worldMarket: game.worldMarketState,
        resourceRules: rules,
      );
      expect(ironPrice, 80);
      final int headroom = budget - currentSpend;
      expect(headroom, 10);
      expect(
        headroom < ironPrice!,
        isTrue,
        reason:
            'Cannot fit even 1 unit of iron at price 80 with only 10 treasury '
            'headroom — the UI must silent-no-op the toggle.',
      );
    });

    test(
      'treasury 100, staged Bid timber qty 3 (spend 90), incrementing timber → '
      'next increment would make spend 120 (> 100), so the UI must silent-no-op',
      () {
        final game = buildTreasuryBidBudgetGame(
          treasury: 100,
          prices: const {'timber': 30},
        );
        final orders = humanOrdersWith([bidOrder('timber', 3)]);
        final int budget = treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: humanPlayerId,
        );
        final int currentSpend = stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: humanPlayerId,
          game: game,
          resourceRules: rules,
        );
        final int delta = 1;
        final int? rowPrice = effectiveMarketPriceForCommodityId(
          commodityId: 'timber',
          worldMarket: game.worldMarketState,
          resourceRules: rules,
        );
        expect(rowPrice, 30);
        expect(currentSpend + delta * rowPrice! > budget, isTrue);
      },
    );

    test('treasury 100, projectedDelta=-40 (UI reconstructs non-bid delta with '
        'no staged bids), market price timber 30 → budget = 60, default qty '
        '1 fits and headroom permits up to qty 2 (spend 60)', () {
      final game = buildTreasuryBidBudgetGame(
        treasury: 100,
        prices: const {'timber': 30},
      );
      // UI maps: projectedDelta from treasurySummaryProvider, no staged bids
      // yet. projectedNonBidDelta = projectedDelta + stagedBidSpend = -40.
      final int budget = treasuryAvailableForBidsByPlayer(
        game: game,
        playerId: humanPlayerId,
        projectedNonBidTreasuryDelta: -40,
      );
      final int currentSpend = stagedBidTotalSpendByPlayer(
        orders: const Orders(),
        playerId: humanPlayerId,
        game: game,
        resourceRules: rules,
      );
      final int headroom = budget - currentSpend;
      final int? rowPrice = effectiveMarketPriceForCommodityId(
        commodityId: 'timber',
        worldMarket: game.worldMarketState,
        resourceRules: rules,
      );
      expect(budget, 60);
      expect(rowPrice, 30);
      expect(headroom ~/ rowPrice!, 2);
    });

    test('treasury 50, projectedNonBidTreasuryDelta=-60 → budget clamps to 0 '
        'so no bid (even default qty 1) can be staged on any priced '
        'commodity (silent no-op gate)', () {
      final game = buildTreasuryBidBudgetGame(
        treasury: 50,
        prices: const {'timber': 30},
      );
      final int budget = treasuryAvailableForBidsByPlayer(
        game: game,
        playerId: humanPlayerId,
        projectedNonBidTreasuryDelta: -60,
      );
      final int? rowPrice = effectiveMarketPriceForCommodityId(
        commodityId: 'timber',
        worldMarket: game.worldMarketState,
        resourceRules: rules,
      );
      expect(budget, 0);
      expect(rowPrice, 30);
      // The UI silent-no-ops the toggle because budget − otherBidSpend (0) is
      // less than rowPrice. The composition mirrors the row-toggle gate
      // implemented in `trade_screen.dart` for the bid clamp.
      expect(budget < rowPrice!, isTrue);
    });
  });
}
