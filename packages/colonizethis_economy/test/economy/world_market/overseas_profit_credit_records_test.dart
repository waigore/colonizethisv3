import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

typedef _BuildRecordsScenario = ({
  String label,
  List<FilledDeal> filledDeals,
  PurchasedTileIndex purchasedTileIndex,
  num Function(String, String) relationScoreFor,
  Map<String, num> Function(String sourceFactionId)? embassyGpRelationsFor,
  void Function(Map<String, List<OverseasProfitCreditRecord>> records) verify,
});

typedef _TotalsScenario = ({
  String label,
  Map<String, List<OverseasProfitCreditRecord>> records,
  Map<String, int> expected,
  bool expectUnmodifiable,
});

void _runBuildRecordsScenario(_BuildRecordsScenario scenario) {
  final credits = computeFirstRightCredits(
    filledDeals: scenario.filledDeals,
    purchasedTileIndex: scenario.purchasedTileIndex,
    relationScoreFor: scenario.relationScoreFor,
    embassyGpRelationsFor: scenario.embassyGpRelationsFor,
  );
  final records = buildOverseasProfitCreditRecordsByGpId(
    credits: credits,
    filledDeals: scenario.filledDeals,
    purchasedTileIndex: scenario.purchasedTileIndex,
    embassyGpRelationsFor: scenario.embassyGpRelationsFor,
  );
  scenario.verify(records);
}

Iterable<_BuildRecordsScenario> _buildRecordsScenarios() sync* {
  final defaultDeals = [dealOn('k1', buyer: 'gpB')];
  final defaultIndex = frrIdxK1GpA();

  yield (
    label: 'maps tile-owner credited deals into tileOwnerShare rows',
    filledDeals: defaultDeals,
    purchasedTileIndex: defaultIndex,
    relationScoreFor: frrConstantRelation(100),
    embassyGpRelationsFor: null,
    verify: (records) {
      expect(records.keys, ['gpA']);
      final row = records['gpA']!.single;
      expect(row.creditKind, OverseasProfitCreditKind.tileOwnerShare);
      expect(row.commodityId, 'timber');
      expect(row.quantity, 10);
      expect(row.profitTreasury, 200);
      expect(row.buyerFactionId, 'gpB');
      expect(row.sourceFactionId, 'M1');
    },
  );

  yield (
    label: 'adds embassyKickback rows for non-owner embassy GPs',
    filledDeals: defaultDeals,
    purchasedTileIndex: defaultIndex,
    relationScoreFor: frrRelationTable(const {
      'gpA': {'M1': 100},
    }),
    embassyGpRelationsFor: frrEmbassyForM1(const {'gpC': 50}),
    verify: (records) {
      expect(
        records['gpA']!.single.creditKind,
        OverseasProfitCreditKind.tileOwnerShare,
      );
      final kickback = records['gpC']!.single;
      expect(kickback.creditKind, OverseasProfitCreditKind.embassyKickback);
      expect(kickback.profitTreasury, 10);
      expect(kickback.buyerFactionId, 'gpB');
      expect(kickback.sourceFactionId, 'M1');
    },
  );

  yield (
    label: 'skips tile-owner row when rounded treasury is zero',
    filledDeals: defaultDeals,
    purchasedTileIndex: defaultIndex,
    relationScoreFor: frrConstantRelation(0),
    embassyGpRelationsFor: null,
    verify: (records) => expect(records, isEmpty),
  );

  yield (
    label: 'skips embassy kickback for tile owner and zero-relation holders',
    filledDeals: defaultDeals,
    purchasedTileIndex: defaultIndex,
    relationScoreFor: frrConstantRelation(100),
    embassyGpRelationsFor: frrEmbassyForM1(const {'gpA': 100, 'gpC': 0}),
    verify: (records) {
      expect(records.keys, ['gpA']);
      expect(records.containsKey('gpC'), isFalse);
    },
  );

  yield (
    label: 'returns unmodifiable nested lists',
    filledDeals: defaultDeals,
    purchasedTileIndex: defaultIndex,
    relationScoreFor: frrConstantRelation(100),
    embassyGpRelationsFor: null,
    verify: (records) {
      expect(
        () => records['gpA']!.add(records['gpA']!.first),
        throwsUnsupportedError,
      );
      expect(() => records['gpZ'] = const [], throwsUnsupportedError);
    },
  );
}

Iterable<_TotalsScenario> _totalsScenarios() sync* {
  yield (
    label: 'sums profitTreasury per GP and omits zero totals',
    records: {
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
    },
    expected: {'gpA': 160},
    expectUnmodifiable: true,
  );
}

void main() {
  runLabeledScenarioGroup(
    'buildOverseasProfitCreditRecordsByGpId (Refs #4226)',
    _buildRecordsScenarios(),
    _runBuildRecordsScenario,
    labelOf: (scenario) => scenario.label,
  );

  runLabeledScenarioGroup(
    'overseasProfitTreasuryTotalByGpId (Refs #4226)',
    _totalsScenarios(),
    (scenario) {
      final totals = overseasProfitTreasuryTotalByGpId(scenario.records);
      expect(totals, scenario.expected);
      if (scenario.expectUnmodifiable) {
        expect(() => totals['gpC'] = 1, throwsUnsupportedError);
      }
    },
    labelOf: (scenario) => scenario.label,
  );
}
