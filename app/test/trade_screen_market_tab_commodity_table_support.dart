// Market tab commodity-table section helpers (Refs #4352).

import 'package:colonizethis_app/config/app_constants.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

List<Commodity> tradeMarketTradeableCommodities() => <Commodity>[
      for (final Commodity c in CommodityCatalog.all)
        if (c.category != CommodityCategory.riches && c.id != 'spices') c,
    ];

List<Commodity> tradeMarketCommoditiesInCategory(CommodityCategory category) =>
    <Commodity>[
      for (final Commodity c in CommodityCatalog.all)
        if (c.category == category && c.id != 'spices') c,
    ];

void expectTradeMarketSectionHeaderOrder(WidgetTester tester) {
  final foodHeaderOffset = tester.getTopLeft(
    find.byKey(TradeScreenMarketKeys.marketSectionFoodKey),
  );
  final rawMaterialsHeaderOffset = tester.getTopLeft(
    find.byKey(TradeScreenMarketKeys.marketSectionRawMaterialsKey),
  );
  final manufacturedHeaderOffset = tester.getTopLeft(
    find.byKey(TradeScreenMarketKeys.marketSectionManufacturedKey),
  );

  expect(rawMaterialsHeaderOffset.dy, greaterThan(foodHeaderOffset.dy));
  expect(manufacturedHeaderOffset.dy, greaterThan(rawMaterialsHeaderOffset.dy));
}

void expectTradeMarketRowsOrderedWithinSections(WidgetTester tester) {
  for (final sectionRows in <List<Commodity>>[
    tradeMarketCommoditiesInCategory(CommodityCategory.food),
    tradeMarketCommoditiesInCategory(CommodityCategory.rawMaterial),
    tradeMarketCommoditiesInCategory(CommodityCategory.manufactured),
  ]) {
    for (var i = 1; i < sectionRows.length; i++) {
      final prior = tester.getTopLeft(
        find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(sectionRows[i - 1].id),
        ),
      );
      final current = tester.getTopLeft(
        find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(sectionRows[i].id),
        ),
      );
      expect(current.dy, greaterThan(prior.dy));
    }
  }
}

void expectTradeMarketCrossSectionBoundaries(WidgetTester tester) {
  final food = tradeMarketCommoditiesInCategory(CommodityCategory.food);
  final raw = tradeMarketCommoditiesInCategory(CommodityCategory.rawMaterial);
  final mfg = tradeMarketCommoditiesInCategory(CommodityCategory.manufactured);

  final rawHeader = tester.getTopLeft(
    find.byKey(TradeScreenMarketKeys.marketSectionRawMaterialsKey),
  );
  final mfgHeader = tester.getTopLeft(
    find.byKey(TradeScreenMarketKeys.marketSectionManufacturedKey),
  );

  final lastFoodRow = tester.getTopLeft(
    find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(food.last.id)),
  );
  final firstRawRow = tester.getTopLeft(
    find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(raw.first.id)),
  );
  expect(lastFoodRow.dy, lessThan(rawHeader.dy));
  expect(rawHeader.dy, lessThan(firstRawRow.dy));

  final lastRawRow = tester.getTopLeft(
    find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(raw.last.id)),
  );
  final firstMfgRow = tester.getTopLeft(
    find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(mfg.first.id)),
  );
  expect(lastRawRow.dy, lessThan(mfgHeader.dy));
  expect(mfgHeader.dy, lessThan(firstMfgRow.dy));
}

Future<void> pumpObserveModeChromeMarket(WidgetTester tester) async {
  await pumpTradeScreenWithContainer(
    tester,
    game: buildTradeTestGame(
      id: 'test_trade_screen_market_tab_observe_mode_chrome',
      stockpile: tradeableStockpileFilled(99),
    ),
    canMutateViaUi: false,
  );
}

void expectObserveModeSectionHeadersMounted(WidgetTester tester) {
  final marketTab = find.byKey(TradeScreenMarketKeys.marketTabBodyKey);
  expect(marketTab, findsOneWidget);
  for (final Key sectionKey in <Key>[
    TradeScreenMarketKeys.marketSectionFoodKey,
    TradeScreenMarketKeys.marketSectionRawMaterialsKey,
    TradeScreenMarketKeys.marketSectionManufacturedKey,
  ]) {
    expect(
      find.descendant(of: marketTab, matching: find.byKey(sectionKey)),
      findsOneWidget,
    );
  }
}

void expectObserveModeRowIconsMounted(WidgetTester tester) {
  final list = find.byKey(TradeScreenMarketKeys.marketCommodityListKey);
  expect(list, findsOneWidget);
  for (final Commodity c in tradeMarketTradeableCommodities()) {
    final iconFinder = find.descendant(
      of: list,
      matching: find.byKey(TradeScreenMarketKeys.marketRowResourceIconKey(c.id)),
    );
    expect(iconFinder, findsOneWidget);
    final ResourceIcon icon = tester.widget<ResourceIcon>(iconFinder);
    expect(icon.size, TradeScreenMarketKeys.marketRowResourceIconSize);

    final coinFinder = find.descendant(
      of: list,
      matching: find.byKey(TradeScreenMarketKeys.marketRowPriceCoinIconKey(c.id)),
    );
    expect(coinFinder, findsOneWidget);
    final StrictAssetIcon coin = tester.widget<StrictAssetIcon>(coinFinder);
    expect(coin.width, TradeScreenMarketKeys.marketRowPriceCoinIconSize);
    expect(coin.height, TradeScreenMarketKeys.marketRowPriceCoinIconSize);
  }
}

void expectObserveModeSellableReadoutsMounted(
  WidgetTester tester, {
  required int qty,
}) {
  final list = find.byKey(TradeScreenMarketKeys.marketCommodityListKey);
  for (final Commodity c in tradeMarketTradeableCommodities()) {
    final sellableFinder = find.descendant(
      of: list,
      matching: find.byKey(TradeScreenMarketKeys.marketRowSellableReadoutKey(c.id)),
    );
    expect(sellableFinder, findsOneWidget);
    final Text sellable = tester.widget<Text>(sellableFinder);
    // ignore: avoid_hardcoded_strings_in_widgets
    expect(sellable.data, '($qty)');
  }
}
