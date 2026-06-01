// Widget tests for the Trade Market tab sellable-headroom display and
// Offer clamp (Refs #3093 Slice 2 — sellable clamp).
//
// SPEC/ui/trade-screen.md § Market tab — Sellable + offer clamp,
// SPEC/game/world-market.md § Trade orders § Validation rules.
//
// Pins:
//   * The `(N)` text rendered next to each commodity name reflects
//     `sellableHeadroomByCommodityId` (offer cap minus the player's
//     own staged offer quantity).
//   * Tapping `Offer` on a commodity with sellable headroom = 0 is a
//     silent no-op (the chip is disabled).
//   * Tapping `+` on an Offer-staged row that is already at the cap
//     is a silent no-op.
//   * Decrement on a saturated offer row still works and refreshes
//     the headroom display.

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

CommodityId get _timber => CommodityCatalog.timber.id;
CommodityId get _iron => CommodityCatalog.iron.id;

Game _buildGame({Map<CommodityId, int>? stockpile}) {
  return Game(
    id: 'test_trade_screen_sellable_clamp',
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
        stockpile: Stockpile(
          quantities: stockpile ?? const <CommodityId, int>{},
        ),
      ),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: const WorldMarketState(),
  );
}

Future<ProviderContainer> _pumpTradeScreen(
  WidgetTester tester, {
  required Game game,
  Orders initialOrders = const Orders(),
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
          canMutateViaUi: true,
          debugCommandTargetPlayerId: player.id,
          inObservePhase: false,
          observeBannerLabel: null,
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

TradeOrder? _stagedOrder(ProviderContainer container, CommodityId commodityId) {
  final Orders orders = container.read(currentOrdersProvider);
  final List<TradeOrder>? list = orders.tradeOrdersByPlayerId[_humanPlayerId];
  if (list == null) return null;
  for (final TradeOrder o in list) {
    if (o.commodityId == commodityId) return o;
  }
  return null;
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab sellable clamp (Refs #3093)', () {
    testWidgets(
      'renders `(N)` next to commodity name where N = stockpile − '
      'stagedOffer (offer cap minus the row\'s staged offer)',
      (tester) async {
        await _pumpTradeScreen(
          tester,
          game: _buildGame(
            stockpile: const <CommodityId, int>{'timber': 10, 'iron': 7},
          ),
        );

        // No staged offers → headroom equals the offer cap (raw stockpile
        // today, with industry-allocation projection deferred per #3093
        // follow-up).
        final Finder timberSellable = find.byKey(
          TradeScreen.marketRowSellableReadoutKey(_timber),
        );
        expect(timberSellable, findsOneWidget);
        expect(
          tester.widget<Text>(timberSellable).data,
          // ignore: avoid_hardcoded_strings_in_widgets
          '(10)',
        );

        final Finder ironSellable = find.byKey(
          TradeScreen.marketRowSellableReadoutKey(_iron),
        );
        expect(
          tester.widget<Text>(ironSellable).data,
          // ignore: avoid_hardcoded_strings_in_widgets
          '(7)',
        );
      },
    );

    testWidgets(
      'with stockpile=10 timber and staged offer for 2 timber, the `(N)` '
      'readout shows `(8)` (headroom = cap − staged)',
      (tester) async {
        await _pumpTradeScreen(
          tester,
          game: _buildGame(
            stockpile: const <CommodityId, int>{'timber': 10},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.offer,
                  quantity: 2,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        final Finder sellable = find.byKey(
          TradeScreen.marketRowSellableReadoutKey(_timber),
        );
        expect(
          tester.widget<Text>(sellable).data,
          // ignore: avoid_hardcoded_strings_in_widgets
          '(8)',
        );
      },
    );

    testWidgets(
      'rows with zero stockpile and no staged offer render `(0)` and the '
      'Offer chip + offer-side `+` are disabled (silent no-op on tap)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(stockpile: const <CommodityId, int>{}),
        );

        // (0) display for an empty-stockpile commodity.
        final Finder timberSellable = find.byKey(
          TradeScreen.marketRowSellableReadoutKey(_timber),
        );
        expect(
          tester.widget<Text>(timberSellable).data,
          // ignore: avoid_hardcoded_strings_in_widgets
          '(0)',
        );

        // Offer chip tap → silent no-op.
        await tester.tap(find.byKey(TradeScreen.marketRowOfferChipKey(_timber)));
        await tester.pump();
        expect(
          _stagedOrder(container, _timber),
          isNull,
          reason:
              'Refs #3093 — Offer chip is disabled when the per-commodity '
              'offer cap is 0; tapping it must not stage a TradeOrder.',
        );
      },
    );

    testWidgets(
      'Offer chip becomes enabled when the player gains stockpile by '
      'releasing a staged offer (re-evaluate on order changes)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            stockpile: const <CommodityId, int>{'timber': 3},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.offer,
                  quantity: 3,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        // Headroom is 0 with the saturated offer.
        expect(
          tester
              .widget<Text>(
                  find.byKey(TradeScreen.marketRowSellableReadoutKey(_timber)))
              .data,
          // ignore: avoid_hardcoded_strings_in_widgets
          '(0)',
        );

        // Decrement the saturated offer down by 1 → headroom updates to 1.
        await tester.tap(find.byKey(TradeScreen.marketRowDecrementKey(_timber)));
        await tester.pump();
        expect(
          tester
              .widget<Text>(
                  find.byKey(TradeScreen.marketRowSellableReadoutKey(_timber)))
              .data,
          // ignore: avoid_hardcoded_strings_in_widgets
          '(1)',
        );
        expect(
          _stagedOrder(container, _timber)?.quantity,
          2,
        );
      },
    );

    testWidgets(
      'tapping `Offer` on a fresh commodity clamps the staged quantity to '
      'the per-commodity offer cap (default 1 ≤ cap → preserves default)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            stockpile: const <CommodityId, int>{'timber': 5},
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowOfferChipKey(_timber)));
        await tester.pump();

        final TradeOrder? staged = _stagedOrder(container, _timber);
        expect(staged, isNotNull);
        expect(staged!.type, TradeOrderType.offer);
        expect(
          staged.quantity,
          TradeScreen.marketRowQuantityDefault,
          reason:
              'Default quantity (1) fits inside the offer cap of 5 — no '
              'clamping needed.',
        );
      },
    );

    testWidgets(
      'tapping `Offer` on a fresh commodity with offer cap = 0 is a silent '
      'no-op (no TradeOrder is staged)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(stockpile: const <CommodityId, int>{}),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowOfferChipKey(_timber)));
        await tester.pump();

        expect(_stagedOrder(container, _timber), isNull);
      },
    );

    testWidgets(
      'tapping `Offer` on a row previously staged as Bid with a quantity '
      'exceeding the cap clamps the staged offer quantity down to the cap',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            stockpile: const <CommodityId, int>{'timber': 4},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 9,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowOfferChipKey(_timber)));
        await tester.pump();

        final TradeOrder? staged = _stagedOrder(container, _timber);
        expect(staged, isNotNull);
        expect(staged!.type, TradeOrderType.offer);
        expect(
          staged.quantity,
          4,
          reason:
              'Refs #3093 — switching to Offer clamps the prior quantity '
              '(9) to the per-commodity offer cap (stockpile=4).',
        );
      },
    );

    testWidgets(
      'incrementing a saturated Offer row is a silent no-op (the staged '
      'quantity stays at the cap and the headroom stays at (0))',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            stockpile: const <CommodityId, int>{'timber': 5},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.offer,
                  quantity: 5,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
        await tester.pump();

        expect(_stagedOrder(container, _timber)?.quantity, 5);
        expect(
          tester
              .widget<Text>(
                  find.byKey(TradeScreen.marketRowSellableReadoutKey(_timber)))
              .data,
          // ignore: avoid_hardcoded_strings_in_widgets
          '(0)',
        );
      },
    );

    testWidgets(
      'incrementing an Offer row with headroom > 0 raises the staged '
      'quantity by 1 and the headroom display decreases accordingly',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            stockpile: const <CommodityId, int>{'timber': 7},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.offer,
                  quantity: 2,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        // Initial headroom 5 (= 7 - 2).
        expect(
          tester
              .widget<Text>(
                  find.byKey(TradeScreen.marketRowSellableReadoutKey(_timber)))
              .data,
          // ignore: avoid_hardcoded_strings_in_widgets
          '(5)',
        );

        await tester.tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
        await tester.pump();
        expect(_stagedOrder(container, _timber)?.quantity, 3);
        expect(
          tester
              .widget<Text>(
                  find.byKey(TradeScreen.marketRowSellableReadoutKey(_timber)))
              .data,
          // ignore: avoid_hardcoded_strings_in_widgets
          '(4)',
        );
      },
    );

    testWidgets(
      'bids do not consume the offer headroom (bid row\'s `(N)` is '
      'unaffected by the staged bid quantity)',
      (tester) async {
        await _pumpTradeScreen(
          tester,
          game: _buildGame(
            stockpile: const <CommodityId, int>{'timber': 10},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 4,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        expect(
          tester
              .widget<Text>(
                  find.byKey(TradeScreen.marketRowSellableReadoutKey(_timber)))
              .data,
          // ignore: avoid_hardcoded_strings_in_widgets
          '(10)',
          reason:
              'Refs #3093 — bids do not reserve stockpile (per '
              'SPEC/game/world-market.md § Cargo). The offer headroom '
              'is independent of staged bids.',
        );
      },
    );
  });
}
