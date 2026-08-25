// Widget tests for Market tab wide two-column + compact row layout (Refs #4227).
// SPEC/ui/trade-screen.md § Market tab — wide two-column layout.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_market_row_controls.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_market_row_header.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

List<Commodity> _foodCommodities() {
  return <Commodity>[
    for (final Commodity c in CommodityCatalog.all)
      if (c.category == CommodityCategory.food && c.id != 'spices') c,
  ];
}

List<Commodity> _manufacturedCommodities() {
  return <Commodity>[
    for (final Commodity c in CommodityCatalog.all)
      if (c.category == CommodityCategory.manufactured && c.id != 'spices') c,
  ];
}

Finder _rowRootColumn(Finder rowKeyFinder) {
  return find.descendant(
    of: rowKeyFinder,
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is Column &&
          widget.crossAxisAlignment == CrossAxisAlignment.start &&
          widget.mainAxisSize == MainAxisSize.min &&
          widget.children.isNotEmpty &&
          widget.children.first is MarketCommodityRowHeader,
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab wide layout (Refs #4227)', () {
    testWidgets(
      'AC-1: food section rows 0 and 1 share a row on wide viewport',
      (tester) async {
        final List<Commodity> food = _foodCommodities();
        expect(food.length, greaterThanOrEqualTo(2));

        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(),
          viewport: kTradeMarketTabViewport,
        );

        final Finder firstRow = find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(food[0].id),
        );
        final Finder secondRow = find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(food[1].id),
        );

        final Offset firstOffset = tester.getTopLeft(firstRow);
        final Offset secondOffset = tester.getTopLeft(secondRow);
        expect(secondOffset.dx, greaterThan(firstOffset.dx));
        expect(secondOffset.dy, firstOffset.dy);
      },
    );

    testWidgets(
      'AC-1: odd manufactured count leaves trailing item in left column only',
      (tester) async {
        final List<Commodity> manufactured = _manufacturedCommodities();
        expect(manufactured.length.isOdd, isTrue);

        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(),
          viewport: kTradeMarketTabViewport,
        );

        final CommodityId lastId = manufactured.last.id;
        final CommodityId priorId = manufactured[manufactured.length - 2].id;
        final CommodityId firstId = manufactured.first.id;

        final Offset lastOffset = tester.getTopLeft(
          find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(lastId)),
        );
        final Offset priorOffset = tester.getTopLeft(
          find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(priorId)),
        );
        final Offset firstOffset = tester.getTopLeft(
          find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(firstId)),
        );

        expect(lastOffset.dx, firstOffset.dx);
        expect(priorOffset.dx, greaterThan(firstOffset.dx));
        expect(lastOffset.dy, greaterThan(priorOffset.dy));
      },
    );

    testWidgets(
      'AC-2: wide compact row has two-line structure with controls on line 2',
      (tester) async {
        final CommodityId commodityId = _foodCommodities().first.id;

        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(),
          viewport: kTradeMarketTabViewport,
        );

        final Finder rowKey = find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(commodityId),
        );
        final Column column = tester.widget<Column>(_rowRootColumn(rowKey));
        expect(column.children.length, 2);

        final Widget line2 = column.children[1];
        expect(line2, isA<Padding>());
        expect(
          find.descendant(
            of: find.byWidget(line2),
            matching: find.byType(MarketCommodityRowControls),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byWidget(line2),
            matching: find.textContaining('Last turn'),
          ),
          findsNothing,
        );

        final Offset headerBottom = tester.getBottomLeft(
          find.descendant(
            of: rowKey,
            matching: find.byKey(
              TradeScreenMarketKeys.marketRowResourceIconKey(commodityId),
            ),
          ),
        );
        final Offset bandTop = tester.getTopLeft(find.byWidget(line2));
        expect(bandTop.dy - headerBottom.dy, lessThanOrEqualTo(4));
      },
    );

    testWidgets(
      'AC-3: narrow viewport preserves two-line stacked row structure',
      (tester) async {
        final CommodityId commodityId = _foodCommodities().first.id;

        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(),
          viewport: const Size(kNarrowBreakpoint - 1, 4096),
        );

        final Finder rowKey = find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(commodityId),
        );
        final Column column = tester.widget<Column>(_rowRootColumn(rowKey));
        expect(column.children.length, 3);

        expect(
          find.descendant(
            of: rowKey,
            matching: find.textContaining('Last turn'),
          ),
          findsNothing,
        );

        expect(
          find.descendant(
            of: rowKey,
            matching: find.byType(MarketCommodityRowControls),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC-5: bid staging on wide compact rows matches narrow interaction contract',
      (tester) async {
        final CommodityId commodityId = CommodityCatalog.timber.id;
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            stockpile: tradeableStockpileFilled(10),
          ),
          viewport: kTradeMarketTabViewport,
        );
        addTearDown(container.dispose);

        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(commodityId)),
        );
        await tester.pumpAndSettle();

        final Orders orders = container.read(currentOrdersProvider);
        final List<TradeOrder>? staged =
            orders.tradeOrdersByPlayerId[kTradeTestHumanPlayerId];
        expect(staged, isNotNull);
        expect(
          staged!.singleWhere((TradeOrder o) => o.commodityId == commodityId),
          isA<TradeOrder>().having(
            (TradeOrder o) => o.type,
            'type',
            TradeOrderType.bid,
          ),
        );
      },
    );
  });
}
