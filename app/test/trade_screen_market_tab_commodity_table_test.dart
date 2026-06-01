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
//    `ResourceRules.defaultMarketPrice` when the prices map lacks an
//    entry for a raw-resource commodity (e.g. iron — base price 80);
//    rows for manufactured commodities (no catalog default today) still
//    render the em-dash glyph `—` until they participate in a market
//    turn. Tracked as follow-up to #3093.
//  * previous-turn aggregate volume line `Bids X / Offers Y` sourced
//    from `Game.worldMarketState.lastTurnActivity`.
//
// The interactive Market controls (bid/offer toggle, quantity stepper,
// priority dropdown, cargo indicator) ship in follow-up slices and are
// out of scope for this pin file.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a synthetic Game with one human player and a populated
/// [WorldMarketState] so the Market tab table renders deterministic
/// rows the assertions below pin. Mirrors the lightweight Widgetbook
/// Game factory in `catalog_part6.dart` so the same data shape proves
/// the contract in both surfaces.
Game _buildGame({
  Map<CommodityId, int>? prices,
  Map<CommodityId, MarketActivity>? activity,
}) {
  return Game(
    id: 'test_trade_screen_market_tab',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      // ignore: avoid_hardcoded_strings_in_widgets
      Player(id: 'gp_h', displayName: 'England', isHuman: true, treasury: 500),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: WorldMarketState(
      prices: prices ?? const <CommodityId, int>{},
      lastTurnActivity:
          activity ?? const <CommodityId, MarketActivity>{},
    ),
  );
}

/// Pumps the [TradeScreen] in isolation (no Hive, no AppEventBus
/// listeners) so the assertions can pin the Market tab body without
/// the full in-game shell. Mirrors the lightweight harness used by
/// `trade_screen_320dp_min_viewport_test.dart`.
Future<void> _pumpTradeScreen(
  WidgetTester tester, {
  required Game game,
}) async {
  final Player player = game.players.first;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      ],
      child: MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: TradeScreen(game: game, player: player),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  suppressLogsForTests();

  group(
    'TradeScreen Market tab read-only commodity table (Refs #2993 E5a)',
    () {
      testWidgets(
        'renders 22 tradeable rows (CommodityCatalog minus riches + spices) '
        'inside marketCommodityListKey',
        (tester) async {
          await _pumpTradeScreen(tester, game: _buildGame());

          final list = find.byKey(TradeScreen.marketCommodityListKey);
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
              matching: find.byKey(TradeScreen.marketCommodityRowKey(c.id)),
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
          await _pumpTradeScreen(tester, game: _buildGame());

          final list = find.byKey(TradeScreen.marketCommodityListKey);
          expect(list, findsOneWidget);

          for (final CommodityId excluded in <CommodityId>[
            CommodityCatalog.gold.id,
            CommodityCatalog.silver.id,
            CommodityCatalog.gems.id,
            CommodityCatalog.diamonds.id,
            CommodityCatalog.spices.id,
          ]) {
            expect(
              find.byKey(TradeScreen.marketCommodityRowKey(excluded)),
              findsNothing,
              reason:
                  'SPEC/game/world-market.md §Tradeable commodities — '
                  '`$excluded` is not tradeable and must not render a row.',
            );
          }
        },
      );

      testWidgets(
        'rows are grouped under Food / Raw Materials / Manufactured '
        'CtSectionLabel headers in catalog order — deterministic order '
        'pin (#3093 sectioned grouping)',
        (tester) async {
          await _pumpTradeScreen(tester, game: _buildGame());

          // All three section headers mounted in order Food → Raw
          // Materials → Manufactured. The pin verifies their vertical
          // positions in the parent column, which guarantees the
          // expected reading order.
          final Offset foodHeaderOffset = tester.getTopLeft(
            find.byKey(TradeScreen.marketSectionFoodKey),
          );
          final Offset rawMaterialsHeaderOffset = tester.getTopLeft(
            find.byKey(TradeScreen.marketSectionRawMaterialsKey),
          );
          final Offset manufacturedHeaderOffset = tester.getTopLeft(
            find.byKey(TradeScreen.marketSectionManufacturedKey),
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
              if (c.category == CommodityCategory.rawMaterial &&
                  c.id != 'spices')
                c,
          ];
          final List<Commodity> manufacturedCommodities = <Commodity>[
            for (final Commodity c in CommodityCatalog.all)
              if (c.category == CommodityCategory.manufactured &&
                  c.id != 'spices')
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
                  TradeScreen.marketCommodityRowKey(sectionRows[i - 1].id),
                ),
              );
              final Offset current = tester.getTopLeft(
                find.byKey(
                  TradeScreen.marketCommodityRowKey(sectionRows[i].id),
                ),
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
            find.byKey(
              TradeScreen.marketCommodityRowKey(foodCommodities.last.id),
            ),
          );
          final Offset firstRawMaterialRow = tester.getTopLeft(
            find.byKey(
              TradeScreen.marketCommodityRowKey(
                rawMaterialCommodities.first.id,
              ),
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
              TradeScreen.marketCommodityRowKey(
                rawMaterialCommodities.last.id,
              ),
            ),
          );
          final Offset firstManufacturedRow = tester.getTopLeft(
            find.byKey(
              TradeScreen.marketCommodityRowKey(
                manufacturedCommodities.first.id,
              ),
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
        },
      );

      testWidgets(
        'CtSectionLabel headers render their localized labels '
        '(Food / Raw Materials / Manufactured)',
        (tester) async {
          await _pumpTradeScreen(tester, game: _buildGame());

          // Section labels rendered as upper-case small-caps by
          // CtSectionLabel; pin the visible (upper-cased) literal.
          expect(
            find.descendant(
              of: find.byKey(TradeScreen.marketSectionFoodKey),
              // ignore: avoid_hardcoded_strings_in_widgets
              matching: find.text('FOOD'),
            ),
            findsOneWidget,
            reason:
                'CtSectionLabel renders its text in upper-case so the '
                'Food header should read `FOOD` (l10n English fallback '
                'when the host MaterialApp has no l10n delegates).',
          );
          expect(
            find.descendant(
              of: find.byKey(TradeScreen.marketSectionRawMaterialsKey),
              // ignore: avoid_hardcoded_strings_in_widgets
              matching: find.text('RAW MATERIALS'),
            ),
            findsOneWidget,
            reason:
                'CtSectionLabel renders its text in upper-case so the '
                'Raw Materials header should read `RAW MATERIALS`.',
          );
          expect(
            find.descendant(
              of: find.byKey(TradeScreen.marketSectionManufacturedKey),
              // ignore: avoid_hardcoded_strings_in_widgets
              matching: find.text('MANUFACTURED'),
            ),
            findsOneWidget,
            reason:
                'CtSectionLabel renders its text in upper-case so the '
                'Manufactured header should read `MANUFACTURED`.',
          );
        },
      );

      testWidgets(
        'every section header is mounted inside the Market tab body '
        '(not under the off-stage Deal Book tab body)',
        (tester) async {
          await _pumpTradeScreen(tester, game: _buildGame());

          for (final Key sectionKey in <Key>[
            TradeScreen.marketSectionFoodKey,
            TradeScreen.marketSectionRawMaterialsKey,
            TradeScreen.marketSectionManufacturedKey,
          ]) {
            expect(
              find.descendant(
                of: find.byKey(TradeScreen.marketTabBodyKey),
                matching: find.byKey(sectionKey),
              ),
              findsOneWidget,
              reason:
                  'Section header `$sectionKey` must be mounted inside '
                  'the Market tab body keyed `marketTabBodyKey`.',
            );
            expect(
              find.descendant(
                of: find.byKey(
                  TradeScreen.dealBookTabBodyKey,
                  skipOffstage: false,
                ),
                matching: find.byKey(sectionKey),
              ),
              findsNothing,
              reason:
                  'Section header `$sectionKey` must NOT leak into the '
                  'off-stage Deal Book tab body subtree.',
            );
          }
        },
      );

      testWidgets(
        'renders the live `WorldMarketState.prices` integer price for a '
        'seeded commodity (timber=30 → `30`) and falls back to the resource '
        'catalog default for an unseeded raw-resource commodity '
        '(iron → `80`); manufactured commodities without a catalog default '
        'still render the em-dash (Refs #3093)',
        (tester) async {
          await _pumpTradeScreen(
            tester,
            game: _buildGame(
              prices: const <CommodityId, int>{'timber': 30},
            ),
          );

          // Seeded commodity row shows the integer price text (Refs #3093 —
          // `Map<CommodityId, int>` post-floor at persistence boundary).
          final timberRow = find.byKey(
            TradeScreen.marketCommodityRowKey(CommodityCatalog.timber.id),
          );
          expect(timberRow, findsOneWidget);
          expect(
            find.descendant(of: timberRow, matching: find.text('30')),
            findsOneWidget,
            reason:
                'SPEC/ui/trade-screen.md § Body — Market tab (Refs #3093): '
                'the price cell reads `Game.worldMarketState.prices[id]` '
                'as a whole integer (price storage is now '
                '`Map<CommodityId, int>` per #3093 issue body § Price '
                'presentation & data model).',
          );

          // Unseeded raw-resource commodity row falls back to the resource
          // catalog default integer price (#3093 — iron defaults to 80 via
          // `ResourceRules.defaultRules.defaultMarketPriceForCommodityId`).
          final ironRow = find.byKey(
            TradeScreen.marketCommodityRowKey(CommodityCatalog.iron.id),
          );
          expect(ironRow, findsOneWidget);
          expect(
            find.descendant(of: ironRow, matching: find.text('80')),
            findsOneWidget,
            reason:
                'SPEC/ui/trade-screen.md § Body — Market tab (Refs #3093): '
                'rows fall back to the resource catalog '
                '`defaultMarketPrice` integer when '
                '`WorldMarketState.prices` lacks an entry. Iron is a raw '
                'resource with catalog default 80.',
          );
          // Negative pin: iron must NOT render the em-dash price glyph
          // (the price-slot em-dash is reserved for the manufactured
          // commodities whose catalog default has not been wired yet).
          // The quantity-idle em-dash is a separate concern below.
          expect(
            find.descendant(
              of: ironRow,
              matching: find.text(
                // ignore: avoid_hardcoded_strings_in_widgets
                '—',
              ),
            ),
            findsOneWidget,
            reason:
                'Refs #3093 — only the quantity-idle em-dash remains in '
                'an iron row when no trade order is staged. The price-'
                'slot em-dash must NOT appear for raw-resource commodities '
                'with a catalog default (regression guard against losing '
                'the catalog fallback).',
          );

          // The quantity-idle em-dash specifically lives under the
          // quantity readout key — keep this scoped pin so a future
          // regression that swaps the quantity glyph still surfaces a
          // readable failure.
          expect(
            find.byKey(
              TradeScreen.marketRowQuantityTextKey(CommodityCatalog.iron.id),
            ),
            findsOneWidget,
            reason:
                'Refs #2993 E5b — every commodity row exposes its '
                'quantity readout via the marketRowQuantityTextKey, '
                'including rows whose staged TradeOrder is empty (the '
                'idle em-dash glyph).',
          );

          // Manufactured commodity row (no catalog default today): the
          // em-dash glyph remains in the price slot until the commodity
          // participates in a market turn. This pins the explicit deferral
          // documented in `_formatPrice`.
          final lumberRow = find.byKey(
            TradeScreen.marketCommodityRowKey(CommodityCatalog.lumber.id),
          );
          expect(lumberRow, findsOneWidget);
          expect(
            find.descendant(
              of: lumberRow,
              matching: find.text(
                // ignore: avoid_hardcoded_strings_in_widgets
                '—',
              ),
            ),
            findsNWidgets(2),
            reason:
                'Refs #3093 — manufactured commodities are not enumerated '
                'in `ResourceRules.defaultMarketPrice`; their price slot '
                'continues to render the em-dash glyph (and the quantity-'
                'idle em-dash also renders when no TradeOrder is staged).',
          );
        },
      );

      testWidgets(
        'renders the previous-turn aggregate volume line `Bids X / Offers Y` '
        'from WorldMarketState.lastTurnActivity (with zero-default for '
        'commodities absent from the activity map)',
        (tester) async {
          await _pumpTradeScreen(
            tester,
            game: _buildGame(
              activity: const <CommodityId, MarketActivity>{
                'timber': MarketActivity(
                  totalBidQuantity: 12,
                  totalOfferQuantity: 8,
                ),
              },
            ),
          );

          final timberRow = find.byKey(
            TradeScreen.marketCommodityRowKey(CommodityCatalog.timber.id),
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
            TradeScreen.marketCommodityRowKey(CommodityCatalog.fabric.id),
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
          await _pumpTradeScreen(tester, game: _buildGame());

          // Sanity: Market tab body hosts the list and rows.
          expect(
            find.descendant(
              of: find.byKey(TradeScreen.marketTabBodyKey),
              matching: find.byKey(TradeScreen.marketCommodityListKey),
            ),
            findsOneWidget,
          );

          // The off-stage Deal Book body must not host any commodity row
          // — both off-stage and on-stage scopes.
          expect(
            find.descendant(
              of: find.byKey(
                TradeScreen.dealBookTabBodyKey,
                skipOffstage: false,
              ),
              matching: find.byKey(TradeScreen.marketCommodityListKey),
            ),
            findsNothing,
          );
        },
      );
    },
  );
}
