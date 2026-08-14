// Treasury bid-cap helpers for Trade Market tab tests (Refs #4352).

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

const String kTreasuryBidHumanPlayerId = kTradeTestHumanPlayerId;
const CommodityId kTreasuryBidTimber = 'timber';
const CommodityId kTreasuryBidIron = 'iron';
const CommodityId kTreasuryBidLumber = 'lumber';

Override treasuryBidSummaryOverride(Game game, int nonBidProjectedDelta) {
  final Player player = game.players.first;
  return treasurySummaryProvider.overrideWith((ref) {
    final Orders orders = ref.watch(currentOrdersProvider);
    final int bidSpend = stagedBidTotalSpendByPlayer(
      orders: orders,
      playerId: kTreasuryBidHumanPlayerId,
      game: game,
      resourceRules: ResourceRules.defaultRules,
    );
    return TreasurySummary(
      treasury: player.treasury,
      projectedDelta: nonBidProjectedDelta - bidSpend,
    );
  });
}

TradeOrder? stagedTreasuryBidOrder(
  ProviderContainer container,
  CommodityId commodityId,
) {
  final Orders orders = container.read(currentOrdersProvider);
  final List<TradeOrder>? list =
      orders.tradeOrdersByPlayerId[kTreasuryBidHumanPlayerId];
  if (list == null) return null;
  for (final TradeOrder o in list) {
    if (o.commodityId == commodityId) return o;
  }
  return null;
}

Orders stagedTreasuryTradeOrders({
  required CommodityId commodityId,
  required TradeOrderType type,
  required int quantity,
}) {
  return Orders(
    tradeOrdersByPlayerId: {
      kTreasuryBidHumanPlayerId: [
        TradeOrder(
          commodityId: commodityId,
          type: type,
          quantity: quantity,
          priority: 1,
        ),
      ],
    },
  );
}

Future<void> tapTreasuryMarketBid(
  WidgetTester tester,
  CommodityId commodityId,
) async {
  await tester.tap(
    find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(commodityId)),
  );
  await tester.pump();
}

Future<void> tapTreasuryMarketIncrement(
  WidgetTester tester,
  CommodityId commodityId,
) async {
  await tester.tap(
    find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(commodityId)),
  );
  await tester.pump();
}

Future<void> tapTreasuryMarketDecrement(
  WidgetTester tester,
  CommodityId commodityId,
) async {
  await tester.tap(
    find.byKey(TradeScreenMarketKeys.marketRowDecrementKey(commodityId)),
  );
  await tester.pump();
}
