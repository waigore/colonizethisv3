// Compact First Right credits result assertions (Refs #3939 phase 3 slice 12).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

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
    this.custom,
  });

  const FrrCreditsExpectation.emptyResult()
      : empty = true,
        sameAsEmpty = false,
        creditedDealsEmpty = false,
        creditedDealsLength = null,
        treasuryCreditEmpty = false,
        treasuryCreditByGpId = null,
        treasuryCreditCloseTo = null,
        treasuryCreditKeysContainAll = null,
        embassyKickbackByGpId = null,
        embassyKickbackCloseTo = null,
        embassyKickbackEmpty = false,
        noEmbassyKickbackFor = null,
        noTreasuryCreditFor = null,
        totalProfitTreasury = null,
        totalEmbassyKickback = null,
        singleCreditedDealBuyer = null,
        custom = null;

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
      expect(result.treasuryCreditByGpId[entry.key], closeTo(entry.value, 1e-12));
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
      expect(result.embassyKickbackByGpId[entry.key], closeTo(entry.value, 1e-12));
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
    expect(result.totalProfitTreasury, closeTo(expectation.totalProfitTreasury!, 1e-12));
  }
  if (expectation.totalEmbassyKickback != null) {
    expect(result.totalEmbassyKickback, closeTo(expectation.totalEmbassyKickback!, 1e-12));
  }
  if (expectation.singleCreditedDealBuyer != null) {
    expect(result.creditedDeals.single.deal.buyerFactionId, expectation.singleCreditedDealBuyer);
  }
  expectation.custom?.call(result);
}
