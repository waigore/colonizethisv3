import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
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

    test(
      'deals defaults to empty list and is omitted from JSON when empty',
      () {
        const m = MarketActivity(
          totalBidQuantity: 5,
          totalOfferQuantity: 5,
          filledQuantity: 5,
        );
        expect(m.deals, isEmpty);
        expect(m.toJson().containsKey('deals'), isFalse);
      },
    );

    test('toJson omits notes when empty', () {
      const m = MarketActivity(totalBidQuantity: 1, totalOfferQuantity: 1);
      expect(m.toJson().containsKey('notes'), isFalse);
    });

    test('round-trips through JSON with deals (preserves order and FRR flag — '
        'Refs #2993 E6 ledger surface)', () {
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
    });

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
      expect(note.toJson(), {
        'kind': 'carryForwardDroppedCargoInsufficient',
        'factionId': 'gp1',
        'commodityId': 'timber',
        'quantity': 1,
      });
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
            kind:
                MarketActivityNoteKind.carryForwardDroppedStockpileInsufficient,
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
            kind:
                MarketActivityNoteKind.carryForwardDroppedStockpileInsufficient,
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
}
