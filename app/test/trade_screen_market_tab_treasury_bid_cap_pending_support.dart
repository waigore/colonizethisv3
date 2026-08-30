// Pending-cost treasury bid-cap scenarios extracted for headroom (Refs #4582).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_market_tab_treasury_bid_cap_support.dart';
import 'trade_screen_test_support.dart';

void registerTreasuryBidCapPendingTests() {
  testWidgets(
    'treasury 100, timber price 30, non-bid pending cost = 40 → tapping '
    'Bid stages qty 1 (budget 60 fits default), incrementing to qty 2 '
    'succeeds (spend 60), next + tap is a silent no-op (spend 90 > '
    'budget 60)',
    (tester) async {
      // Refs #3093 — pending-cost projection wiring. The override
      // mirrors production `treasurySummaryProvider`: it re-derives
      // `projectedDelta` from current orders so the value tracks bid
      // staging like the real app would. The fixture pins the non-bid
      // contribution at -40 (e.g. 40 treasury of build/recruit/civilian
      // commitments).
      final Game game = buildTradeTestGame(
        treasury: 100,
        prices: const {kTreasuryBidTimber: 30},
      );
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: game,
        extraOverrides: <Override>[treasuryBidSummaryOverride(game, -40)],
      );

      await tapTreasuryMarketBid(tester, kTreasuryBidTimber);

      TradeOrder? staged = stagedTreasuryBidOrder(
        container,
        kTreasuryBidTimber,
      );
      expect(staged?.type, TradeOrderType.bid);
      expect(
        staged?.quantity,
        1,
        reason: 'Budget 60 / price 30 = 2 headroom; default qty 1 fits.',
      );

      await tapTreasuryMarketIncrement(tester, kTreasuryBidTimber);
      staged = stagedTreasuryBidOrder(container, kTreasuryBidTimber);
      expect(
        staged?.quantity,
        2,
        reason: 'Spend grows to 60; still inside the 60 budget.',
      );

      await tapTreasuryMarketIncrement(tester, kTreasuryBidTimber);
      staged = stagedTreasuryBidOrder(container, kTreasuryBidTimber);
      expect(
        staged?.quantity,
        2,
        reason:
            'Refs #3093 — qty 3 would cost 90, exceeding the 60 budget; '
            'the + tap must silent-no-op.',
      );
    },
  );

  testWidgets(
    'treasury 50, timber price 30, non-bid pending cost = 60 → bid budget '
    'clamps to 0; tapping Bid on timber is a silent no-op (no TradeOrder '
    'staged)',
    (tester) async {
      // Refs #3093 — projected pending deficit exceeds raw treasury so the
      // helper clamps the bid budget at 0. Even default qty 1 cannot land.
      final Game game = buildTradeTestGame(
        treasury: 50,
        prices: const {kTreasuryBidTimber: 30},
      );
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: game,
        extraOverrides: <Override>[treasuryBidSummaryOverride(game, -60)],
      );

      await tapTreasuryMarketBid(tester, kTreasuryBidTimber);

      expect(
        stagedTreasuryBidOrder(container, kTreasuryBidTimber),
        isNull,
        reason:
            'Refs #3093 — pending non-bid deficit (60) exceeds raw treasury '
            '(50), so the bid budget is 0 and even default-qty 1 cannot '
            'land. The toggle must be a silent no-op.',
      );
    },
  );

  testWidgets('treasury 100, iron price 80, non-bid projected delta = +25 (net '
      'non-bid income) → bid budget stays at raw treasury 100 (income '
      'does not raise the budget); tapping Bid stages qty 1 normally', (
    tester,
  ) async {
    // Refs #3093 — net non-bid income never raises the bid budget
    // (conservative clamp per SPEC § Treasury budget for bids).
    final Game game = buildTradeTestGame(
      treasury: 100,
      prices: const {kTreasuryBidIron: 80},
    );
    final ProviderContainer container = await pumpTradeScreenWithContainer(
      tester,
      game: game,
      extraOverrides: <Override>[treasuryBidSummaryOverride(game, 25)],
    );

    await tapTreasuryMarketBid(tester, kTreasuryBidIron);

    final TradeOrder? staged = stagedTreasuryBidOrder(
      container,
      kTreasuryBidIron,
    );
    expect(staged?.type, TradeOrderType.bid);
    expect(
      staged?.quantity,
      1,
      reason:
          'Net non-bid income (+25) is ignored by the bid clamp; '
          'budget stays at raw treasury 100 so the default qty 1 (spend '
          '80) lands.',
    );
  });

  testWidgets(
    'treasury 100, timber price 30, staged Bid timber qty 2 (spend 60), '
    'non-bid projected delta = +10 (net non-bid income) → incrementing '
    'timber lands (budget stays at raw treasury 100, spend grows to 90)',
    (tester) async {
      // Refs #3093 — exercises the UI-side delta reconstruction with a
      // dynamic treasury summary. The non-bid delta is +10 (income), so
      // the helper clamps the deficit to 0 and leaves the budget at raw
      // treasury 100. Spend 60 + 30 = 90 ≤ 100, so the increment lands.
      final Game game = buildTradeTestGame(
        treasury: 100,
        prices: const {kTreasuryBidTimber: 30},
      );
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: game,
        initialOrders: stagedTreasuryTradeOrders(
          commodityId: kTreasuryBidTimber,
          type: TradeOrderType.bid,
          quantity: 2,
        ),
        extraOverrides: <Override>[treasuryBidSummaryOverride(game, 10)],
      );

      await tapTreasuryMarketIncrement(tester, kTreasuryBidTimber);
      expect(
        stagedTreasuryBidOrder(container, kTreasuryBidTimber)?.quantity,
        3,
        reason:
            'Reconstructed non-bid delta is +10 (net income); budget '
            'stays at raw treasury 100, allowing the increment to qty 3 '
            '(spend 90).',
      );
    },
  );

  testWidgets(
    'treasury 100, non-bid pending cost = 40, staged Bid timber qty 1 '
    '(spend 30) → tapping Bid on iron (price 80) is refused (budget 60, '
    'headroom 30 < iron price 80)',
    (tester) async {
      // Refs #3093 — cross-commodity bid gate under pending non-bid costs.
      // Bid budget = 100 − 40 = 60; existing timber spend = 30; iron toggle
      // would need 80 of remaining 30 headroom.
      final Game game = buildTradeTestGame(
        treasury: 100,
        prices: const {kTreasuryBidTimber: 30, kTreasuryBidIron: 80},
      );
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: game,
        initialOrders: stagedTreasuryTradeOrders(
          commodityId: kTreasuryBidTimber,
          type: TradeOrderType.bid,
          quantity: 1,
        ),
        extraOverrides: <Override>[treasuryBidSummaryOverride(game, -40)],
      );

      await tapTreasuryMarketBid(tester, kTreasuryBidIron);

      expect(
        stagedTreasuryBidOrder(container, kTreasuryBidIron),
        isNull,
        reason:
            'Bid budget 60 − existing timber spend 30 leaves 30 headroom; '
            'iron price 80 > 30 → toggle is silent no-op.',
      );
      expect(
        stagedTreasuryBidOrder(container, kTreasuryBidTimber)?.quantity,
        1,
      );
    },
  );
}
