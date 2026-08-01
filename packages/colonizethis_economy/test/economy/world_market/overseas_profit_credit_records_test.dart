import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('buildOverseasProfitCreditRecordsByGpId (Refs #4226)', () {
    test('maps tile-owner credited deals into tileOwnerShare rows', () {
      final credits = computeFirstRightCredits(
        filledDeals: [dealOn('k1', buyer: 'gpB')],
        purchasedTileIndex: frrIdxK1GpA(),
        relationScoreFor: frrConstantRelation(100),
      );

      final records = buildOverseasProfitCreditRecordsByGpId(
        credits: credits,
        filledDeals: [dealOn('k1', buyer: 'gpB')],
        purchasedTileIndex: frrIdxK1GpA(),
        embassyGpRelationsFor: null,
      );

      expect(records.keys, ['gpA']);
      final row = records['gpA']!.single;
      expect(row.creditKind, OverseasProfitCreditKind.tileOwnerShare);
      expect(row.commodityId, 'timber');
      expect(row.quantity, 10);
      expect(row.profitTreasury, 200);
      expect(row.buyerFactionId, 'gpB');
      expect(row.sourceFactionId, 'M1');
    });

    test('adds embassyKickback rows for non-owner embassy GPs', () {
      final filledDeals = [dealOn('k1', buyer: 'gpB')];
      final credits = computeFirstRightCredits(
        filledDeals: filledDeals,
        purchasedTileIndex: frrIdxK1GpA(),
        relationScoreFor: frrRelationTable(const {
          'gpA': {'M1': 100},
        }),
        embassyGpRelationsFor: frrEmbassyForM1(const {'gpC': 50}),
      );

      final records = buildOverseasProfitCreditRecordsByGpId(
        credits: credits,
        filledDeals: filledDeals,
        purchasedTileIndex: frrIdxK1GpA(),
        embassyGpRelationsFor: frrEmbassyForM1(const {'gpC': 50}),
      );

      expect(records['gpA']!.single.creditKind,
          OverseasProfitCreditKind.tileOwnerShare);
      final kickback = records['gpC']!.single;
      expect(kickback.creditKind, OverseasProfitCreditKind.embassyKickback);
      expect(kickback.profitTreasury, 10);
      expect(kickback.buyerFactionId, 'gpB');
      expect(kickback.sourceFactionId, 'M1');
    });

    test('skips tile-owner row when rounded treasury is zero', () {
      final credits = computeFirstRightCredits(
        filledDeals: [dealOn('k1', buyer: 'gpB')],
        purchasedTileIndex: frrIdxK1GpA(),
        relationScoreFor: frrConstantRelation(0),
      );

      final records = buildOverseasProfitCreditRecordsByGpId(
        credits: credits,
        filledDeals: [dealOn('k1', buyer: 'gpB')],
        purchasedTileIndex: frrIdxK1GpA(),
        embassyGpRelationsFor: null,
      );

      expect(records, isEmpty);
    });

    test('skips embassy kickback for tile owner and zero-relation holders', () {
      final filledDeals = [dealOn('k1', buyer: 'gpB')];
      final credits = computeFirstRightCredits(
        filledDeals: filledDeals,
        purchasedTileIndex: frrIdxK1GpA(),
        relationScoreFor: frrConstantRelation(100),
        embassyGpRelationsFor: frrEmbassyForM1(const {'gpA': 100, 'gpC': 0}),
      );

      final records = buildOverseasProfitCreditRecordsByGpId(
        credits: credits,
        filledDeals: filledDeals,
        purchasedTileIndex: frrIdxK1GpA(),
        embassyGpRelationsFor: frrEmbassyForM1(const {'gpA': 100, 'gpC': 0}),
      );

      expect(records.keys, ['gpA']);
      expect(records.containsKey('gpC'), isFalse);
    });

    test('returns unmodifiable nested lists', () {
      final credits = computeFirstRightCredits(
        filledDeals: [dealOn('k1', buyer: 'gpB')],
        purchasedTileIndex: frrIdxK1GpA(),
        relationScoreFor: frrConstantRelation(100),
      );

      final records = buildOverseasProfitCreditRecordsByGpId(
        credits: credits,
        filledDeals: [dealOn('k1', buyer: 'gpB')],
        purchasedTileIndex: frrIdxK1GpA(),
        embassyGpRelationsFor: null,
      );

      expect(() => records['gpA']!.add(records['gpA']!.first), throwsUnsupportedError);
      expect(() => records['gpZ'] = const [], throwsUnsupportedError);
    });
  });

  group('overseasProfitTreasuryTotalByGpId (Refs #4226)', () {
    test('sums profitTreasury per GP and omits zero totals', () {
      final records = {
        'gpA': [
          const OverseasProfitCreditRecord(
            creditKind: OverseasProfitCreditKind.tileOwnerShare,
            commodityId: 'timber',
            quantity: 10,
            profitTreasury: 150,
          ),
          const OverseasProfitCreditRecord(
            creditKind: OverseasProfitCreditKind.embassyKickback,
            commodityId: 'timber',
            quantity: 10,
            profitTreasury: 10,
          ),
        ],
        'gpB': [
          const OverseasProfitCreditRecord(
            creditKind: OverseasProfitCreditKind.tileOwnerShare,
            commodityId: 'iron',
            quantity: 5,
            profitTreasury: 0,
          ),
        ],
      };

      final totals = overseasProfitTreasuryTotalByGpId(records);

      expect(totals, {'gpA': 160});
      expect(() => totals['gpC'] = 1, throwsUnsupportedError);
    });
  });
}
