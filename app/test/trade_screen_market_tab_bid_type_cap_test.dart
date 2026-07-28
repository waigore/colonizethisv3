// Widget tests for the Trade Market tab bid-type slot indicator and gate
// (Refs #4170).
//
// SPEC/ui/trade-screen.md § Market tab — bid-type cap.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

const String _humanPlayerId = kTradeTestHumanPlayerId;

const CommodityId _timber = 'timber';
const CommodityId _iron = 'iron';
const CommodityId _grain = 'grain';

Orders _orders(List<TradeOrder> tradeOrders) {
  return Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      _humanPlayerId: tradeOrders,
    },
  );
}

TradeOrder _bid(CommodityId commodityId, int quantity) {
  return TradeOrder(
    commodityId: commodityId,
    type: TradeOrderType.bid,
    quantity: quantity,
    priority: 1,
  );
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

String _bidGoodsIndicatorText(WidgetTester tester) {
  final Text widget = tester.widget<Text>(
    find.byKey(TradeScreenMarketKeys.marketBidGoodsIndicatorKey),
  );
  return widget.data!;
}

Finder _bidChip(CommodityId commodityId) {
  return find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(commodityId));
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab bid-type cap (Refs #4170)', () {
    testWidgets(
      'no embassy (cap 1) with zero staged bids → indicator reads Bid goods: 0 of 1',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(prices: const {_timber: 30}),
        );

        expect(_bidGoodsIndicatorText(tester), 'Bid goods: 0 of 1');
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidTypeWarningKey),
          findsNothing,
        );
      },
    );

    testWidgets(
      'cap 1 with staged bid on timber → indicator reads Bid goods: 1 of 1 '
      'and warning mounts',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(prices: const {_timber: 30}),
          initialOrders: _orders([_bid(_timber, 1)]),
        );

        expect(_bidGoodsIndicatorText(tester), 'Bid goods: 1 of 1');
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidTypeWarningKey),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'cap 1 saturated → fresh iron Bid is a silent no-op and chip is disabled',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            prices: const {_timber: 30, _iron: 80},
            stockpile: tradeableStockpileFilled(50),
          ),
          initialOrders: _orders([_bid(_timber, 1)]),
        );

        final CtChoiceChip ironBidChip = tester.widget<CtChoiceChip>(
          _bidChip(_iron),
        );
        expect(ironBidChip.onSelected, isNull);

        await tester.tap(_bidChip(_iron));
        await tester.pump();

        expect(_stagedOrder(container, _iron), isNull);
        expect(_bidGoodsIndicatorText(tester), 'Bid goods: 1 of 1');
      },
    );

    testWidgets(
      'cap 1 saturated → timber bid row stays editable (increment allowed)',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            prices: const {_timber: 30},
            tradeCargoCapacityOverride: 10,
          ),
          initialOrders: _orders([_bid(_timber, 1)]),
        );

        final CtChoiceChip timberBidChip = tester.widget<CtChoiceChip>(
          _bidChip(_timber),
        );
        expect(timberBidChip.onSelected, isNotNull);

        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(_timber)),
        );
        await tester.pump();

        expect(_stagedOrder(container, _timber)?.quantity, 2);
      },
    );

    testWidgets(
      'offers do not consume bid-goods slots',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            prices: const {_timber: 30, _iron: 80},
            stockpile: tradeableStockpileFilled(50),
          ),
          initialOrders: _orders([
            TradeOrder(
              commodityId: _timber,
              type: TradeOrderType.offer,
              quantity: 2,
              priority: 1,
            ),
          ]),
        );

        expect(_bidGoodsIndicatorText(tester), 'Bid goods: 0 of 1');
      },
    );

    testWidgets(
      'setting bid to None frees a slot immediately on the indicator',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(prices: const {_timber: 30, _iron: 80}),
          initialOrders: _orders([_bid(_timber, 1)]),
        );

        expect(_bidGoodsIndicatorText(tester), 'Bid goods: 1 of 1');

        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketRowNoneChipKey(_timber)),
        );
        await tester.pump();

        expect(_stagedOrder(container, _timber), isNull);
        expect(_bidGoodsIndicatorText(tester), 'Bid goods: 0 of 1');
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidTypeWarningKey),
          findsNothing,
        );
      },
    );

    testWidgets(
      'embassy without Trade Fairs → cap 3 reflected in indicator',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            prices: const {_timber: 30, _iron: 80, _grain: 50},
            overtureStates: const <OvertureState>[
              OvertureState(
                gpId: _humanPlayerId,
                targetId: 'minor1',
                stage: OvertureStage.embassy,
              ),
            ],
          ),
          initialOrders: _orders([
            _bid(_timber, 1),
            _bid(_iron, 1),
          ]),
        );

        expect(_bidGoodsIndicatorText(tester), 'Bid goods: 2 of 3');
      },
    );

    testWidgets(
      'embassy + Trade Fairs → cap 6 reflected in indicator',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            techUnlocked: const <String, bool>{kTechIdTradeFairs: true},
            overtureStates: const <OvertureState>[
              OvertureState(
                gpId: _humanPlayerId,
                targetId: 'minor1',
                stage: OvertureStage.embassy,
              ),
            ],
          ),
        );

        expect(_bidGoodsIndicatorText(tester), 'Bid goods: 0 of 6');
      },
    );

    testWidgets(
      'Why this limit? expands plain-language copy for cap 1',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(),
        );

        expect(
          find.byKey(TradeScreenMarketKeys.marketBidTypeWhyBodyKey),
          findsNothing,
        );

        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketBidTypeWhyToggleKey),
        );
        await tester.pump();

        expect(
          find.byKey(TradeScreenMarketKeys.marketBidTypeWhyBodyKey),
          findsOneWidget,
        );
        expect(
          find.text(TradeScreenMarketKeys.bidTypeWhyLimitCopyCap1),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'observe mode → bid-goods indicator live; bid chip taps do not mutate',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(prices: const {_timber: 30}),
          canMutateViaUi: false,
        );

        expect(_bidGoodsIndicatorText(tester), 'Bid goods: 0 of 1');

        await tester.tap(_bidChip(_timber));
        await tester.pump();

        expect(_stagedOrder(container, _timber), isNull);
      },
    );
  });
}
