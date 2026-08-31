// Bid-budget header pump helpers for Trade Market tab tests (Refs #4186, #4305).

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

const String kTradeBidBudgetHumanPlayerId = kTradeTestHumanPlayerId;
const CommodityId kTradeBidBudgetTimber = 'timber';
const CommodityId kTradeBidBudgetIron = 'iron';

String tradeBidBudgetIndicatorText(WidgetTester tester) {
  return tester.widget<Text>(
    find.byKey(TradeScreenMarketKeys.marketBidBudgetIndicatorKey),
  ).data!;
}

Override tradeBidBudgetTreasurySummaryOverride(
  Game game,
  int nonBidProjectedDelta,
) {
  final Player player = game.players.first;
  return treasurySummaryProvider.overrideWith((ref) {
    final Orders orders = ref.watch(currentOrdersProvider);
    final int bidSpend = stagedBidTotalSpendByPlayer(
      orders: orders,
      playerId: kTradeBidBudgetHumanPlayerId,
      game: game,
      resourceRules: ResourceRules.defaultRules,
    );
    return TreasurySummary(
      treasury: player.treasury,
      projectedDelta: nonBidProjectedDelta - bidSpend,
    );
  });
}
