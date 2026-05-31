// Widget tests for the Market tab read-only commodity table
// (Refs #2993 E5a). SPEC/ui/trade-screen.md § Body — Market tab.
//
// Exercises the durable contract for the Market tab body:
//
//  * one row per tradeable commodity (full CommodityCatalog minus
//    riches and `spices` — 22 rows total per SPEC/game/world-market.md
//    §Tradeable commodities),
//  * deterministic alphabetical sort by display name so widget tests
//    and Widgetbook stories pin the same ordering,
//  * last market price sourced from `Game.worldMarketState.prices`
//    (rendered as the em-dash glyph `—` when the commodity is absent
//    from the map — typically only seen in tests / Widgetbook stories
//    that instantiate `WorldMarketState.empty`),
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
  Map<CommodityId, double>? prices,
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
      prices: prices ?? const <CommodityId, double>{},
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
        'rows are sorted alphabetically by display name (case-insensitive) '
        '— deterministic order pin',
        (tester) async {
          await _pumpTradeScreen(tester, game: _buildGame());

          final List<Commodity> tradeable = <Commodity>[
            for (final Commodity c in CommodityCatalog.all)
              if (c.category != CommodityCategory.riches && c.id != 'spices') c,
          ];
          final List<Commodity> expectedOrder = List<Commodity>.of(tradeable)
            ..sort((Commodity a, Commodity b) {
              final String an = (a.displayName ?? a.id).toLowerCase();
              final String bn = (b.displayName ?? b.id).toLowerCase();
              return an.compareTo(bn);
            });

          final List<Offset> positions = <Offset>[
            for (final Commodity c in expectedOrder)
              tester.getTopLeft(
                find.byKey(TradeScreen.marketCommodityRowKey(c.id)),
              ),
          ];

          for (int i = 1; i < positions.length; i++) {
            expect(
              positions[i].dy,
              greaterThan(positions[i - 1].dy),
              reason:
                  'Row `${expectedOrder[i].id}` must appear below row '
                  '`${expectedOrder[i - 1].id}` (alphabetical by display '
                  'name, case-insensitive).',
            );
          }

          // Concrete spot-check: `Cast iron` precedes `Cigars` precedes
          // `Coal` (deterministic alphabetical pin so a regression in
          // the comparator surfaces with a readable failure).
          final castIron = tester.getTopLeft(
            find.byKey(
              TradeScreen.marketCommodityRowKey(CommodityCatalog.castIron.id),
            ),
          );
          final cigars = tester.getTopLeft(
            find.byKey(
              TradeScreen.marketCommodityRowKey(CommodityCatalog.cigars.id),
            ),
          );
          final coal = tester.getTopLeft(
            find.byKey(
              TradeScreen.marketCommodityRowKey(CommodityCatalog.coal.id),
            ),
          );
          expect(castIron.dy, lessThan(cigars.dy));
          expect(cigars.dy, lessThan(coal.dy));
        },
      );

      testWidgets(
        'renders the live `WorldMarketState.prices` price for a seeded '
        'commodity (timber=30.0 → `30.0`) and the em-dash glyph for an '
        'unseeded commodity (iron, absent from the prices map)',
        (tester) async {
          await _pumpTradeScreen(
            tester,
            game: _buildGame(
              prices: const <CommodityId, double>{'timber': 30.0},
            ),
          );

          // Seeded commodity row shows the formatted price text.
          final timberRow = find.byKey(
            TradeScreen.marketCommodityRowKey(CommodityCatalog.timber.id),
          );
          expect(timberRow, findsOneWidget);
          expect(
            find.descendant(of: timberRow, matching: find.text('30.0')),
            findsOneWidget,
            reason:
                'SPEC/ui/trade-screen.md § Body — Market tab: the price '
                'cell reads `Game.worldMarketState.prices[commodityId]` '
                'formatted to one decimal place.',
          );

          // Unseeded commodity row shows the canonical em-dash glyph.
          final ironRow = find.byKey(
            TradeScreen.marketCommodityRowKey(CommodityCatalog.iron.id),
          );
          expect(ironRow, findsOneWidget);
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
                'SPEC/ui/trade-screen.md § Body — Market tab: rows for '
                'commodities absent from `WorldMarketState.prices` show '
                'the em-dash glyph as the price-unknown sentinel.',
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
