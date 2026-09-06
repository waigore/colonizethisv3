// Widget tests for the Trade Market tab bid-type slot indicator and gate
// (Refs #4170). SPEC/ui/trade-screen.md § Market tab — bid-type cap.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_market_tab_bid_type_cap_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab bid-type cap (Refs #4170)', () {
    testWidgets(
      'no embassy (cap 3) with zero staged bids → indicator reads Bid goods: 0 of 3',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(prices: const {kBidTypeCapTimber: 30}),
        );

        expect(bidTypeCapIndicatorText(tester), 'Bid goods: 0 of 3');
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidTypeWarningKey),
          findsNothing,
        );
      },
    );

    testWidgets(
      'cap 3 saturated → indicator reads Bid goods: 3 of 3 and warning mounts',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            prices: const {
              kBidTypeCapTimber: 30,
              kBidTypeCapIron: 80,
              kBidTypeCapGrain: 50,
            },
          ),
          initialOrders: bidTypeCapOrders([
            bidTypeCapBid(kBidTypeCapTimber, 1),
            bidTypeCapBid(kBidTypeCapIron, 1),
            bidTypeCapBid(kBidTypeCapGrain, 1),
          ]),
        );

        expect(bidTypeCapIndicatorText(tester), 'Bid goods: 3 of 3');
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidTypeWarningKey),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'cap 3 saturated → fresh commodity Bid is a silent no-op when 3 slots used',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            prices: const {
              kBidTypeCapTimber: 30,
              kBidTypeCapIron: 80,
              kBidTypeCapGrain: 50,
            },
            stockpile: tradeableStockpileFilled(50),
          ),
          initialOrders: bidTypeCapOrders([
            bidTypeCapBid(kBidTypeCapTimber, 1),
            bidTypeCapBid(kBidTypeCapIron, 1),
            bidTypeCapBid(kBidTypeCapGrain, 1),
          ]),
        );

        const CommodityId wool = 'wool';
        final CtChoiceChip woolBidChip = tester.widget<CtChoiceChip>(
          bidTypeCapBidChip(wool),
        );
        expect(woolBidChip.onSelected, isNull);

        await tester.tap(bidTypeCapBidChip(wool));
        await tester.pump();

        expect(bidTypeCapStagedOrder(container, wool), isNull);
        expect(bidTypeCapIndicatorText(tester), 'Bid goods: 3 of 3');
      },
    );

    testWidgets(
      'cap 3 with one staged bid → timber bid row stays editable (increment allowed)',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            prices: const {kBidTypeCapTimber: 30},
            tradeCargoCapacityOverride: 10,
          ),
          initialOrders: bidTypeCapOrders([bidTypeCapBid(kBidTypeCapTimber, 1)]),
        );

        final CtChoiceChip timberBidChip = tester.widget<CtChoiceChip>(
          bidTypeCapBidChip(kBidTypeCapTimber),
        );
        expect(timberBidChip.onSelected, isNotNull);

        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(kBidTypeCapTimber)),
        );
        await tester.pump();

        expect(bidTypeCapStagedOrder(container, kBidTypeCapTimber)?.quantity, 2);
      },
    );

    testWidgets(
      'offers do not consume bid-goods slots',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            prices: const {kBidTypeCapTimber: 30, kBidTypeCapIron: 80},
            stockpile: tradeableStockpileFilled(50),
          ),
          initialOrders: bidTypeCapOrders([
            TradeOrder(
              commodityId: kBidTypeCapTimber,
              type: TradeOrderType.offer,
              quantity: 2,
              priority: 1,
            ),
          ]),
        );

        expect(bidTypeCapIndicatorText(tester), 'Bid goods: 0 of 3');
      },
    );

    testWidgets(
      'setting bid to None frees a slot immediately on the indicator',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            prices: const {kBidTypeCapTimber: 30, kBidTypeCapIron: 80},
          ),
          initialOrders: bidTypeCapOrders([bidTypeCapBid(kBidTypeCapTimber, 1)]),
        );

        expect(bidTypeCapIndicatorText(tester), 'Bid goods: 1 of 3');

        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketRowNoneChipKey(kBidTypeCapTimber)),
        );
        await tester.pump();

        expect(bidTypeCapStagedOrder(container, kBidTypeCapTimber), isNull);
        expect(bidTypeCapIndicatorText(tester), 'Bid goods: 0 of 3');
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidTypeWarningKey),
          findsNothing,
        );
      },
    );

    testWidgets(
      'embassy without Trade Fairs → cap remains 3 on indicator',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            prices: const {
              kBidTypeCapTimber: 30,
              kBidTypeCapIron: 80,
              kBidTypeCapGrain: 50,
            },
            overtureStates: const <OvertureState>[
              OvertureState(
                gpId: kBidTypeCapHumanPlayerId,
                targetId: 'minor1',
                stage: OvertureStage.embassy,
              ),
            ],
          ),
          initialOrders: bidTypeCapOrders([
            bidTypeCapBid(kBidTypeCapTimber, 1),
            bidTypeCapBid(kBidTypeCapIron, 1),
          ]),
        );

        expect(bidTypeCapIndicatorText(tester), 'Bid goods: 2 of 3');
      },
    );

    testWidgets(
      'Trade Fairs unlocked → cap 6 reflected in indicator',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            techUnlocked: const <String, bool>{kTechIdTradeFairs: true},
          ),
        );

        expect(bidTypeCapIndicatorText(tester), 'Bid goods: 0 of 6');
      },
    );
  });
}
