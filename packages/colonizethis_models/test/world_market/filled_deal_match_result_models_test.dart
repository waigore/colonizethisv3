import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Concern-split densify from world_market_state_models_test (Refs #4571).

void main() {
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

    test('equality differs when only isFirstRightOfRefusalMatch differs', () {
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
    });
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
