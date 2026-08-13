// Widget tests for the Market tab read-only commodity table
// (Refs #2993 E5a + #3093 integer-price refresh + sectioned grouping).
// SPEC/ui/trade-screen.md § Body — Market tab.
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_market_tab_commodity_table_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab read-only commodity table (Refs #2993 E5a)', () {
    testWidgets(
      'renders 22 tradeable rows (CommodityCatalog minus riches + spices) '
      'inside marketCommodityListKey',
      (tester) async {
        await pumpTradeScreen(tester, game: buildTradeTestGame());

        final list = find.byKey(TradeScreenMarketKeys.marketCommodityListKey);
        expect(list, findsOneWidget);

        final tradeable = tradeMarketTradeableCommodities();
        expect(tradeable.length, 22);

        for (final Commodity c in tradeable) {
          expect(
            find.descendant(
              of: list,
              matching: find.byKey(
                TradeScreenMarketKeys.marketCommodityRowKey(c.id),
              ),
            ),
            findsOneWidget,
            reason:
                'tradeable commodity `${c.id}` must render a row keyed '
                'tradeScreenMarketRow:${c.id} inside the Market tab list.',
          );
        }
      },
    );

    testWidgets(
      'excludes riches commodities and the `spices` advanced commodity '
      '(negative AC: no row key for gold / silver / gems / diamonds / spices)',
      (tester) async {
        await pumpTradeScreen(tester, game: buildTradeTestGame());

        for (final CommodityId excluded in <CommodityId>[
          CommodityCatalog.gold.id,
          CommodityCatalog.silver.id,
          CommodityCatalog.gems.id,
          CommodityCatalog.diamonds.id,
          CommodityCatalog.spices.id,
        ]) {
          expect(
            find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(excluded)),
            findsNothing,
          );
        }
      },
    );

    testWidgets('rows are grouped under Food / Raw Materials / Manufactured '
        'CtSectionLabel headers in catalog order — deterministic order '
        'pin (#3093 sectioned grouping, narrow viewport)', (tester) async {
      await pumpTradeScreen(
        tester,
        game: buildTradeTestGame(),
        viewport: const Size(400, 4096),
      );

      expectTradeMarketSectionHeaderOrder(tester);
      expectTradeMarketRowsOrderedWithinSections(tester);
      expectTradeMarketCrossSectionBoundaries(tester);
    });

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
      'Market prices: seeded timber=30; catalog fallbacks iron=80, '
      'lumber=60, castIron=160; idle quantity em-dash only (Refs #3093)',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(
            id: 'test_trade_screen_market_tab',
            prices: const <CommodityId, int>{'timber': 30},
          ),
        );

        for (final case_ in <({CommodityId id, String price})>[
          (id: CommodityCatalog.timber.id, price: '30'),
          (id: CommodityCatalog.iron.id, price: '80'),
          (id: CommodityCatalog.lumber.id, price: '60'),
          (id: CommodityCatalog.castIron.id, price: '160'),
        ]) {
          final row = find.byKey(
            TradeScreenMarketKeys.marketCommodityRowKey(case_.id),
          );
          expect(row, findsOneWidget);
          expect(
            find.descendant(of: row, matching: find.text(case_.price)),
            findsOneWidget,
          );
        }

        for (final id in <CommodityId>[
          CommodityCatalog.iron.id,
          CommodityCatalog.lumber.id,
        ]) {
          expect(
            find.descendant(
              of: find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(id)),
              matching: find.text('—'),
            ),
            findsOneWidget,
          );
        }
        expect(
          find.byKey(
            TradeScreenMarketKeys.marketRowQuantityTextKey(CommodityCatalog.iron.id),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders the previous-turn aggregate volume line '
      '`Last turn: bids X · offers Y` from '
      'WorldMarketState.lastTurnActivity (with zero-default for '
      'commodities absent from the activity map)',
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
            matching: find.text('Last turn: bids 12 · offers 8'),
          ),
          findsOneWidget,
        );

        final fabricRow = find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(CommodityCatalog.fabric.id),
        );
        expect(fabricRow, findsOneWidget);
        expect(
          find.descendant(
            of: fabricRow,
            matching: find.text('Last turn: bids 0 · offers 0'),
          ),
          findsOneWidget,
        );
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
  });
}
