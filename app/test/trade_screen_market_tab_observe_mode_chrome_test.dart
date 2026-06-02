// Widget tests for the Trade Market tab observe-mode chrome parity
// (Refs #3093 — observe-mode rendering parity slice).
//
// SPEC/ui/trade-screen.md § Market tab — observe-mode chrome parity
// (`#3093` slice).
//
// Issue context (Refs #3093 § Observe mode):
//   "Given `canMutateViaUi == false`, when Trade Market renders,
//    then grouping/icons/prices/stockpile still show and controls do
//    not mutate orders."
//
// The interaction-blocking half of that AC is already pinned by
// `trade_screen_market_tab_e5b_interactive_controls_test.dart`
// (chips + steppers mounted under `IgnorePointer` when
// `canMutateViaUi == false`). This file closes the verification gap
// on the chrome half — none of the existing slice tests assert that
// the `#3093`-era read-only surfaces (sectioned grouping, row icons,
// sellable readout, integer price text) remain mounted under observe
// mode, so a regression that hides the chrome under `IgnorePointer`
// would silently slip through CI.
//
// Pins (one positive AC per `#3093` chrome surface, plus one
// negative AC for the em-dash glyph):
//
//   * Sectioned grouping (Food / Raw Materials / Manufactured)
//     remains mounted — `TradeScreen.marketSectionFoodKey`,
//     `marketSectionRawMaterialsKey`,
//     `marketSectionManufacturedKey` each resolve to exactly one
//     widget when `canMutateViaUi == false`.
//   * Row icons (leading `ResourceIcon` 20 dp + trailing treasury
//     coin 14 dp) remain mounted on every tradeable row when
//     `canMutateViaUi == false` — `marketRowResourceIconKey(c.id)`
//     and `marketRowPriceCoinIconKey(c.id)` resolve to one widget
//     each per tradeable commodity.
//   * Sellable readout `(N)` remains mounted on every tradeable row
//     when `canMutateViaUi == false` — visible text equals the raw
//     stockpile quantity when no offers / reservations exist.
//   * Integer price text remains mounted under observe mode —
//     `worldMarketState.prices == {timber: 30}` renders the literal
//     `30` on the timber row.
//   * Every tradeable row's price column resolves to a finite
//     integer under observe mode — when `worldMarketState.prices`
//     omits a commodity (e.g. `iron`) the catalog default-price
//     fallback (`ResourceRules.defaultMarketPriceForCommodityId`)
//     supplies the row's published integer price (e.g. `iron == 80`)
//     so the em-dash glyph (`_MarketTabContent.priceUnknownGlyph` —
//     `—`) never paints in the price slot per `#3093`
//     (`SPEC/game/world-market.md` § Price discovery — "the catalog
//     default covers every tradeable commodity"). The quantity-idle
//     readout (`marketRowQuantityTextKey` rendering
//     `marketRowQuantityIdleGlyph` — `—` — when no direction is
//     staged) is orthogonal chrome and shares the same literal but
//     is not in scope for this pin.

import 'package:colonizethis_app/config/app_constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/trade_screen.dart';
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const String _humanPlayerId = 'gp_h';

CommodityId get _timber => CommodityCatalog.timber.id;

/// Builds a synthetic [Game] with one human player and a baseline
/// stockpile of 99 units for every tradeable commodity so the sellable
/// readout pin can assert `(99)` on the row under test without depending
/// on the in-game shell fixture.
///
/// [prices] feeds `WorldMarketState.prices` so the integer-price pin
/// can assert the timber row renders `30` under observe mode.
Game _buildGame({Map<CommodityId, int>? prices}) {
  final Map<CommodityId, int> stockpile = <CommodityId, int>{
    for (final Commodity c in CommodityCatalog.all)
      if (c.category != CommodityCategory.riches && c.id != 'spices') c.id: 99,
  };
  return Game(
    id: 'test_trade_screen_market_tab_observe_mode_chrome',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(
        id: _humanPlayerId,
        // ignore: avoid_hardcoded_strings_in_widgets
        displayName: 'England',
        isHuman: true,
        treasury: 500,
        stockpile: Stockpile(quantities: stockpile),
      ),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: WorldMarketState(
      prices: prices ?? const <CommodityId, int>{},
      lastTurnActivity: const <CommodityId, MarketActivity>{},
    ),
  );
}

/// Pumps [TradeScreen] under a [ProviderScope] whose
/// `shellPlayerContextProvider` is overridden to `canMutateViaUi: false`
/// (the per-GP observe variant — distinct from the `showPlayerChrome:
/// false` global-observe sentinel that swaps the body for
/// [ObserveModeNotDefinedPanel]). Uses a tall (1024 × 4096) surface so
/// every alphabetical row in the 22-commodity tradeable list lays out
/// inside the scroll view at once — mirrors the harness in
/// `trade_screen_market_tab_e5b_interactive_controls_test.dart`.
Future<void> _pumpTradeScreenObserveMode(
  WidgetTester tester, {
  required Game game,
}) async {
  final Player player = game.players.first;
  final ProviderContainer container = ProviderContainer(
    overrides: [
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
      shellPlayerContextProvider.overrideWith(
        (ref) => ShellPlayerContext(
          effectiveHumanPlayerId: player.id,
          viewingPlayerId: player.id,
          mapVisibilityMode: CtMapVisibilityMode.full,
          playerView: null,
          omniscientDetail: false,
          showPlayerChrome: true,
          canMutateViaUi: false,
          debugCommandTargetPlayerId: player.id,
          inObservePhase: true,
          // ignore: avoid_hardcoded_strings_in_widgets
          observeBannerLabel: 'Observing',
          treasuryNotDefined: false,
          cargoNotDefined: false,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.binding.setSurfaceSize(const Size(1024, 4096));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
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
    'TradeScreen Market tab observe-mode chrome parity (Refs #3093)',
    () {
      testWidgets(
        'sectioned grouping (Food / Raw Materials / Manufactured) '
        'remains mounted when canMutateViaUi == false',
        (tester) async {
          await _pumpTradeScreenObserveMode(tester, game: _buildGame());

          final marketTab = find.byKey(TradeScreen.marketTabBodyKey);
          expect(
            marketTab,
            findsOneWidget,
            reason:
                'Refs #3093 observe-mode chrome parity: the Market tab '
                'body must still mount under observe mode — the body is '
                'wrapped in IgnorePointer + Opacity but not removed '
                '(SPEC/ui/trade-screen.md § Body — Observe-mode).',
          );

          for (final Key sectionKey in <Key>[
            TradeScreen.marketSectionFoodKey,
            TradeScreen.marketSectionRawMaterialsKey,
            TradeScreen.marketSectionManufacturedKey,
          ]) {
            expect(
              find.descendant(of: marketTab, matching: find.byKey(sectionKey)),
              findsOneWidget,
              reason:
                  'Refs #3093 observe-mode chrome parity: the '
                  'sectioned grouping header keyed $sectionKey must '
                  'still mount when canMutateViaUi == false — section '
                  'labels are read-only chrome that never depends on '
                  'the player\'s ability to mutate orders.',
            );
          }
        },
      );

      testWidgets(
        'row icons (leading ResourceIcon 20 dp + trailing treasury '
        'coin 14 dp) remain mounted on every tradeable row when '
        'canMutateViaUi == false',
        (tester) async {
          await _pumpTradeScreenObserveMode(tester, game: _buildGame());

          final list = find.byKey(TradeScreen.marketCommodityListKey);
          expect(list, findsOneWidget);

          for (final Commodity c in CommodityCatalog.all) {
            if (c.category == CommodityCategory.riches || c.id == 'spices') {
              continue;
            }
            final iconFinder = find.descendant(
              of: list,
              matching: find.byKey(TradeScreen.marketRowResourceIconKey(c.id)),
            );
            expect(
              iconFinder,
              findsOneWidget,
              reason:
                  'Refs #3093 observe-mode chrome parity: tradeable '
                  'commodity `${c.id}` must still mount its '
                  'ResourceIcon under observe mode — row icons are '
                  'decorative chrome that never depends on '
                  'canMutateViaUi.',
            );
            final ResourceIcon icon = tester.widget<ResourceIcon>(iconFinder);
            expect(
              icon.size,
              TradeScreen.marketRowResourceIconSize,
              reason:
                  'Refs #3093 observe-mode chrome parity: leading '
                  'ResourceIcon on row `${c.id}` must paint at 20 dp '
                  'regardless of canMutateViaUi.',
            );

            final coinFinder = find.descendant(
              of: list,
              matching: find.byKey(TradeScreen.marketRowPriceCoinIconKey(c.id)),
            );
            expect(
              coinFinder,
              findsOneWidget,
              reason:
                  'Refs #3093 observe-mode chrome parity: tradeable '
                  'commodity `${c.id}` must still mount its trailing '
                  'treasury-coin StrictAssetIcon under observe mode.',
            );
            final StrictAssetIcon coin = tester.widget<StrictAssetIcon>(
              coinFinder,
            );
            expect(
              coin.assetPath,
              '${kAppIconAssetPrefix}ui_icon_treasury_coin.png',
              reason:
                  'Refs #3093 observe-mode chrome parity: trailing '
                  'coin glyph on row `${c.id}` must still reuse the '
                  'canonical treasury-coin asset under observe mode.',
            );
            expect(coin.width, TradeScreen.marketRowPriceCoinIconSize);
            expect(coin.height, TradeScreen.marketRowPriceCoinIconSize);
          }
        },
      );

      testWidgets(
        'sellable readout `(N)` remains mounted on every tradeable row '
        'when canMutateViaUi == false (N = raw stockpile when no '
        'offers / industry-allocation reservations exist)',
        (tester) async {
          await _pumpTradeScreenObserveMode(tester, game: _buildGame());

          final list = find.byKey(TradeScreen.marketCommodityListKey);
          expect(list, findsOneWidget);

          for (final Commodity c in CommodityCatalog.all) {
            if (c.category == CommodityCategory.riches || c.id == 'spices') {
              continue;
            }
            final sellableFinder = find.descendant(
              of: list,
              matching: find.byKey(
                TradeScreen.marketRowSellableReadoutKey(c.id),
              ),
            );
            expect(
              sellableFinder,
              findsOneWidget,
              reason:
                  'Refs #3093 observe-mode chrome parity: the sellable '
                  'readout for tradeable commodity `${c.id}` must '
                  'still mount under observe mode — the readout '
                  'reflects the player\'s stockpile / reservation '
                  'state regardless of canMutateViaUi.',
            );
            final Text sellable = tester.widget<Text>(sellableFinder);
            expect(
              sellable.data,
              // ignore: avoid_hardcoded_strings_in_widgets
              '(99)',
              reason:
                  'Refs #3093 observe-mode chrome parity: with raw '
                  'stockpile 99, no staged offers, and no '
                  'industry-allocation reservations, the sellable '
                  'readout for `${c.id}` must render the literal '
                  '`(99)` under observe mode.',
            );
          }
        },
      );

      testWidgets(
        'integer price text remains mounted under observe mode — '
        'worldMarketState.prices == {timber: 30} renders the literal '
        '`30` on the timber row',
        (tester) async {
          await _pumpTradeScreenObserveMode(
            tester,
            game: _buildGame(
              prices: const <CommodityId, int>{'timber': 30},
            ),
          );

          final timberRow = find.byKey(
            TradeScreen.marketCommodityRowKey(_timber),
          );
          expect(timberRow, findsOneWidget);
          expect(
            find.descendant(
              of: timberRow,
              // ignore: avoid_hardcoded_strings_in_widgets
              matching: find.text('30'),
            ),
            findsOneWidget,
            reason:
                'Refs #3093 observe-mode chrome parity: the integer '
                'price text rendered by `_formatPrice` must still '
                'mount under observe mode — integer-price chrome is '
                'read-only and never depends on canMutateViaUi.',
          );
        },
      );

      testWidgets(
        'catalog default-price fallback resolves under observe mode — '
        'iron row (price absent from worldMarketState.prices) renders '
        'the integer catalog default `80` immediately to the right of '
        'the row treasury-coin glyph (no em-dash in the price slot)',
        (tester) async {
          // worldMarketState.prices is intentionally empty here so the
          // row must fall back to ResourceRules.defaultMarketPriceForCommodityId
          // for every tradeable commodity. The negative pin uses iron
          // (catalog default = 80 per ResourceRules.defaultRules) so a
          // regression that drops the catalog fallback under observe
          // mode surfaces as the em-dash glyph appearing in the price
          // slot instead of the integer literal `80`.
          await _pumpTradeScreenObserveMode(tester, game: _buildGame());

          final ironRow = find.byKey(
            TradeScreen.marketCommodityRowKey(CommodityCatalog.iron.id),
          );
          expect(ironRow, findsOneWidget);

          expect(
            find.descendant(
              of: ironRow,
              // ignore: avoid_hardcoded_strings_in_widgets
              matching: find.text('80'),
            ),
            findsOneWidget,
            reason:
                'Refs #3093 observe-mode chrome parity: with '
                'worldMarketState.prices empty, the iron row must '
                'still render the published catalog default price `80` '
                'under observe mode (ResourceRules.defaultRules '
                'covers every tradeable commodity per '
                'SPEC/game/world-market.md § Price discovery). The '
                'em-dash glyph must never paint in the price slot.',
          );

          // The coin glyph mounts to the immediate left of the price
          // text, so pinning the spatial relationship under observe
          // mode guards against a regression that hides the coin or
          // the integer price specifically on the observed surface.
          final coinRect = tester.getRect(
            find.byKey(
              TradeScreen.marketRowPriceCoinIconKey(CommodityCatalog.iron.id),
            ),
          );
          final priceRect = tester.getRect(
            find.descendant(
              of: ironRow,
              // ignore: avoid_hardcoded_strings_in_widgets
              matching: find.text('80'),
            ),
          );
          expect(
            coinRect.right,
            lessThanOrEqualTo(priceRect.left),
            reason:
                'Refs #3093 observe-mode chrome parity: the trailing '
                'treasury-coin glyph must still paint immediately to '
                'the left of the integer price text under observe '
                'mode (Refs #3093 § Market tab — row icons).',
          );
        },
      );
    },
  );
}
