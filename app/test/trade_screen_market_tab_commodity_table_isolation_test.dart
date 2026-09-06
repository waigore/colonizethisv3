// Market tab commodity-table tab-body isolation checks (Refs #4734 Slice G).
// Primary table ACs: trade_screen_market_tab_commodity_table_test.dart.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab body isolation (Refs #4734 Slice G)', () {
    testWidgets(
      'section headers show Food/Raw Materials/Manufactured labels inside '
      'Market tab body only (not Deal Book)',
      (tester) async {
        await pumpTradeScreen(tester, game: buildTradeTestGame());

        for (final case_ in <({Key key, String label})>[
          (key: TradeScreenMarketKeys.marketSectionFoodKey, label: 'FOOD'),
          (
            key: TradeScreenMarketKeys.marketSectionRawMaterialsKey,
            label: 'RAW MATERIALS',
          ),
          (
            key: TradeScreenMarketKeys.marketSectionManufacturedKey,
            label: 'MANUFACTURED',
          ),
        ]) {
          expect(
            find.descendant(
              of: find.byKey(case_.key),
              matching: find.text(case_.label),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byKey(TradeScreenMarketKeys.marketTabBodyKey),
              matching: find.byKey(case_.key),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byKey(
                TradeScreenDealBookKeys.dealBookTabBodyKey,
                skipOffstage: false,
              ),
              matching: find.byKey(case_.key),
            ),
            findsNothing,
          );
        }
      },
    );

    testWidgets(
      'commodity rows render only inside the Market tab body — the off-stage '
      'Deal Book tab placeholder body does not host any commodity row keys',
      (tester) async {
        await pumpTradeScreen(tester, game: buildTradeTestGame());

        expect(
          find.descendant(
            of: find.byKey(TradeScreenMarketKeys.marketTabBodyKey),
            matching: find.byKey(TradeScreenMarketKeys.marketCommodityListKey),
          ),
          findsOneWidget,
        );

        expect(
          find.descendant(
            of: find.byKey(
              TradeScreenDealBookKeys.dealBookTabBodyKey,
              skipOffstage: false,
            ),
            matching: find.byKey(TradeScreenMarketKeys.marketCommodityListKey),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'renders Last market on non-zero last-turn volume and omits volume '
      'chrome when the commodity is absent from lastTurnActivity',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(
            id: 'test_trade_screen_market_tab',
            lastTurnActivity: const <CommodityId, MarketActivity>{
              'timber': MarketActivity(
                totalBidQuantity: 12,
                totalOfferQuantity: 8,
              ),
            },
          ),
        );

        final timberRow = find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(CommodityCatalog.timber.id),
        );
        expect(timberRow, findsOneWidget);
        expect(
          find.descendant(
            of: timberRow,
            matching: find.byKey(
              TradeScreenMarketKeys.marketRowLastMarketChipKey(
                CommodityCatalog.timber.id,
              ),
            ),
          ),
          findsOneWidget,
        );
        expect(find.text('Last turn: bids 12 · offers 8'), findsNothing);

        final fabricRow = find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(CommodityCatalog.fabric.id),
        );
        expect(fabricRow, findsOneWidget);
        expect(
          find.descendant(
            of: fabricRow,
            matching: find.byKey(
              TradeScreenMarketKeys.marketRowLastMarketChipKey(
                CommodityCatalog.fabric.id,
              ),
            ),
          ),
          findsNothing,
        );
        expect(find.text('Last turn: bids 0 · offers 0'), findsNothing);
      },
    );
  });
}
