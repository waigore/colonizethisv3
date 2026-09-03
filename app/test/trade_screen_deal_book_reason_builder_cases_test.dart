// Deal Book leftover reason builder cases (Refs #4500).

import 'package:colonizethis_app/features/game/screens/trade/trade_screen_deal_book_reasons.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  const String humanId = 'gp_h';

  group('DealBookReasonBuilder (Refs #4500)', () {
    test('offer fallback when zero last-turn bids and no human notes', () {
      final WorldMarketState worldMarket = WorldMarketState(
        lastTurnActivity: <CommodityId, MarketActivity>{
          'grain': const MarketActivity(totalBidQuantity: 0),
        },
        carryForwardOffersByFactionId: <String, List<TradeOrder>>{
          humanId: <TradeOrder>[
            TradeOrder(
              commodityId: 'grain',
              type: TradeOrderType.offer,
              quantity: 4,
              priority: 1,
            ),
          ],
        },
      );

      final DealBookPanelReasonData data = DealBookReasonBuilder.buildOffers(
        worldMarket: worldMarket,
        playerId: humanId,
        unfilledOffers: worldMarket.carryForwardOffersByFactionId[humanId]!,
      );

      expect(
        data.stillOpenRows.first.reasonKind,
        DealBookStillOpenReasonKind.noMatchingBuys,
      );
    });

    test('foreign notes are ignored', () {
      final WorldMarketState worldMarket = WorldMarketState(
        lastTurnActivity: <CommodityId, MarketActivity>{
          'timber': MarketActivity(
            notes: <MarketActivityNote>[
              MarketActivityNote(
                kind:
                    MarketActivityNoteKind.carryForwardDroppedCargoInsufficient,
                factionId: 'gp_other',
                commodityId: 'timber',
                quantity: 8,
              ),
            ],
          ),
        },
      );

      final DealBookPanelReasonData data = DealBookReasonBuilder.buildBids(
        worldMarket: worldMarket,
        playerId: humanId,
        unfilledBids: const <TradeOrder>[],
      );

      expect(data.didNotStayOpenRows, isEmpty);
    });

    test('orphan treasury note with no leftover bid is omitted', () {
      final WorldMarketState worldMarket = WorldMarketState(
        lastTurnActivity: <CommodityId, MarketActivity>{
          'timber': MarketActivity(
            notes: <MarketActivityNote>[
              MarketActivityNote(
                kind: MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
                factionId: humanId,
                commodityId: 'timber',
                quantity: 10,
              ),
            ],
          ),
        },
      );

      final DealBookPanelReasonData data = DealBookReasonBuilder.buildBids(
        worldMarket: worldMarket,
        playerId: humanId,
        unfilledBids: const <TradeOrder>[],
      );

      expect(data.stillOpenRows, isEmpty);
      expect(data.didNotStayOpenRows, isEmpty);
    });

    test('no offer fallback when last-turn bids were non-zero', () {
      final WorldMarketState worldMarket = WorldMarketState(
        lastTurnActivity: <CommodityId, MarketActivity>{
          'grain': const MarketActivity(totalBidQuantity: 4),
        },
        carryForwardOffersByFactionId: <String, List<TradeOrder>>{
          humanId: <TradeOrder>[
            TradeOrder(
              commodityId: 'grain',
              type: TradeOrderType.offer,
              quantity: 4,
              priority: 1,
            ),
          ],
        },
      );

      final DealBookPanelReasonData data = DealBookReasonBuilder.buildOffers(
        worldMarket: worldMarket,
        playerId: humanId,
        unfilledOffers: worldMarket.carryForwardOffersByFactionId[humanId]!,
      );

      expect(data.stillOpenRows.first.reasonKind, isNull);
    });
  });
}
