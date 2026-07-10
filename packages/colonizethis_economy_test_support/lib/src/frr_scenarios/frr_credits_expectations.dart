// Compact First Right credits result assertions (Refs #3939 phase 3 slice 12 / 61).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

/// Treasury-close-to pin helper (Refs #3939 slice 61).
FrrCreditsExpectation frrTreasuryCloseTo(
  Map<String, double> treasuryCreditCloseTo, {
  double? totalProfitTreasury,
  int? creditedDealsLength,
  Iterable<String>? treasuryCreditKeysContainAll,
  List<String>? treasuryCreditKeysExact,
  bool creditedDealsEmpty = false,
  bool treasuryCreditEmpty = false,
  String? singleCreditedDealBuyer,
}) => FrrCreditsExpectation(
  treasuryCreditCloseTo: treasuryCreditCloseTo,
  totalProfitTreasury: totalProfitTreasury,
  creditedDealsLength: creditedDealsLength,
  treasuryCreditKeysContainAll: treasuryCreditKeysContainAll,
  treasuryCreditKeysExact: treasuryCreditKeysExact,
  creditedDealsEmpty: creditedDealsEmpty,
  treasuryCreditEmpty: treasuryCreditEmpty,
  singleCreditedDealBuyer: singleCreditedDealBuyer,
);

/// Single credited-deal + treasury pin helper (Refs #3939 slice 61).
FrrCreditsExpectation frrCreditedDealExpect({
  Map<String, double>? treasuryCreditCloseTo,
  required double totalProfitTreasury,
  int creditedDealsLength = 1,
  String? owningGpId,
  String? sourceFactionId,
  int? relationScore,
  double? profitRateCloseTo,
  double? profitTreasuryCloseTo,
  bool profitIsZero = false,
  Map<String, double>? treasuryCreditByGpId,
}) => FrrCreditsExpectation(
  creditedDealsLength: creditedDealsLength,
  singleCreditedDealOwningGpId: owningGpId,
  singleCreditedDealSourceFactionId: sourceFactionId,
  singleCreditedDealRelationScore: relationScore,
  singleCreditedDealProfitRateCloseTo: profitRateCloseTo,
  singleCreditedDealProfitTreasuryCloseTo: profitTreasuryCloseTo,
  singleCreditedDealProfitIsZero: profitIsZero,
  treasuryCreditCloseTo: treasuryCreditCloseTo,
  treasuryCreditByGpId: treasuryCreditByGpId,
  totalProfitTreasury: totalProfitTreasury,
);

/// Embassy kickback pin helper (Refs #3939 slice 61).
FrrCreditsExpectation frrKickbackExpect({
  Map<String, double>? embassyKickbackCloseTo,
  Map<String, double>? treasuryCreditCloseTo,
  Iterable<String>? noEmbassyKickbackFor,
  bool treasuryCreditEmpty = false,
  bool embassyKickbackEmpty = false,
  double? totalEmbassyKickback,
  bool sameAsEmpty = false,
}) => FrrCreditsExpectation(
  embassyKickbackCloseTo: embassyKickbackCloseTo,
  treasuryCreditCloseTo: treasuryCreditCloseTo,
  noEmbassyKickbackFor: noEmbassyKickbackFor,
  treasuryCreditEmpty: treasuryCreditEmpty,
  embassyKickbackEmpty: embassyKickbackEmpty,
  totalEmbassyKickback: totalEmbassyKickback,
  sameAsEmpty: sameAsEmpty,
);

/// Data-driven expectations for [FirstRightCreditsResult] scenario rows.
class FrrCreditsExpectation {
  const FrrCreditsExpectation({
    this.empty = false,
    this.sameAsEmpty = false,
    this.creditedDealsEmpty = false,
    this.creditedDealsLength,
    this.treasuryCreditEmpty = false,
    this.treasuryCreditByGpId,
    this.treasuryCreditCloseTo,
    this.treasuryCreditKeysContainAll,
    this.embassyKickbackByGpId,
    this.embassyKickbackCloseTo,
    this.embassyKickbackEmpty = false,
    this.noEmbassyKickbackFor,
    this.noTreasuryCreditFor,
    this.totalProfitTreasury,
    this.totalEmbassyKickback,
    this.singleCreditedDealBuyer,
    this.singleCreditedDealOwningGpId,
    this.singleCreditedDealSourceFactionId,
    this.singleCreditedDealRelationScore,
    this.singleCreditedDealProfitRateCloseTo,
    this.singleCreditedDealProfitTreasuryCloseTo,
    this.singleCreditedDealProfitIsZero = false,
    this.treasuryCreditKeysExact,
    this.custom,
  });

  final bool empty;
  final bool sameAsEmpty;
  final bool creditedDealsEmpty;
  final int? creditedDealsLength;
  final bool treasuryCreditEmpty;
  final Map<String, double>? treasuryCreditByGpId;
  final Map<String, double>? treasuryCreditCloseTo;
  final Iterable<String>? treasuryCreditKeysContainAll;
  final Map<String, double>? embassyKickbackByGpId;
  final Map<String, double>? embassyKickbackCloseTo;
  final bool embassyKickbackEmpty;
  final Iterable<String>? noEmbassyKickbackFor;
  final Iterable<String>? noTreasuryCreditFor;
  final double? totalProfitTreasury;
  final double? totalEmbassyKickback;
  final String? singleCreditedDealBuyer;
  final String? singleCreditedDealOwningGpId;
  final String? singleCreditedDealSourceFactionId;
  final int? singleCreditedDealRelationScore;
  final double? singleCreditedDealProfitRateCloseTo;
  final double? singleCreditedDealProfitTreasuryCloseTo;
  final bool singleCreditedDealProfitIsZero;
  final List<String>? treasuryCreditKeysExact;
  final void Function(FirstRightCreditsResult result)? custom;
}

void assertFrrCreditsExpectation(
  FirstRightCreditsResult result,
  FrrCreditsExpectation expectation,
) {
  if (expectation.empty) {
    expect(result.creditedDeals, isEmpty);
    expect(result.treasuryCreditByGpId, isEmpty);
  }
  if (expectation.sameAsEmpty) {
    expect(result, same(FirstRightCreditsResult.empty));
  }
  if (expectation.creditedDealsEmpty) {
    expect(result.creditedDeals, isEmpty);
  }
  if (expectation.creditedDealsLength != null) {
    expect(result.creditedDeals, hasLength(expectation.creditedDealsLength));
  }
  if (expectation.treasuryCreditEmpty) {
    expect(result.treasuryCreditByGpId, isEmpty);
  }
  if (expectation.treasuryCreditByGpId != null) {
    for (final entry in expectation.treasuryCreditByGpId!.entries) {
      expect(result.treasuryCreditByGpId[entry.key], entry.value);
    }
  }
  if (expectation.treasuryCreditCloseTo != null) {
    for (final entry in expectation.treasuryCreditCloseTo!.entries) {
      expect(
        result.treasuryCreditByGpId[entry.key],
        closeTo(entry.value, 1e-12),
      );
    }
  }
  if (expectation.treasuryCreditKeysContainAll != null) {
    expect(
      result.treasuryCreditByGpId.keys,
      containsAll(expectation.treasuryCreditKeysContainAll!),
    );
  }
  if (expectation.embassyKickbackByGpId != null) {
    for (final entry in expectation.embassyKickbackByGpId!.entries) {
      expect(result.embassyKickbackByGpId[entry.key], entry.value);
    }
  }
  if (expectation.embassyKickbackCloseTo != null) {
    for (final entry in expectation.embassyKickbackCloseTo!.entries) {
      expect(
        result.embassyKickbackByGpId[entry.key],
        closeTo(entry.value, 1e-12),
      );
    }
  }
  if (expectation.embassyKickbackEmpty) {
    expect(result.embassyKickbackByGpId, isEmpty);
  }
  if (expectation.noEmbassyKickbackFor != null) {
    for (final gpId in expectation.noEmbassyKickbackFor!) {
      expect(result.embassyKickbackByGpId.containsKey(gpId), isFalse);
    }
  }
  if (expectation.noTreasuryCreditFor != null) {
    for (final gpId in expectation.noTreasuryCreditFor!) {
      expect(result.treasuryCreditByGpId.containsKey(gpId), isFalse);
    }
  }
  if (expectation.totalProfitTreasury != null) {
    expect(
      result.totalProfitTreasury,
      closeTo(expectation.totalProfitTreasury!, 1e-12),
    );
  }
  if (expectation.totalEmbassyKickback != null) {
    expect(
      result.totalEmbassyKickback,
      closeTo(expectation.totalEmbassyKickback!, 1e-12),
    );
  }
  if (expectation.singleCreditedDealBuyer != null) {
    expect(
      result.creditedDeals.single.deal.buyerFactionId,
      expectation.singleCreditedDealBuyer,
    );
  }
  if (expectation.singleCreditedDealOwningGpId != null) {
    expect(
      result.creditedDeals.single.owningGpId,
      expectation.singleCreditedDealOwningGpId,
    );
  }
  if (expectation.singleCreditedDealSourceFactionId != null) {
    expect(
      result.creditedDeals.single.sourceFactionId,
      expectation.singleCreditedDealSourceFactionId,
    );
  }
  if (expectation.singleCreditedDealRelationScore != null) {
    expect(
      result.creditedDeals.single.relationScore,
      expectation.singleCreditedDealRelationScore,
    );
  }
  if (expectation.singleCreditedDealProfitRateCloseTo != null) {
    expect(
      result.creditedDeals.single.profit.profitRate,
      closeTo(expectation.singleCreditedDealProfitRateCloseTo!, 1e-12),
    );
  }
  if (expectation.singleCreditedDealProfitTreasuryCloseTo != null) {
    expect(
      result.creditedDeals.single.profit.profitTreasury,
      closeTo(expectation.singleCreditedDealProfitTreasuryCloseTo!, 1e-12),
    );
  }
  if (expectation.singleCreditedDealProfitIsZero) {
    expect(result.creditedDeals.single.profit, FirstRightProfit.zero);
  }
  if (expectation.treasuryCreditKeysExact != null) {
    expect(
      result.treasuryCreditByGpId.keys,
      expectation.treasuryCreditKeysExact,
    );
  }
  expectation.custom?.call(result);
}
