// TradeScreen E8 market pump/assert helpers (Refs #2993, #4117 / #4642 Slice C).

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/widgets/panels/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_e8_test_helpers.dart';
import 'trade_screen_test_support.dart';

String tradeE8CargoIndicatorText(WidgetTester tester) =>
    tester
        .widget<Text>(find.byKey(TradeScreenMarketKeys.marketCargoIndicatorKey))
        .data ??
    '';

Future<void> tradeE8SwitchToDealBook(WidgetTester tester) async {
  final Finder dealBookLabel = find.descendant(
    of: find.byType(CtTabStrip),
    matching: find.text(TradeScreenDealBookKeys.dealBookTabLabel),
  );
  expect(dealBookLabel, findsOneWidget);
  await tester.tap(dealBookLabel);
  await tester.pump();
}

Future<ProviderContainer> tradeE8PumpMarket(
  WidgetTester tester, {
  WorldMarketState? worldMarketState,
  int? tradeCargoCapacityOverride,
  Orders initialOrders = const Orders(),
  bool canMutateViaUi = true,
  int treasury = 500,
  List<OvertureState> overtureStates = const <OvertureState>[],
}) => pumpTradeScreenWithContainer(
  tester,
  game: buildTradeTestGame(
    id: 'test_trade_screen_e8',
    treasury: treasury,
    stockpile: tradeableStockpileFilled(99),
    worldMarketState: worldMarketState,
    tradeCargoCapacityOverride: tradeCargoCapacityOverride,
    overtureStates: overtureStates,
  ),
  initialOrders: initialOrders,
  canMutateViaUi: canMutateViaUi,
);

Future<void> tradeE8IncrementCommodity(
  WidgetTester tester,
  CommodityId commodityId,
  int taps,
) async {
  for (int i = 0; i < taps; i++) {
    await tester.tap(
      find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(commodityId)),
    );
    await tester.pump();
  }
}

Future<void> tradeE8TapBid(WidgetTester tester, CommodityId commodityId) async {
  await tester.tap(
    find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(commodityId)),
  );
  await tester.pump();
}

Future<void> tradeE8TapOffer(
  WidgetTester tester,
  CommodityId commodityId,
) async {
  await tester.tap(
    find.byKey(TradeScreenMarketKeys.marketRowOfferChipKey(commodityId)),
  );
  await tester.pump();
}

void expectTradeE8CargoSaturated(WidgetTester tester) {
  expect(tradeE8CargoIndicatorText(tester), 'Cargo remaining: 0');
  expect(
    find.byKey(TradeScreenMarketKeys.marketCargoWarningKey),
    findsOneWidget,
  );
  expect(
    find.text(TradeScreenMarketKeys.cargoLimitWarningText),
    findsOneWidget,
  );
}

void expectTradeE8Chrome(WidgetTester tester) {
  final CtTopBar topBar = tester.widget<CtTopBar>(
    find.byKey(TradeScreenMarketKeys.topBarKey),
  );
  expect(topBar.title, TradeScreenMarketKeys.topBarTitle);
  expect(topBar.backButtonLabel, TradeScreenMarketKeys.topBarBackLabel);
  expect(find.byKey(TradeScreenMarketKeys.tabsBodyKey), findsOneWidget);
  final CtTabStrip strip = tester.widget<CtTabStrip>(
    find.descendant(
      of: find.byKey(TradeScreenMarketKeys.tabsBodyKey),
      matching: find.byType(CtTabStrip),
    ),
  );
  expect(strip.tabLabels, <String>[
    TradeScreenMarketKeys.marketTabLabel,
    TradeScreenDealBookKeys.dealBookTabLabel,
  ]);
  expect(
    find.descendant(
      of: find.byKey(TradeScreenMarketKeys.tabsBodyKey),
      matching: find.byType(CtPanel),
    ),
    findsOneWidget,
  );
}

void expectTradeE8DealBookTotals(
  WidgetTester tester, {
  required String bidsTotal,
  required String offersTotal,
}) {
  expect(
    tester
        .widget<Text>(find.byKey(TradeScreenDealBookKeys.dealBookBidsTotalsKey))
        .data,
    bidsTotal,
  );
  expect(
    tester
        .widget<Text>(
          find.byKey(TradeScreenDealBookKeys.dealBookOffersTotalsKey),
        )
        .data,
    offersTotal,
  );
}

void expectTradeE8ObserveModeBlocksMarket(WidgetTester tester) {
  expect(find.byType(TradeScreen), findsOneWidget);
  expect(find.byKey(TradeScreenMarketKeys.topBarKey), findsOneWidget);
  final Finder observePanelFinder = find.byType(ObserveModeNotDefinedPanel);
  expect(observePanelFinder, findsOneWidget);
  // ignore: avoid_hardcoded_strings_in_widgets
  expect(
    tester.widget<ObserveModeNotDefinedPanel>(observePanelFinder).title,
    'Trade',
  );
  for (final Finder finder in <Finder>[
    find.byKey(TradeScreenMarketKeys.tabsBodyKey),
    find.byKey(TradeScreenMarketKeys.marketTabBodyKey),
    find.byKey(TradeScreenDealBookKeys.dealBookTabBodyKey),
    find.byType(CtTabStrip),
    find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(kTradeE8Timber)),
    find.byKey(TradeScreenMarketKeys.marketRowOfferChipKey(kTradeE8Timber)),
    find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(kTradeE8Timber)),
  ]) {
    expect(finder, findsNothing);
  }
}

WorldMarketState tradeE8PartialTimberDealBookMarket() => WorldMarketState(
  prices: const <CommodityId, int>{},
  lastTurnActivity: const <CommodityId, MarketActivity>{
    'timber': MarketActivity(
      totalBidQuantity: 10,
      totalOfferQuantity: 5,
      filledQuantity: 5,
      deals: <FilledDeal>[
        FilledDeal(
          sellerFactionId: 'gp_a',
          buyerFactionId: kTradeE8HumanPlayerId,
          commodityId: 'timber',
          quantity: 5,
          pricePerUnit: 8.4,
        ),
      ],
    ),
  },
  carryForwardBidsByFactionId: <String, List<TradeOrder>>{
    kTradeE8HumanPlayerId: <TradeOrder>[tradeE8Bid('timber', 5)],
  },
  carryForwardOffersByFactionId: <String, List<TradeOrder>>{
    kTradeE8HumanPlayerId: <TradeOrder>[tradeE8Offer('fabric', 3)],
  },
);
