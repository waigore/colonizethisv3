// Deal Book tab ledger fixtures (Refs #4352).

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

const List<Player> dealBookTestPlayers = <Player>[
  // ignore: avoid_hardcoded_strings_in_widgets
  Player(
    id: kTradeTestHumanPlayerId,
    displayName: 'England',
    isHuman: true,
    treasury: 500,
  ),
  // ignore: avoid_hardcoded_strings_in_widgets
  Player(id: 'gp_a', displayName: 'Aragon', isHuman: false, treasury: 500),
];

FilledDeal dealBookFilledDeal({
  required String seller,
  required String buyer,
  required String commodity,
  required int qty,
  required double price,
  bool frr = false,
  bool ftp = false,
  String? sellerOriginTileKey,
}) {
  return FilledDeal(
    sellerFactionId: seller,
    buyerFactionId: buyer,
    commodityId: commodity,
    quantity: qty,
    pricePerUnit: price,
    isFirstRightOfRefusalMatch: frr,
    isFtpMatch: ftp,
    sellerOriginTileKey: sellerOriginTileKey,
  );
}

MarketActivity dealBookActivity(String commodity, List<FilledDeal> deals) {
  final qty = deals.fold<int>(0, (sum, d) => sum + d.quantity);
  return MarketActivity(
    totalBidQuantity: qty,
    totalOfferQuantity: qty,
    filledQuantity: qty,
    deals: deals,
  );
}

void expectDealBookTotals(WidgetTester tester, {int? bids, int? offers}) {
  if (bids != null) {
    final bidsTotals = tester.widget<Text>(
      find.byKey(TradeScreenDealBookKeys.dealBookBidsTotalsKey),
    );
    expect(
      bidsTotals.data,
      TradeScreenDealBookKeys.formatTotalsLine(
        TradeScreenDealBookKeys.dealBookTotalSpentLabel,
        bids,
      ),
    );
  }
  if (offers != null) {
    final offersTotals = tester.widget<Text>(
      find.byKey(TradeScreenDealBookKeys.dealBookOffersTotalsKey),
    );
    expect(
      offersTotals.data,
      TradeScreenDealBookKeys.formatTotalsLine(
        TradeScreenDealBookKeys.dealBookTotalReceivedLabel,
        offers,
      ),
    );
  }
}
