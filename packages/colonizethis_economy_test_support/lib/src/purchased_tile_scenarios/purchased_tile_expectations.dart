// Compact purchased-tile index and riches assertions (Refs #3939 phase 3 slice 17).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Data-driven expectations for [PurchasedTileIndexFromGameScenario] rows.
class PurchasedTileIndexExpectation {
  const PurchasedTileIndexExpectation({
    this.length,
    this.isEmpty,
    this.isNotEmpty,
    this.attributionForTileKeyNull,
    this.singleAttribution,
    this.attributionsTileKeysContainAll,
    this.custom,
  });

  final int? length;
  final bool? isEmpty;
  final bool? isNotEmpty;
  final String? attributionForTileKeyNull;
  final PurchasedTileAttributionExpectation? singleAttribution;
  final Iterable<String>? attributionsTileKeysContainAll;
  final void Function(PurchasedTileIndex index)? custom;
}

class PurchasedTileAttributionExpectation {
  const PurchasedTileAttributionExpectation({
    required this.tileKey,
    this.owningGpId,
    this.sourceFactionId,
    this.provinceId,
  });

  final String tileKey;
  final String? owningGpId;
  final String? sourceFactionId;
  final String? provinceId;
}

void assertPurchasedTileIndexExpectation(
  PurchasedTileIndex index,
  PurchasedTileIndexExpectation expectation,
) {
  if (expectation.length != null) {
    expect(index.length, expectation.length);
  }
  if (expectation.isEmpty != null) {
    expect(index.isEmpty, expectation.isEmpty);
  }
  if (expectation.isNotEmpty != null) {
    expect(index.isNotEmpty, expectation.isNotEmpty);
  }
  if (expectation.attributionForTileKeyNull != null) {
    expect(
      index.attributionForTileKey(expectation.attributionForTileKeyNull!),
      isNull,
    );
  }
  if (expectation.singleAttribution != null) {
    final attr = index.attributionForTileKey(
      expectation.singleAttribution!.tileKey,
    );
    expect(attr, isNotNull);
    if (expectation.singleAttribution!.owningGpId != null) {
      expect(attr!.owningGpId, expectation.singleAttribution!.owningGpId);
    }
    if (expectation.singleAttribution!.sourceFactionId != null) {
      expect(attr!.sourceFactionId, expectation.singleAttribution!.sourceFactionId);
    }
    if (expectation.singleAttribution!.provinceId != null) {
      expect(attr!.provinceId, expectation.singleAttribution!.provinceId);
    }
    expect(attr!.tileKey, expectation.singleAttribution!.tileKey);
  }
  if (expectation.attributionsTileKeysContainAll != null) {
    expect(
      index.attributions.map((a) => a.tileKey).toSet(),
      containsAll(expectation.attributionsTileKeysContainAll!),
    );
  }
  expectation.custom?.call(index);
}

/// Data-driven expectations for [PurchasedTileRichesScenario] rows.
class PurchasedTileRichesExpectation {
  const PurchasedTileRichesExpectation({
    this.indexLength,
    this.creditsLength,
    this.creditsEmpty = false,
    this.treasuryCreditEmpty = false,
    this.equalsEmpty = false,
    this.isEmpty,
    this.singleCredit,
    this.treasuryCreditByGpId,
    this.treasuryCreditCloseTo,
    this.totalTreasuryCredit,
    this.totalTreasuryCreditCloseTo,
    this.custom,
  });

  final int? indexLength;
  final int? creditsLength;
  final bool creditsEmpty;
  final bool treasuryCreditEmpty;
  final bool equalsEmpty;
  final bool? isEmpty;
  final PurchasedTileRichesCreditExpectation? singleCredit;
  final Map<String, int>? treasuryCreditByGpId;
  final Map<String, int>? treasuryCreditCloseTo;
  final int? totalTreasuryCredit;
  final int? totalTreasuryCreditCloseTo;
  final void Function(
    PurchasedTileRichesResult result,
    PurchasedTileIndex index,
    Game game,
  )?
  custom;
}

class PurchasedTileRichesCreditExpectation {
  const PurchasedTileRichesCreditExpectation({
    this.tileKey,
    this.owningGpId,
    this.sourceFactionId,
    this.commodityId,
    this.units,
    this.treasuryDelta,
    this.treasuryDeltaCloseTo,
  });

  final String? tileKey;
  final String? owningGpId;
  final String? sourceFactionId;
  final String? commodityId;
  final int? units;
  final int? treasuryDelta;
  final int? treasuryDeltaCloseTo;
}

void assertPurchasedTileRichesExpectation(
  PurchasedTileRichesResult result,
  PurchasedTileIndex index,
  Game game,
  PurchasedTileRichesExpectation expectation,
) {
  if (expectation.indexLength != null) {
    expect(index.length, expectation.indexLength);
  }
  if (expectation.creditsEmpty) {
    expect(result.credits, isEmpty);
  }
  if (expectation.treasuryCreditEmpty) {
    expect(result.treasuryCreditByGpId, isEmpty);
  }
  if (expectation.creditsLength != null) {
    expect(result.credits, hasLength(expectation.creditsLength));
  }
  if (expectation.equalsEmpty) {
    expect(result, equals(PurchasedTileRichesResult.empty));
  }
  if (expectation.isEmpty != null) {
    expect(result.isEmpty, expectation.isEmpty);
  }
  if (expectation.singleCredit != null) {
    final credit = result.credits.single;
    final pin = expectation.singleCredit!;
    if (pin.tileKey != null) {
      expect(credit.tileKey, equals(pin.tileKey));
    }
    if (pin.owningGpId != null) {
      expect(credit.owningGpId, equals(pin.owningGpId));
    }
    if (pin.sourceFactionId != null) {
      expect(credit.sourceFactionId, equals(pin.sourceFactionId));
    }
    if (pin.commodityId != null) {
      expect(credit.commodityId, equals(pin.commodityId));
    }
    if (pin.units != null) {
      expect(credit.units, equals(pin.units));
    }
    if (pin.treasuryDelta != null) {
      expect(credit.treasuryDelta, equals(pin.treasuryDelta));
    }
    if (pin.treasuryDeltaCloseTo != null) {
      expect(credit.treasuryDelta, equals(pin.treasuryDeltaCloseTo));
    }
  }
  if (expectation.treasuryCreditByGpId != null) {
    expect(result.treasuryCreditByGpId, equals(expectation.treasuryCreditByGpId));
  }
  if (expectation.treasuryCreditCloseTo != null) {
    for (final entry in expectation.treasuryCreditCloseTo!.entries) {
      expect(result.treasuryCreditByGpId[entry.key], equals(entry.value));
    }
  }
  if (expectation.totalTreasuryCredit != null) {
    expect(result.totalTreasuryCredit, equals(expectation.totalTreasuryCredit));
  }
  if (expectation.totalTreasuryCreditCloseTo != null) {
    expect(
      result.totalTreasuryCredit,
      equals(expectation.totalTreasuryCreditCloseTo),
    );
  }
  expectation.custom?.call(result, index, game);
}
