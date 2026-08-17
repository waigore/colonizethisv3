// Deal Book leftover reason builder tests (Refs #4500).

import 'package:colonizethis_app/features/game/screens/trade/trade_screen_deal_book_reasons.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  const String humanId = 'gp_h';

  group('DealBookReasonBuilder (Refs #4500)', () {
    test('treasury note attaches to matching still-open bid', () {
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
        carryForwardBidsByFactionId: <String, List<TradeOrder>>{
          humanId: <TradeOrder>[
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.bid,
              quantity: 5,
              priority: 1,
            ),
          ],
        },
      );

      final DealBookPanelReasonData data = DealBookReasonBuilder.buildBids(
        worldMarket: worldMarket,
        playerId: humanId,
        unfilledBids: worldMarket.carryForwardBidsByFactionId[humanId]!,
      );

      expect(data.stillOpenRows, hasLength(1));
      expect(
        data.stillOpenRows.first.reasonKind,
        DealBookStillOpenReasonKind.treasuryInsufficient,
      );
      expect(data.didNotStayOpenRows, isEmpty);
    });

    test(
      'cargo drop note renders as Did not stay open without Still open row',
      () {
        final WorldMarketState worldMarket = WorldMarketState(
          lastTurnActivity: <CommodityId, MarketActivity>{
            'timber': MarketActivity(
              notes: <MarketActivityNote>[
                MarketActivityNote(
                  kind: MarketActivityNoteKind
                      .carryForwardDroppedCargoInsufficient,
                  factionId: humanId,
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

        expect(data.stillOpenRows, isEmpty);
        expect(data.didNotStayOpenRows, hasLength(1));
        expect(data.didNotStayOpenRows.first.quantity, 8);
        expect(
          data.didNotStayOpenRows.first.reasonKind,
          DealBookDropReasonKind.cargoInsufficient,
        );
      },
    );

    test('stockpile drop note renders on offers panel', () {
      final WorldMarketState worldMarket = WorldMarketState(
        lastTurnActivity: <CommodityId, MarketActivity>{
          'grain': MarketActivity(
            notes: <MarketActivityNote>[
              MarketActivityNote(
                kind: MarketActivityNoteKind
                    .carryForwardDroppedStockpileInsufficient,
                factionId: humanId,
                commodityId: 'grain',
                quantity: 6,
              ),
            ],
          ),
        },
      );

      final DealBookPanelReasonData data = DealBookReasonBuilder.buildOffers(
        worldMarket: worldMarket,
        playerId: humanId,
        unfilledOffers: const <TradeOrder>[],
      );

      expect(data.didNotStayOpenRows, hasLength(1));
      expect(
        data.didNotStayOpenRows.first.reasonKind,
        DealBookDropReasonKind.stockpileInsufficient,
      );
    });

    test('bid fallback when zero last-turn offers and no human notes', () {
      final WorldMarketState worldMarket = WorldMarketState(
        lastTurnActivity: <CommodityId, MarketActivity>{
          'timber': const MarketActivity(totalOfferQuantity: 0),
        },
        carryForwardBidsByFactionId: <String, List<TradeOrder>>{
          humanId: <TradeOrder>[
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.bid,
              quantity: 3,
              priority: 1,
            ),
          ],
        },
      );

      final DealBookPanelReasonData data = DealBookReasonBuilder.buildBids(
        worldMarket: worldMarket,
        playerId: humanId,
        unfilledBids: worldMarket.carryForwardBidsByFactionId[humanId]!,
      );

      expect(
        data.stillOpenRows.first.reasonKind,
        DealBookStillOpenReasonKind.noMatchingSales,
      );
    });

    test('no bid fallback when last-turn offers were non-zero', () {
      final WorldMarketState worldMarket = WorldMarketState(
        lastTurnActivity: <CommodityId, MarketActivity>{
          'timber': const MarketActivity(totalOfferQuantity: 4),
        },
        carryForwardBidsByFactionId: <String, List<TradeOrder>>{
          humanId: <TradeOrder>[
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.bid,
              quantity: 3,
              priority: 1,
            ),
          ],
        },
      );

      final DealBookPanelReasonData data = DealBookReasonBuilder.buildBids(
        worldMarket: worldMarket,
        playerId: humanId,
        unfilledBids: worldMarket.carryForwardBidsByFactionId[humanId]!,
      );

      expect(data.stillOpenRows.first.reasonKind, isNull);
    });

    test('treasury note wins over zero-offer volume fallback', () {
      final WorldMarketState worldMarket = WorldMarketState(
        lastTurnActivity: <CommodityId, MarketActivity>{
          'timber': MarketActivity(
            totalOfferQuantity: 0,
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
        carryForwardBidsByFactionId: <String, List<TradeOrder>>{
          humanId: <TradeOrder>[
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.bid,
              quantity: 3,
              priority: 1,
            ),
          ],
        },
      );

      final DealBookPanelReasonData data = DealBookReasonBuilder.buildBids(
        worldMarket: worldMarket,
        playerId: humanId,
        unfilledBids: worldMarket.carryForwardBidsByFactionId[humanId]!,
      );

      expect(
        data.stillOpenRows.first.reasonKind,
        DealBookStillOpenReasonKind.treasuryInsufficient,
      );
    });

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
