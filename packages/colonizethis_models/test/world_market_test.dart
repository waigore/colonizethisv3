import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('TradeOrder constructor', () {
    test('constructs valid instance with isFtp default false', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.bid,
        quantity: 5,
        priority: 2,
      );
      expect(order.commodityId, 'timber');
      expect(order.type, TradeOrderType.bid);
      expect(order.quantity, 5);
      expect(order.priority, 2);
      expect(order.isFtp, false);
    });

    test('rejects empty commodityId', () {
      expect(
        () => TradeOrder(
          commodityId: '',
          type: TradeOrderType.bid,
          quantity: 1,
          priority: 1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative quantity', () {
      expect(
        () => TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: -1,
          priority: 1,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('quantity'),
          ),
        ),
      );
    });

    test('rejects priority below 1', () {
      expect(
        () => TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 1,
          priority: 0,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('priority'),
          ),
        ),
      );
    });

    test('accepts quantity == 0 (caller may carry zero-rest after partial)', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 0,
        priority: 1,
      );
      expect(order.quantity, 0);
    });
  });

  group('TradeOrder serialization', () {
    test('toJson produces canonical fields and omits originTileKey when null',
        () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.bid,
        quantity: 5,
        priority: 2,
        isFtp: true,
      );
      expect(order.toJson(), {
        'commodityId': 'timber',
        'type': 'bid',
        'quantity': 5,
        'priority': 2,
        'isFtp': true,
      });
      expect(order.toJson().containsKey('originTileKey'), isFalse);
    });

    test('round-trips equal instance with all fields preserved', () {
      final order = TradeOrder(
        commodityId: 'iron',
        type: TradeOrderType.offer,
        quantity: 12,
        priority: 3,
        isFtp: false,
      );
      final restored = TradeOrder.fromJson(order.toJson());
      expect(restored, equals(order));
      expect(restored.hashCode, equals(order.hashCode));
    });

    test('fromJson rejects missing/invalid type field', () {
      expect(
        () => TradeOrder.fromJson({
          'commodityId': 'timber',
          'type': 'invalid_type',
          'quantity': 1,
          'priority': 1,
          'isFtp': false,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson rejects non-int quantity field', () {
      expect(
        () => TradeOrder.fromJson({
          'commodityId': 'timber',
          'type': 'bid',
          'quantity': 'not-a-number',
          'priority': 1,
          'isFtp': false,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('TradeOrder equality and copyWith', () {
    test('equality is field-based', () {
      final a = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.bid,
        quantity: 5,
        priority: 2,
      );
      final b = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.bid,
        quantity: 5,
        priority: 2,
      );
      final c = a.copyWith(quantity: 6);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('equality differs when only originTileKey differs', () {
      final a = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
      );
      final b = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
        originTileKey: 'oldWorld|M1|0|0',
      );
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('copyWith preserves originTileKey when not specified', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
        originTileKey: 'oldWorld|M1|0|0',
      );
      final copy = order.copyWith(quantity: 3);
      expect(copy.originTileKey, 'oldWorld|M1|0|0');
      expect(copy.quantity, 3);
    });

    test('copyWith can clear originTileKey by passing null explicitly', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
        originTileKey: 'oldWorld|M1|0|0',
      );
      final cleared = order.copyWith(originTileKey: null);
      expect(cleared.originTileKey, isNull);
    });

    test('copyWith can replace originTileKey with a new value', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
      );
      final updated = order.copyWith(originTileKey: 'newWorld|T2|3|3');
      expect(updated.originTileKey, 'newWorld|T2|3|3');
    });
  });

  group('TradeOrder originTileKey (#2992 D2)', () {
    test('originTileKey defaults to null', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
      );
      expect(order.originTileKey, isNull);
    });

    test('rejects empty originTileKey', () {
      expect(
        () => TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.offer,
          quantity: 5,
          priority: 1,
          originTileKey: '',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('originTileKey'),
          ),
        ),
      );
    });

    test('toJson includes originTileKey when set', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
        originTileKey: 'oldWorld|M1|0|0',
      );
      expect(order.toJson()['originTileKey'], 'oldWorld|M1|0|0');
    });

    test('round-trips originTileKey through JSON', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
        originTileKey: 'oldWorld|M1|0|0',
      );
      final restored = TradeOrder.fromJson(order.toJson());
      expect(restored, equals(order));
      expect(restored.originTileKey, 'oldWorld|M1|0|0');
    });

    test('fromJson treats missing originTileKey as null', () {
      final restored = TradeOrder.fromJson({
        'commodityId': 'timber',
        'type': 'offer',
        'quantity': 5,
        'priority': 1,
        'isFtp': false,
      });
      expect(restored.originTileKey, isNull);
    });

    test('fromJson treats empty-string originTileKey as null', () {
      final restored = TradeOrder.fromJson({
        'commodityId': 'timber',
        'type': 'offer',
        'quantity': 5,
        'priority': 1,
        'isFtp': false,
        'originTileKey': '',
      });
      expect(restored.originTileKey, isNull);
    });
  });

  group('MarketActivity', () {
    test('empty has zeroed fields and empty deals/notes', () {
      const m = MarketActivity.empty;
      expect(m.totalBidQuantity, 0);
      expect(m.totalOfferQuantity, 0);
      expect(m.filledQuantity, 0);
      expect(m.priceChangePercent, 0.0);
      expect(m.deals, isEmpty);
      expect(m.notes, isEmpty);
    });

    test('round-trips through JSON', () {
      const original = MarketActivity(
        totalBidQuantity: 20,
        totalOfferQuantity: 10,
        filledQuantity: 10,
        priceChangePercent: 0.1667,
      );
      final restored = MarketActivity.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('deals defaults to empty list and is omitted from JSON when empty', () {
      const m = MarketActivity(
        totalBidQuantity: 5,
        totalOfferQuantity: 5,
        filledQuantity: 5,
      );
      expect(m.deals, isEmpty);
      expect(m.toJson().containsKey('deals'), isFalse);
    });

    test('toJson omits notes when empty', () {
      const m = MarketActivity(
        totalBidQuantity: 1,
        totalOfferQuantity: 1,
      );
      expect(m.toJson().containsKey('notes'), isFalse);
    });

    test(
      'round-trips through JSON with deals (preserves order and FRR flag — '
      'Refs #2993 E6 ledger surface)',
      () {
        const original = MarketActivity(
          totalBidQuantity: 12,
          totalOfferQuantity: 12,
          filledQuantity: 12,
          priceChangePercent: 0.0,
          deals: <FilledDeal>[
            FilledDeal(
              sellerFactionId: 'gpA',
              buyerFactionId: 'gpB',
              commodityId: 'timber',
              quantity: 5,
              pricePerUnit: 30.0,
            ),
            FilledDeal(
              sellerFactionId: 'M1',
              buyerFactionId: 'gpA',
              commodityId: 'timber',
              quantity: 7,
              pricePerUnit: 30.0,
              isFirstRightOfRefusalMatch: true,
              sellerOriginTileKey: 'oldWorld|M1|0|0',
            ),
          ],
        );
        final restored = MarketActivity.fromJson(original.toJson());
        expect(restored, equals(original));
        expect(restored.deals, hasLength(2));
        expect(restored.deals.first.buyerFactionId, 'gpB');
        expect(restored.deals.last.isFirstRightOfRefusalMatch, isTrue);
      },
    );

    test('equality reflects deals differences', () {
      const a = MarketActivity(
        deals: <FilledDeal>[
          FilledDeal(
            sellerFactionId: 'gpA',
            buyerFactionId: 'gpB',
            commodityId: 'timber',
            quantity: 5,
            pricePerUnit: 30.0,
          ),
        ],
      );
      const b = MarketActivity(
        deals: <FilledDeal>[
          FilledDeal(
            sellerFactionId: 'gpA',
            buyerFactionId: 'gpB',
            commodityId: 'timber',
            quantity: 6, // different quantity
            pricePerUnit: 30.0,
          ),
        ],
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('MarketActivityNote (#2990 B3 follow-up)', () {
    test('round-trips stockpile-drop note through JSON', () {
      const note = MarketActivityNote(
        kind: MarketActivityNoteKind.carryForwardDroppedStockpileInsufficient,
        factionId: 'gp1',
        commodityId: 'timber',
        quantity: 7,
      );
      final restored = MarketActivityNote.fromJson(note.toJson());
      expect(restored, equals(note));
      expect(restored.hashCode, equals(note.hashCode));
    });

    test('round-trips cargo-drop note through JSON', () {
      const note = MarketActivityNote(
        kind: MarketActivityNoteKind.carryForwardDroppedCargoInsufficient,
        factionId: 'gp2',
        commodityId: 'iron',
        quantity: 4,
      );
      final restored = MarketActivityNote.fromJson(note.toJson());
      expect(restored, equals(note));
    });

    test('toJson uses enum names', () {
      const note = MarketActivityNote(
        kind: MarketActivityNoteKind.carryForwardDroppedCargoInsufficient,
        factionId: 'gp1',
        commodityId: 'timber',
        quantity: 1,
      );
      expect(
        note.toJson(),
        {
          'kind': 'carryForwardDroppedCargoInsufficient',
          'factionId': 'gp1',
          'commodityId': 'timber',
          'quantity': 1,
        },
      );
    });

    test('fromJson rejects unknown kind', () {
      expect(
        () => MarketActivityNote.fromJson({
          'kind': 'totallyMadeUp',
          'factionId': 'gp1',
          'commodityId': 'timber',
          'quantity': 1,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson rejects non-string factionId', () {
      expect(
        () => MarketActivityNote.fromJson({
          'kind': 'carryForwardDroppedStockpileInsufficient',
          'factionId': 7,
          'commodityId': 'timber',
          'quantity': 1,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('MarketActivity round-trips a notes list through JSON', () {
      const original = MarketActivity(
        totalBidQuantity: 0,
        totalOfferQuantity: 5,
        filledQuantity: 0,
        priceChangePercent: 0.0,
        notes: [
          MarketActivityNote(
            kind: MarketActivityNoteKind
                .carryForwardDroppedStockpileInsufficient,
            factionId: 'gp1',
            commodityId: 'timber',
            quantity: 7,
          ),
        ],
      );
      final restored = MarketActivity.fromJson(original.toJson());
      expect(restored, equals(original));
      expect(restored.notes.single.factionId, 'gp1');
      expect(restored.notes.single.quantity, 7);
    });

    test('MarketActivity equality reflects notes differences', () {
      const a = MarketActivity(totalOfferQuantity: 1);
      const b = MarketActivity(
        totalOfferQuantity: 1,
        notes: [
          MarketActivityNote(
            kind: MarketActivityNoteKind
                .carryForwardDroppedStockpileInsufficient,
            factionId: 'gp1',
            commodityId: 'timber',
            quantity: 1,
          ),
        ],
      );
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('WorldMarketState', () {
    test('withDefaultPrices populates prices as int and leaves activity empty',
        () {
      final state = WorldMarketState.withDefaultPrices({
        'timber': 30,
        'iron': 80,
      });
      // Post-#3093: `WorldMarketState.prices` is now `Map<CommodityId, int>`
      // (floored at persistence boundary per
      // SPEC/game/world-market.md § Price discovery).
      expect(state.prices, <CommodityId, int>{'timber': 30, 'iron': 80});
      expect(state.prices['timber'], isA<int>());
      expect(state.lastTurnActivity, isEmpty);
    });

    test('round-trips through JSON', () {
      final state = WorldMarketState.withDefaultPrices({
        'timber': 30,
        'iron': 80,
      }).copyWith(
        lastTurnActivity: const {
          'timber': MarketActivity(
            totalBidQuantity: 20,
            totalOfferQuantity: 10,
            filledQuantity: 10,
            priceChangePercent: 0.1667,
          ),
        },
      );
      final restored = WorldMarketState.fromJson(state.toJson());
      expect(restored, equals(state));
      expect(restored.prices['timber'], isA<int>());
      expect(restored.prices['timber'], 30);
    });

    test('fromJson floors legacy double prices to int (backward compat)', () {
      // Pre-#3093 saves wrote `prices` as `Map<CommodityId, double>`.
      // The new `fromJson` floors any non-integer numeric value so the
      // in-memory map is always int-valued without forcing a save migration.
      final restored = WorldMarketState.fromJson(<String, dynamic>{
        'prices': <String, dynamic>{
          'timber': 29.99,
          'iron': 80.5,
          'coal': 100,
        },
        'lastTurnActivity': <String, dynamic>{},
      });
      expect(restored.prices, <CommodityId, int>{
        'timber': 29,
        'iron': 80,
        'coal': 100,
      });
      expect(restored.prices['timber'], isA<int>());
    });

    test('fromJson clamps negative numeric prices to 0 (defensive)', () {
      // SPEC/game/world-market.md § Price discovery clamps the floor at
      // 30% of base price (always non-negative). A hand-edited save with a
      // negative price would have been a logic bug pre-#3093; the new
      // floor migration treats it as zero rather than crashing.
      final restored = WorldMarketState.fromJson(<String, dynamic>{
        'prices': <String, dynamic>{'timber': -5.0},
      });
      expect(restored.prices['timber'], 0);
    });

    test('empty constants are equal', () {
      expect(WorldMarketState.empty, equals(const WorldMarketState()));
    });

    test('carry-forward maps default to empty and omit from JSON when empty', () {
      const state = WorldMarketState();
      expect(state.carryForwardOffersByFactionId, isEmpty);
      expect(state.carryForwardBidsByFactionId, isEmpty);
      final json = state.toJson();
      expect(json.containsKey('carryForwardOffersByFactionId'), isFalse);
      expect(json.containsKey('carryForwardBidsByFactionId'), isFalse);
    });

    test('round-trips carry-forward offers and bids through JSON', () {
      final state = WorldMarketState.empty.copyWith(
        carryForwardOffersByFactionId: {
          'gp1': [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.offer,
              quantity: 5,
              priority: 2,
            ),
          ],
        },
        carryForwardBidsByFactionId: {
          'gp2': [
            TradeOrder(
              commodityId: 'iron',
              type: TradeOrderType.bid,
              quantity: 3,
              priority: 1,
              isFtp: true,
            ),
          ],
        },
      );
      final restored = WorldMarketState.fromJson(state.toJson());
      expect(restored, equals(state));
      expect(
        restored.carryForwardOffersByFactionId['gp1']!.single.quantity,
        5,
      );
      expect(
        restored.carryForwardBidsByFactionId['gp2']!.single.isFtp,
        isTrue,
      );
    });

    test('equality reflects carry-forward differences', () {
      final base = WorldMarketState.empty.copyWith(
        carryForwardOffersByFactionId: {
          'gp1': [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.offer,
              quantity: 5,
              priority: 2,
            ),
          ],
        },
      );
      final differentQty = WorldMarketState.empty.copyWith(
        carryForwardOffersByFactionId: {
          'gp1': [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.offer,
              quantity: 6,
              priority: 2,
            ),
          ],
        },
      );
      expect(base, isNot(equals(differentQty)));
      expect(base, equals(base.copyWith()));
    });
  });

  group('FilledDeal', () {
    test('round-trips through JSON', () {
      const deal = FilledDeal(
        sellerFactionId: 'f1',
        buyerFactionId: 'f2',
        commodityId: 'timber',
        quantity: 7,
        pricePerUnit: 30.5,
        isFtpMatch: true,
      );
      final restored = FilledDeal.fromJson(deal.toJson());
      expect(restored, equals(deal));
    });

    test('isFirstRightOfRefusalMatch defaults to false', () {
      const deal = FilledDeal(
        sellerFactionId: 'f1',
        buyerFactionId: 'f2',
        commodityId: 'timber',
        quantity: 1,
        pricePerUnit: 1.0,
      );
      expect(deal.isFirstRightOfRefusalMatch, isFalse);
      expect(deal.toJson().containsKey('isFirstRightOfRefusalMatch'), isFalse);
    });

    test(
      'isFirstRightOfRefusalMatch round-trips through JSON when true (#2992 D2)',
      () {
        const deal = FilledDeal(
          sellerFactionId: 'M1',
          buyerFactionId: 'gpA',
          commodityId: 'timber',
          quantity: 4,
          pricePerUnit: 30.0,
          isFirstRightOfRefusalMatch: true,
        );
        final restored = FilledDeal.fromJson(deal.toJson());
        expect(restored, equals(deal));
        expect(restored.isFirstRightOfRefusalMatch, isTrue);
        expect(deal.toJson()['isFirstRightOfRefusalMatch'], true);
      },
    );

    test(
      'equality differs when only isFirstRightOfRefusalMatch differs',
      () {
        const ftpDeal = FilledDeal(
          sellerFactionId: 'a',
          buyerFactionId: 'b',
          commodityId: 'timber',
          quantity: 1,
          pricePerUnit: 1.0,
          isFtpMatch: true,
        );
        const frrDeal = FilledDeal(
          sellerFactionId: 'a',
          buyerFactionId: 'b',
          commodityId: 'timber',
          quantity: 1,
          pricePerUnit: 1.0,
          isFirstRightOfRefusalMatch: true,
        );
        expect(ftpDeal, isNot(equals(frrDeal)));
        expect(ftpDeal.hashCode, isNot(equals(frrDeal.hashCode)));
      },
    );
  });

  group('DealMatchResult.empty', () {
    test('has empty children and equals const default', () {
      const r = DealMatchResult.empty;
      expect(r.filledDeals, isEmpty);
      expect(r.unfilledOffersByFactionId, isEmpty);
      expect(r.unfilledBidsByFactionId, isEmpty);
      expect(r.activityByCommodityId, isEmpty);
      expect(r, equals(const DealMatchResult()));
    });
  });
}
