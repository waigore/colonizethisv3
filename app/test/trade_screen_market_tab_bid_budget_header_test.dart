// Widget tests for the Trade Market tab treasury bid-budget header (Refs
// #4186).
//
// SPEC/ui/trade-screen.md § Market tab — treasury bid budget indicator.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

const String _humanPlayerId = kTradeTestHumanPlayerId;

const CommodityId _timber = 'timber';
const CommodityId _iron = 'iron';

String _bidBudgetIndicatorText(WidgetTester tester) {
  return tester.widget<Text>(
    find.byKey(TradeScreenMarketKeys.marketBidBudgetIndicatorKey),
  ).data!;
}

Override _treasurySummaryOverride(Game game, int nonBidProjectedDelta) {
  final Player player = game.players.first;
  return treasurySummaryProvider.overrideWith((ref) {
    final Orders orders = ref.watch(currentOrdersProvider);
    final int bidSpend = stagedBidTotalSpendByPlayer(
      orders: orders,
      playerId: _humanPlayerId,
      game: game,
      resourceRules: ResourceRules.defaultRules,
    );
    return TreasurySummary(
      treasury: player.treasury,
      projectedDelta: nonBidProjectedDelta - bidSpend,
    );
  });
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab bid-budget header (Refs #4186)', () {
    testWidgets(
      'treasury 100, no staged bids → indicator reads Bid budget: 100 of 100',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(treasury: 100, prices: const {_timber: 30}),
        );

        expect(_bidBudgetIndicatorText(tester), 'Bid budget: 100 of 100');
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetWarningKey),
          findsNothing,
        );
      },
    );

    testWidgets(
      'treasury 100, staged Bid timber qty 3 (spend 90) → indicator reads '
      'Bid budget: 10 of 100',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(treasury: 100, prices: const {_timber: 30}),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 3,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        expect(_bidBudgetIndicatorText(tester), 'Bid budget: 10 of 100');
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetWarningKey),
          findsNothing,
        );
      },
    );

    testWidgets(
      'treasury 90, staged Bid timber qty 3 (spend 90) → R == 0 shows warning',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(treasury: 90, prices: const {_timber: 30}),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 3,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        expect(_bidBudgetIndicatorText(tester), 'Bid budget: 0 of 90');
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetWarningKey),
          findsOneWidget,
        );
        expect(
          find.text(TradeScreenMarketKeys.bidBudgetLimitWarningText),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'treasury 50, non-bid pending cost 60 → budget 0 with no bids shows '
      'warning (B == 0, S == 0)',
      (tester) async {
        final Game game = buildTradeTestGame(
          treasury: 50,
          prices: const {_timber: 30},
        );
        await pumpTradeScreenWithContainer(
          tester,
          game: game,
          extraOverrides: <Override>[_treasurySummaryOverride(game, -60)],
        );

        expect(_bidBudgetIndicatorText(tester), 'Bid budget: 0 of 0');
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetWarningKey),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'treasury 100, non-bid pending cost 40 → header budget reads 60 of 60 '
      'with no staged bids',
      (tester) async {
        final Game game = buildTradeTestGame(
          treasury: 100,
          prices: const {_timber: 30},
        );
        await pumpTradeScreenWithContainer(
          tester,
          game: game,
          extraOverrides: <Override>[_treasurySummaryOverride(game, -40)],
        );

        expect(_bidBudgetIndicatorText(tester), 'Bid budget: 60 of 60');
      },
    );

    testWidgets(
      'staged Offer timber qty 4 only → bid spend 0 and remaining equals full '
      'budget',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            treasury: 50,
            prices: const {_timber: 30},
            stockpile: const {_timber: 10},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.offer,
                  quantity: 4,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        expect(_bidBudgetIndicatorText(tester), 'Bid budget: 50 of 50');
      },
    );

    testWidgets(
      'incrementing staged bid updates the bid-budget line live',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(treasury: 100, prices: const {_timber: 30}),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 1,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        expect(_bidBudgetIndicatorText(tester), 'Bid budget: 70 of 100');

        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(_timber)),
        );
        await tester.pump();

        expect(_bidBudgetIndicatorText(tester), 'Bid budget: 40 of 100');
      },
    );

    testWidgets(
      'Why this limit? expands treasury bid-budget copy',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(treasury: 100, prices: const {_timber: 30}),
        );

        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetWhyBodyKey),
          findsNothing,
        );

        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetWhyToggleKey),
        );
        await tester.pump();

        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetWhyBodyKey),
          findsOneWidget,
        );
        expect(
          find.text(TradeScreenMarketKeys.bidBudgetWhyLimitCopy),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'observe mode → bid-budget indicator remains live',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(treasury: 100, prices: const {_timber: 30}),
          canMutateViaUi: false,
        );

        expect(_bidBudgetIndicatorText(tester), 'Bid budget: 100 of 100');

        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_timber)),
        );
        await tester.pump();

        expect(_bidBudgetIndicatorText(tester), 'Bid budget: 100 of 100');
      },
    );

    testWidgets(
      'treasury-saturated increment remains silent no-op (clamp unchanged)',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(treasury: 100, prices: const {_timber: 30}),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 3,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(_timber)),
        );
        await tester.pump();

        final Orders orders = container.read(currentOrdersProvider);
        final List<TradeOrder>? list =
            orders.tradeOrdersByPlayerId[_humanPlayerId];
        TradeOrder? staged;
        if (list != null) {
          for (final TradeOrder o in list) {
            if (o.commodityId == _timber) {
              staged = o;
              break;
            }
          }
        }
        expect(staged?.quantity, 3);
        expect(_bidBudgetIndicatorText(tester), 'Bid budget: 10 of 100');
      },
    );

    testWidgets(
      'fresh iron bid refused when headroom below row price leaves indicator '
      'unchanged',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            treasury: 100,
            prices: const {_timber: 30, _iron: 80},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 3,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        expect(_bidBudgetIndicatorText(tester), 'Bid budget: 10 of 100');

        await tester.tap(find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_iron)));
        await tester.pump();

        expect(_bidBudgetIndicatorText(tester), 'Bid budget: 10 of 100');
      },
    );
  });
}
