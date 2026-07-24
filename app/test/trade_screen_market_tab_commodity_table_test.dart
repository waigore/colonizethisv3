// Widget tests for the Market tab read-only commodity table
// (Refs #2993 E5a + #3093 integer-price refresh + sectioned grouping).
// SPEC/ui/trade-screen.md § Body — Market tab.
//
// Exercises the durable contract for the Market tab body:
//
//  * one row per tradeable commodity (full CommodityCatalog minus
//    riches and `spices` — 22 rows total per SPEC/game/world-market.md
//    §Tradeable commodities),
//  * Production-style sectioned grouping (`#3093` § Layout & grouping):
//    the rows are grouped by [CommodityCategory] under `CtSectionLabel`
//    headers — Food → Raw Materials → Manufactured — and within each
//    section the rows follow `CommodityCatalog.all` catalog order
//    (mirroring the Production panel's Available subpanel),
//  * last market price sourced from `Game.worldMarketState.prices`
//    (integer, post-#3093). Rows fall back to
//    `ResourceRules.defaultMarketPriceForCommodityId` when the prices
//    map lacks an entry — the catalog covers every tradeable commodity,
//    raw resources (e.g. iron → 80) and manufactured commodities (e.g.
//    lumber → 60 per SPEC/game/commodity-catalog.md § Manufactured base
//    prices). The em-dash glyph is reserved as a defensive fallback for
//    future commodity additions that ship without a catalog default.
//  * previous-turn aggregate volume line `Bids X / Offers Y` sourced
//    from `Game.worldMarketState.lastTurnActivity`.
//
// The interactive Market controls (bid/offer toggle, quantity stepper,
// priority dropdown, cargo indicator) ship in follow-up slices and are
// out of scope for this pin file.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

        final List<Commodity> tradeable = <Commodity>[
          for (final Commodity c in CommodityCatalog.all)
            if (c.category != CommodityCategory.riches && c.id != 'spices') c,
        ];
        expect(
          tradeable.length,
          22,
          reason:
              'SPEC/game/world-market.md §Tradeable commodities — the '
              'tradeable set is the full CommodityCatalog minus riches '
              'and spices (22 rows). If this count changes, '
              'SPEC/game/world-market.md and SPEC/ui/trade-screen.md '
              'must both be updated together with the row pin below.',
        );

        // Each tradeable commodity must be present as a row keyed by
        // its commodity id, scoped under the marketCommodityListKey.
        for (final Commodity c in tradeable) {
          final rowFinder = find.descendant(
            of: list,
            matching: find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(c.id)),
          );
          expect(
            rowFinder,
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

        final list = find.byKey(TradeScreenMarketKeys.marketCommodityListKey);
        expect(list, findsOneWidget);

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
            reason:
                'SPEC/game/world-market.md §Tradeable commodities — '
                '`$excluded` is not tradeable and must not render a row.',
          );
        }
      },
    );

    testWidgets('rows are grouped under Food / Raw Materials / Manufactured '
        'CtSectionLabel headers in catalog order — deterministic order '
        'pin (#3093 sectioned grouping)', (tester) async {
      await pumpTradeScreen(tester, game: buildTradeTestGame());

      // All three section headers mounted in order Food → Raw
      // Materials → Manufactured. The pin verifies their vertical
      // positions in the parent column, which guarantees the
      // expected reading order.
      final Offset foodHeaderOffset = tester.getTopLeft(
        find.byKey(TradeScreenMarketKeys.marketSectionFoodKey),
      );
      final Offset rawMaterialsHeaderOffset = tester.getTopLeft(
        find.byKey(TradeScreenMarketKeys.marketSectionRawMaterialsKey),
      );
      final Offset manufacturedHeaderOffset = tester.getTopLeft(
        find.byKey(TradeScreenMarketKeys.marketSectionManufacturedKey),
      );

      expect(
        rawMaterialsHeaderOffset.dy,
        greaterThan(foodHeaderOffset.dy),
        reason:
            'SPEC/ui/trade-screen.md § Market tab — sectioned '
            'grouping (#3093): the Raw Materials section header must '
            'appear below the Food section header.',
      );
      expect(
        manufacturedHeaderOffset.dy,
        greaterThan(rawMaterialsHeaderOffset.dy),
        reason:
            'SPEC/ui/trade-screen.md § Market tab — sectioned '
            'grouping (#3093): the Manufactured section header must '
            'appear below the Raw Materials section header.',
      );

      // Each section contains its category's commodities in
      // CommodityCatalog.all iteration order (the same order the
      // Production panel uses). Build the expected per-section
      // lists from the live catalog so a future ruleset extension
      // automatically reflects in the assertion without manual
      // edits.
      final List<Commodity> foodCommodities = <Commodity>[
        for (final Commodity c in CommodityCatalog.all)
          if (c.category == CommodityCategory.food && c.id != 'spices') c,
      ];
      final List<Commodity> rawMaterialCommodities = <Commodity>[
        for (final Commodity c in CommodityCatalog.all)
          if (c.category == CommodityCategory.rawMaterial && c.id != 'spices')
            c,
      ];
      final List<Commodity> manufacturedCommodities = <Commodity>[
        for (final Commodity c in CommodityCatalog.all)
          if (c.category == CommodityCategory.manufactured && c.id != 'spices')
            c,
      ];

      for (final List<Commodity> sectionRows in <List<Commodity>>[
        foodCommodities,
        rawMaterialCommodities,
        manufacturedCommodities,
      ]) {
        for (int i = 1; i < sectionRows.length; i++) {
          final Offset prior = tester.getTopLeft(
            find.byKey(
              TradeScreenMarketKeys.marketCommodityRowKey(sectionRows[i - 1].id),
            ),
          );
          final Offset current = tester.getTopLeft(
            find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(sectionRows[i].id)),
          );
          expect(
            current.dy,
            greaterThan(prior.dy),
            reason:
                'Row `${sectionRows[i].id}` must appear below row '
                '`${sectionRows[i - 1].id}` (catalog order within '
                'its category section).',
          );
        }
      }

      // Cross-section pin: the last food row must precede the Raw
      // Materials header which must precede the first raw-material
      // row; likewise for the manufactured boundary. This catches
      // regressions where a single commodity slips out of its
      // section into the wrong bucket.
      final Offset lastFoodRow = tester.getTopLeft(
        find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(foodCommodities.last.id)),
      );
      final Offset firstRawMaterialRow = tester.getTopLeft(
        find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(rawMaterialCommodities.first.id),
        ),
      );
      expect(
        lastFoodRow.dy,
        lessThan(rawMaterialsHeaderOffset.dy),
        reason:
            'The last Food row (`${foodCommodities.last.id}`) must '
            'sit above the Raw Materials section header.',
      );
      expect(
        rawMaterialsHeaderOffset.dy,
        lessThan(firstRawMaterialRow.dy),
        reason:
            'The Raw Materials section header must sit above the '
            'first Raw Materials row '
            '(`${rawMaterialCommodities.first.id}`).',
      );

      final Offset lastRawMaterialRow = tester.getTopLeft(
        find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(rawMaterialCommodities.last.id),
        ),
      );
      final Offset firstManufacturedRow = tester.getTopLeft(
        find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(manufacturedCommodities.first.id),
        ),
      );
      expect(
        lastRawMaterialRow.dy,
        lessThan(manufacturedHeaderOffset.dy),
        reason:
            'The last Raw Materials row '
            '(`${rawMaterialCommodities.last.id}`) must sit above '
            'the Manufactured section header.',
      );
      expect(
        manufacturedHeaderOffset.dy,
        lessThan(firstManufacturedRow.dy),
        reason:
            'The Manufactured section header must sit above the '
            'first Manufactured row '
            '(`${manufacturedCommodities.first.id}`).',
      );
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
              // ignore: avoid_hardcoded_strings_in_widgets
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
          final row = find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(case_.id));
          expect(row, findsOneWidget);
          expect(
            find.descendant(of: row, matching: find.text(case_.price)),
            findsOneWidget,
          );
        }

        // Negative pin: catalog-backed rows keep only the quantity-idle
        // em-dash (price-slot em-dash must not appear).
        for (final id in <CommodityId>[
          CommodityCatalog.iron.id,
          CommodityCatalog.lumber.id,
        ]) {
          expect(
            find.descendant(
              of: find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(id)),
              // ignore: avoid_hardcoded_strings_in_widgets
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
      'renders the previous-turn aggregate volume line `Bids X / Offers Y` '
      'from WorldMarketState.lastTurnActivity (with zero-default for '
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
            // ignore: avoid_hardcoded_strings_in_widgets
            matching: find.text('Bids 12 / Offers 8'),
          ),
          findsOneWidget,
          reason:
              'SPEC/ui/trade-screen.md § Body — Market tab: per-row '
              'inline aggregate volumes sourced from '
              '`WorldMarketState.lastTurnActivity[commodityId]`.',
        );

        // Commodity not present in the activity map falls back to 0/0.
        final fabricRow = find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(CommodityCatalog.fabric.id),
        );
        expect(fabricRow, findsOneWidget);
        expect(
          find.descendant(
            of: fabricRow,
            // ignore: avoid_hardcoded_strings_in_widgets
            matching: find.text('Bids 0 / Offers 0'),
          ),
          findsOneWidget,
          reason:
              'SPEC/ui/trade-screen.md § Body — Market tab: rows for '
              'commodities absent from `WorldMarketState.lastTurnActivity` '
              'default to a zero-volume line so the column reads '
              'consistently for every row.',
        );
      },
    );

    testWidgets(
      'commodity rows render only inside the Market tab body — the off-stage '
      'Deal Book tab placeholder body does not host any commodity row keys',
      (tester) async {
        await pumpTradeScreen(tester, game: buildTradeTestGame());

        // Sanity: Market tab body hosts the list and rows.
        expect(
          find.descendant(
            of: find.byKey(TradeScreenMarketKeys.marketTabBodyKey),
            matching: find.byKey(TradeScreenMarketKeys.marketCommodityListKey),
          ),
          findsOneWidget,
        );

        // The off-stage Deal Book body must not host any commodity row
        // — both off-stage and on-stage scopes.
        expect(
          find.descendant(
            of: find.byKey(TradeScreenDealBookKeys.dealBookTabBodyKey, skipOffstage: false),
            matching: find.byKey(TradeScreenMarketKeys.marketCommodityListKey),
          ),
          findsNothing,
        );
      },
    );
  });
}
