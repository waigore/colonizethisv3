// Compact purchased-tile index and riches assertions (Refs #3939 phase 3 slice 17).

import 'package:colonizethis_data/colonizethis_data.dart';
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
    this.attributionForTileKeysNull,
    this.attributionsEmpty = false,
    this.singleAttribution,
    this.multiAttributions,
    this.attributionsTileKeysContainAll,
    this.deterministicIndexRerun = false,
    this.deterministicRerunTileKey,
  });

  final int? length;
  final bool? isEmpty;
  final bool? isNotEmpty;
  final String? attributionForTileKeyNull;
  final Iterable<String>? attributionForTileKeysNull;
  final bool attributionsEmpty;
  final PurchasedTileAttributionExpectation? singleAttribution;
  final Iterable<PurchasedTileAttributionExpectation>? multiAttributions;
  final Iterable<String>? attributionsTileKeysContainAll;
  final bool deterministicIndexRerun;
  final String? deterministicRerunTileKey;
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
  PurchasedTileIndexExpectation expectation, {
  Game? gameForDeterminismRerun,
}) {
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
  if (expectation.attributionForTileKeysNull != null) {
    for (final tileKey in expectation.attributionForTileKeysNull!) {
      expect(index.attributionForTileKey(tileKey), isNull);
    }
  }
  if (expectation.attributionsEmpty) {
    expect(index.attributions, isEmpty);
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
  if (expectation.multiAttributions != null) {
    for (final pin in expectation.multiAttributions!) {
      final attr = index.attributionForTileKey(pin.tileKey);
      expect(attr, isNotNull);
      if (pin.owningGpId != null) {
        expect(attr!.owningGpId, pin.owningGpId);
      }
      if (pin.sourceFactionId != null) {
        expect(attr!.sourceFactionId, pin.sourceFactionId);
      }
      if (pin.provinceId != null) {
        expect(attr!.provinceId, pin.provinceId);
      }
    }
  }
  if (expectation.attributionsTileKeysContainAll != null) {
    expect(
      index.attributions.map((a) => a.tileKey).toSet(),
      containsAll(expectation.attributionsTileKeysContainAll!),
    );
  }
  if (expectation.deterministicIndexRerun) {
    final game = gameForDeterminismRerun;
    expect(game, isNotNull, reason: 'deterministicIndexRerun requires game');
    final first = PurchasedTileIndex.fromGame(game!);
    final second = PurchasedTileIndex.fromGame(game);
    expect(index.length, first.length);
    expect(first.length, second.length);
    if (expectation.deterministicRerunTileKey != null) {
      expect(
        first.attributionForTileKey(expectation.deterministicRerunTileKey!),
        equals(second.attributionForTileKey(expectation.deterministicRerunTileKey!)),
      );
    }
  }
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
    this.deterministicRichesRerun = false,
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
  final bool deterministicRichesRerun;
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
  PurchasedTileRichesExpectation expectation, {
  Map<String, TileMapResult> tileMapByRegion = const {},
  double richesCashMultiplier = 1.0,
}) {
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
  if (expectation.deterministicRichesRerun) {
    final r2 = computePurchasedTileRichesCredits(
      game: game,
      tileMapByRegion: tileMapByRegion,
      purchasedTileIndex: index,
      richesCashMultiplier: richesCashMultiplier,
    );
    expect(result.credits.length, equals(r2.credits.length));
    expect(result.totalTreasuryCredit, equals(r2.totalTreasuryCredit));
    expect(result.treasuryCreditByGpId, equals(r2.treasuryCreditByGpId));
  }
}
