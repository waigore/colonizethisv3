// Widget tests for the Trade Market tab treasury bid cap (Refs #3093 —
// treasury bid budget slice).
//
// SPEC/ui/trade-screen.md § Market tab — treasury bid cap,
// SPEC/game/world-market.md § Treasury budget for bids.
//
// Pins:
//   * Toggling `Bid` on a row clamps the staged quantity to
//     `min(marketRowQuantityDefault, treasuryQuantityCap)`.
//   * Incrementing a staged Bid past the treasury budget is a silent
//     no-op (no mutation of `currentOrdersProvider`).
//   * Toggling `Bid` on a fresh row whose `treasuryHeadroom < rowPrice`
//     is a silent no-op.
//   * Toggling `Bid` on a row whose effective market price is null
//     (manufactured commodity without catalog default) is a silent
//     no-op.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/trade_screen.dart';
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const String _humanPlayerId = 'gp_h';

const CommodityId _timber = 'timber';
const CommodityId _iron = 'iron';
const CommodityId _lumber = 'lumber';

Game _buildGame({
  int treasury = 100,
  Map<CommodityId, int>? prices,
  Map<CommodityId, int>? stockpile,
}) {
  return Game(
    id: 'test_trade_screen_treasury_bid_cap',
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
        treasury: treasury,
        stockpile: Stockpile(
          quantities: stockpile ?? const <CommodityId, int>{},
        ),
      ),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: WorldMarketState(
      prices: prices ?? const <CommodityId, int>{},
    ),
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

  group('TradeScreen Market tab treasury bid cap (Refs #3093)', () {
    testWidgets(
      'treasury 100, timber price 30, no staged orders → tapping Bid stages '
      'a TradeOrder with quantity 1 (default fits inside the budget of 3)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 100,
            prices: const {_timber: 30},
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_timber)));
        await tester.pump();

        final TradeOrder? staged = _stagedOrder(container, _timber);
        expect(staged, isNotNull);
        expect(staged!.type, TradeOrderType.bid);
        expect(
          staged.quantity,
          TradeScreen.marketRowQuantityDefault,
          reason:
              'Treasury 100 / price 30 = 3 units of headroom; default '
              'staged qty 1 fits inside the budget.',
        );
      },
    );

    testWidgets(
      'treasury 100, timber price 30, staged Bid timber qty 3 → '
      'incrementing further is a silent no-op (budget saturated)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 100,
            prices: const {_timber: 30},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 3,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowIncrementKey(_timber)));
        await tester.pump();

        final TradeOrder? staged = _stagedOrder(container, _timber);
        expect(
          staged?.quantity,
          3,
          reason:
              'Refs #3093 — total spend 4×30=120 exceeds treasury 100, so '
              'the `+` tap is a silent no-op.',
        );
      },
    );

    testWidgets(
      'treasury 100, staged Bid timber qty 3 (spend 90), iron price 80 → '
      'tapping the Bid chip on a fresh iron row is a silent no-op '
      '(headroom 10 < rowPrice 80)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 100,
            prices: const {_timber: 30, _iron: 80},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 3,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_iron)));
        await tester.pump();

        expect(
          _stagedOrder(container, _iron),
          isNull,
          reason:
              'Refs #3093 — treasury headroom 10 cannot cover iron price 80; '
              'toggle must be a silent no-op.',
        );
        expect(_stagedOrder(container, _timber)?.quantity, 3);
      },
    );

    testWidgets(
      'treasury 50, timber price 30, staged Offer timber qty 4 → '
      'tapping Bid clamps the staged bid quantity to treasury budget '
      '(min(4, 50 / 30) = min(4, 1) = 1)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 50,
            prices: const {_timber: 30},
            stockpile: const {_timber: 10},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.offer,
                  quantity: 4,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_timber)));
        await tester.pump();

        final TradeOrder? staged = _stagedOrder(container, _timber);
        expect(staged, isNotNull);
        expect(staged!.type, TradeOrderType.bid);
        expect(
          staged.quantity,
          1,
          reason:
              'Refs #3093 — prior offer qty 4 is clamped down to treasury '
              'budget 50 / 30 = 1 when toggling Offer → Bid.',
        );
      },
    );

    testWidgets(
      'treasury 100, price map omits commodity and catalog default is also '
      'null (manufactured `lumber`) → Bid toggle stages a TradeOrder under '
      'the cargo cap only (treasury clamp skipped)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 100,
            prices: const <CommodityId, int>{},
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowBidChipKey(_lumber)));
        await tester.pump();

        final TradeOrder? staged = _stagedOrder(container, _lumber);
        expect(
          staged,
          isNotNull,
          reason:
              'Refs #3093 — when rowPrice is null (manufactured commodity, '
              'no catalog default), the treasury clamp is skipped so the '
              'cargo cap is the only constraint on the bid toggle; the '
              'validator-side enforcement (follow-up) covers spend cases '
              'for unpriced commodities.',
        );
        expect(staged!.type, TradeOrderType.bid);
        expect(staged.quantity, TradeScreen.marketRowQuantityDefault);
      },
    );

    testWidgets(
      'treasury 100, timber price 30, staged Bid timber qty 2 → '
      'decrementing the staged bid still works (decrement is not gated by '
      'the treasury cap)',
      (tester) async {
        final ProviderContainer container = await _pumpTradeScreen(
          tester,
          game: _buildGame(
            treasury: 100,
            prices: const {_timber: 30},
          ),
          initialOrders: Orders(
            tradeOrdersByPlayerId: {
              _humanPlayerId: [
                TradeOrder(
                  commodityId: _timber,
                  type: TradeOrderType.bid,
                  quantity: 2,
                  priority: 1,
                ),
              ],
            },
          ),
        );

        await tester.tap(find.byKey(TradeScreen.marketRowDecrementKey(_timber)));
        await tester.pump();

        expect(_stagedOrder(container, _timber)?.quantity, 1);
      },
    );
  });
}
