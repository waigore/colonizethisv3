// Widget tests for the Market tab interactive bid/offer/quantity
// controls (Refs #2993 E5b). SPEC/ui/trade-screen.md § Body — Market
// tab interactive controls.
//
// Exercises the durable contract for the per-row interactive controls:
//
//  * `None` / `Bid` / `Offer` direction selector is keyed per
//    commodity (`marketRowNoneChipKey` / `marketRowBidChipKey` /
//    `marketRowOfferChipKey`),
//  * Tapping `Bid` stages a `TradeOrder(type: bid, quantity: 1,
//    priority: 1)` for the row's commodity in `currentOrdersProvider`,
//  * Tapping `Offer` on a row that already has a staged bid REPLACES
//    the prior order (mutual exclusion: at most one staged TradeOrder
//    per (player, commodityId)),
//  * Tapping `None` removes any staged order for the commodity,
//  * Quantity stepper `+` / `−` adjusts `TradeOrder.quantity` in
//    steps of 1, clamped at the lower bound `marketRowQuantityMin` (1)
//    while a direction is selected,
//  * Decrement is disabled at the lower bound (no further decrement),
//  * Stepper buttons and direction chips are non-interactive when
//    `canMutateViaUi == false` (observe variant) — controls render but
//    taps do not mutate `currentOrdersProvider`.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/trade_screen.dart';
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const String _humanPlayerId = 'gp_h';

Game _buildGame() {
  // Refs #3093 — sellable clamp slice. The Offer chip + offer-side
  // `+` are now gated by the per-commodity offer cap
  // (`stockpile − industryAllocation`). Seed a baseline stockpile of
  // 99 units for every tradeable commodity so the E5b interactive-
  // control tests (which stage Offer orders without specifying
  // stockpile) keep passing under the new contract.
  final Map<CommodityId, int> stockpile = <CommodityId, int>{
    for (final Commodity c in CommodityCatalog.all)
      if (c.category != CommodityCategory.riches && c.id != 'spices') c.id: 99,
  };
  return Game(
    id: 'test_trade_screen_e5b',
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
    worldMarketState: const WorldMarketState(),
  );
}

/// Pumps the [TradeScreen] in isolation under a [ProviderScope] that
/// exposes [currentGameProvider], [currentOrdersProvider], and a
/// (mockable) [shellPlayerContextProvider]. Mirrors the harness used
/// by the E5a commodity-table tests so the assertions can pin the
/// Market tab body without the full in-game shell.
///
/// Uses a tall (1024 × 4096) test viewport so every alphabetical row
/// in the 22-commodity tradeable list is laid out inside the scroll
/// view at once — `tester.tap` resolves to a visible target without
/// the test having to scroll the list. Mirrors the pattern used by
/// `production_screen_top_bar_test.dart` for similarly long lists.
Future<ProviderContainer> _pumpTradeScreen(
  WidgetTester tester, {
  required Game game,
  Orders initialOrders = const Orders(),
  bool canMutateViaUi = true,
}) async {
  final Player player = game.players.first;
  final ProviderContainer container = ProviderContainer(
    overrides: [
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(initialOrders),
      ),
      shellPlayerContextProvider.overrideWith(
        (ref) => ShellPlayerContext(
          effectiveHumanPlayerId: player.id,
          viewingPlayerId: player.id,
          mapVisibilityMode: CtMapVisibilityMode.full,
          playerView: null,
          omniscientDetail: false,
          showPlayerChrome: true,
          canMutateViaUi: canMutateViaUi,
          debugCommandTargetPlayerId: player.id,
          inObservePhase: !canMutateViaUi,
          observeBannerLabel: canMutateViaUi ? null : 'Observing',
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
  return container;
}

CommodityId get _timber => CommodityCatalog.timber.id;
CommodityId get _fabric => CommodityCatalog.fabric.id;

TradeOrder? _stagedOrder(
  ProviderContainer container,
  CommodityId commodityId,
) {
  final Orders orders = container.read(currentOrdersProvider);
  final List<TradeOrder>? list =
      orders.tradeOrdersByPlayerId[_humanPlayerId];
  if (list == null) return null;
  for (final TradeOrder o in list) {
    if (o.commodityId == commodityId) return o;
  }
  return null;
}

void main() {
  suppressLogsForTests();

  group(
    'TradeScreen Market tab interactive controls (Refs #2993 E5b)',
    () {
      testWidgets(
        'every tradeable row exposes None / Bid / Offer chips and the '
        '`+` / quantity / `−` stepper widgets keyed per commodity',
        (tester) async {
          await _pumpTradeScreen(tester, game: _buildGame());

          for (final Commodity c in CommodityCatalog.all) {
            if (c.category == CommodityCategory.riches || c.id == 'spices') {
              continue;
            }
            final row = find.byKey(TradeScreen.marketCommodityRowKey(c.id));
            expect(row, findsOneWidget);
            expect(
              find.descendant(
                of: row,
                matching: find.byKey(TradeScreen.marketRowNoneChipKey(c.id)),
              ),
              findsOneWidget,
              reason: 'commodity `${c.id}` row must mount its `None` chip.',
            );
            expect(
              find.descendant(
                of: row,
                matching: find.byKey(TradeScreen.marketRowBidChipKey(c.id)),
              ),
              findsOneWidget,
              reason: 'commodity `${c.id}` row must mount its `Bid` chip.',
            );
            expect(
              find.descendant(
                of: row,
                matching: find.byKey(TradeScreen.marketRowOfferChipKey(c.id)),
              ),
              findsOneWidget,
              reason: 'commodity `${c.id}` row must mount its `Offer` chip.',
            );
            expect(
              find.descendant(
                of: row,
                matching:
                    find.byKey(TradeScreen.marketRowDecrementKey(c.id)),
              ),
              findsOneWidget,
              reason:
                  'commodity `${c.id}` row must mount its decrement button.',
            );
            expect(
              find.descendant(
                of: row,
                matching:
                    find.byKey(TradeScreen.marketRowIncrementKey(c.id)),
              ),
              findsOneWidget,
              reason:
                  'commodity `${c.id}` row must mount its increment button.',
            );
            expect(
              find.descendant(
                of: row,
                matching:
                    find.byKey(TradeScreen.marketRowQuantityTextKey(c.id)),
              ),
              findsOneWidget,
              reason:
                  'commodity `${c.id}` row must mount its quantity readout.',
            );
          }
        },
      );

      testWidgets(
        'tapping `Bid` on an unstaged row stages a TradeOrder with '
        'type=bid, quantity=1, priority=1 in currentOrdersProvider',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(),
          );
          expect(_stagedOrder(container, _timber), isNull);

          await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_timber)));
          await tester.pump();

          final TradeOrder? staged = _stagedOrder(container, _timber);
          expect(staged, isNotNull);
          expect(staged!.commodityId, _timber);
          expect(staged.type, TradeOrderType.bid);
          expect(
            staged.quantity,
            TradeScreen.marketRowQuantityDefault,
            reason:
                'Refs #2993 E5b: a freshly toggled Bid stages '
                'quantity=1 (the stepper minimum). Subsequent + taps '
                'increment from there.',
          );
          expect(
            staged.priority,
            TradeScreen.marketRowDefaultPriority,
            reason:
                'Refs #2993 E5b: priority defaults to 1 until the '
                'priority dropdown ships in a follow-up slice.',
          );
        },
      );

      testWidgets(
        'tapping `Offer` on a row that already has a staged bid '
        'REPLACES the prior bid (mutual exclusion: at most one staged '
        'TradeOrder per commodity)',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(),
          );

          await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_timber)));
          await tester.pump();
          await tester.tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
          await tester.pump();
          // After Bid + one increment: timber bid, quantity=2.
          TradeOrder? staged = _stagedOrder(container, _timber);
          expect(staged, isNotNull);
          expect(staged!.type, TradeOrderType.bid);
          expect(staged.quantity, 2);

          // Toggle to Offer: the prior bid must be replaced by an
          // offer. Quantity is preserved (2) since it tracks the
          // staged direction's quantity.
          await tester
              .tap(find.byKey(TradeScreen.marketRowOfferChipKey(_timber)));
          await tester.pump();
          staged = _stagedOrder(container, _timber);
          expect(staged, isNotNull);
          expect(staged!.type, TradeOrderType.offer);
          expect(staged.quantity, 2);

          // Mutual exclusion: list contains at most one staged
          // TradeOrder for the timber commodity.
          final Orders orders = container.read(currentOrdersProvider);
          final List<TradeOrder>? list =
              orders.tradeOrdersByPlayerId[_humanPlayerId];
          expect(list, isNotNull);
          final int timberCount =
              list!.where((TradeOrder o) => o.commodityId == _timber).length;
          expect(
            timberCount,
            1,
            reason:
                'Refs #2993 E5b mutual exclusion: tradeOrdersByPlayerId '
                'must contain at most one TradeOrder per (player, '
                'commodityId) pair.',
          );
        },
      );

      testWidgets(
        'tapping `None` on a row with a staged direction removes the '
        'TradeOrder for the commodity from currentOrdersProvider',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(),
          );
          await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_timber)));
          await tester.pump();
          expect(_stagedOrder(container, _timber), isNotNull);

          await tester.tap(find.byKey(TradeScreen.marketRowNoneChipKey(_timber)));
          await tester.pump();
          expect(
            _stagedOrder(container, _timber),
            isNull,
            reason:
                'Refs #2993 E5b: tapping the None chip removes the '
                'staged TradeOrder for the row\'s commodity.',
          );
        },
      );

      testWidgets(
        '`+` increments quantity by 1 and `−` decrements by 1 (clamped '
        'at marketRowQuantityMin = 1 when a direction is staged)',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(),
          );
          await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_timber)));
          await tester.pump();
          // Initial quantity: 1.
          expect(_stagedOrder(container, _timber)!.quantity, 1);

          // + → 2 → 3 → 4
          await tester.tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
          await tester.pump();
          await tester.tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
          await tester.pump();
          await tester.tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
          await tester.pump();
          expect(_stagedOrder(container, _timber)!.quantity, 4);

          // − → 3 → 2 → 1
          await tester.tap(find.byKey(TradeScreen.marketRowDecrementKey(_timber)));
          await tester.pump();
          await tester.tap(find.byKey(TradeScreen.marketRowDecrementKey(_timber)));
          await tester.pump();
          await tester.tap(find.byKey(TradeScreen.marketRowDecrementKey(_timber)));
          await tester.pump();
          expect(_stagedOrder(container, _timber)!.quantity, 1);

          // Further − is a no-op (clamped at the lower bound of 1).
          await tester.tap(find.byKey(TradeScreen.marketRowDecrementKey(_timber)));
          await tester.pump();
          expect(
            _stagedOrder(container, _timber)!.quantity,
            TradeScreen.marketRowQuantityMin,
            reason:
                'Refs #2993 E5b: the per-row stepper clamps at '
                '`marketRowQuantityMin = 1` while a direction is '
                'staged (going below 1 is equivalent to None and is '
                'reached via the None chip, not the decrement button).',
          );
        },
      );

      testWidgets(
        'increment / decrement buttons are no-ops while no direction is '
        'staged (the `−` and `+` taps must not create a TradeOrder)',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(),
          );
          // No staged direction yet — increment must NOT auto-stage a
          // bid/offer. The +/- buttons only operate on already-staged
          // TradeOrders. The user must pick a direction first.
          await tester.tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
          await tester.pump();
          await tester.tap(find.byKey(TradeScreen.marketRowDecrementKey(_timber)));
          await tester.pump();
          expect(
            _stagedOrder(container, _timber),
            isNull,
            reason:
                'Refs #2993 E5b: stepper taps without a staged '
                'direction are silent no-ops (the user picks Bid / '
                'Offer first; the stepper then adjusts the staged '
                'TradeOrder.quantity).',
          );
        },
      );

      testWidgets(
        'mutual exclusion across distinct commodities — staging timber '
        'as Bid and fabric as Offer keeps both as a single TradeOrder '
        'each in currentOrdersProvider',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(),
          );
          await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_timber)));
          await tester.pump();
          await tester.tap(find.byKey(TradeScreen.marketRowOfferChipKey(_fabric)));
          await tester.pump();

          expect(_stagedOrder(container, _timber)?.type,
              TradeOrderType.bid);
          expect(_stagedOrder(container, _fabric)?.type,
              TradeOrderType.offer);
          final Orders orders = container.read(currentOrdersProvider);
          expect(
            orders.tradeOrdersByPlayerId[_humanPlayerId]?.length,
            2,
            reason:
                'Refs #2993 E5b: the player can stage one TradeOrder '
                'per commodity simultaneously; mutual exclusion is '
                'per-commodity, not per-player.',
          );
        },
      );

      testWidgets(
        'observe variant (canMutateViaUi == false): direction chips and '
        'stepper taps do NOT mutate currentOrdersProvider — the table '
        'reads as read-only',
        (tester) async {
          final ProviderContainer container = await _pumpTradeScreen(
            tester,
            game: _buildGame(),
            canMutateViaUi: false,
          );

          await tester.tap(
            find.byKey(TradeScreen.marketRowBidChipKey(_timber)),
            warnIfMissed: false,
          );
          await tester.pump();
          await tester.tap(
            find.byKey(TradeScreen.marketRowIncrementKey(_timber)),
            warnIfMissed: false,
          );
          await tester.pump();

          expect(
            _stagedOrder(container, _timber),
            isNull,
            reason:
                'Refs #2993 E5b observe variant: when '
                'canMutateViaUi == false, the Market tab body is '
                'wrapped in IgnorePointer so the controls are visible '
                'but not interactive — taps do not stage trade '
                'orders.',
          );
        },
      );

      testWidgets(
        'observe variant still mounts the row controls and quantity '
        'readout (the chrome remains visible — only interaction is '
        'blocked, matching the Production screen pattern)',
        (tester) async {
          await _pumpTradeScreen(
            tester,
            game: _buildGame(),
            canMutateViaUi: false,
          );

          final timberRow = find.byKey(
            TradeScreen.marketCommodityRowKey(_timber),
          );
          expect(
            find.descendant(
              of: timberRow,
              matching: find.byKey(TradeScreen.marketRowNoneChipKey(_timber)),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: timberRow,
              matching: find.byKey(TradeScreen.marketRowQuantityTextKey(_timber)),
            ),
            findsOneWidget,
          );
        },
      );
    },
  );
}
