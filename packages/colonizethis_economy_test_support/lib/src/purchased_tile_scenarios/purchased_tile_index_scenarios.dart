// Table-driven purchased-tile index scenarios (Refs #3856, #3939 slice 17).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import 'purchased_tile_expectations.dart';
import 'purchased_tile_index_test_support.dart';

/// One row in [purchasedTileAttributionSemanticsScenarios].
typedef PurchasedTileAttributionSemanticsScenario = ({
  String label,
  void Function() run,
  String? refs,
});

/// Canonical K1 attribution for semantics rows (Refs #3939 slice 56).
const PurchasedTileAttribution _kAttrM1GpA = PurchasedTileAttribution(
  tileKey: 'oldWorld|M1|0|0',
  owningGpId: 'gpA',
  sourceFactionId: 'M1',
  provinceId: 'oldWorld|M1',
);

PurchasedTileAttribution _attr({
  String? tileKey,
  String? owningGpId,
  String? sourceFactionId,
  String? provinceId,
}) => PurchasedTileAttribution(
  tileKey: tileKey ?? _kAttrM1GpA.tileKey,
  owningGpId: owningGpId ?? _kAttrM1GpA.owningGpId,
  sourceFactionId: sourceFactionId ?? _kAttrM1GpA.sourceFactionId,
  provinceId: provinceId ?? _kAttrM1GpA.provinceId,
);

/// Canonical scenarios for [PurchasedTileAttribution] value semantics.
List<PurchasedTileAttributionSemanticsScenario>
purchasedTileAttributionSemanticsScenarios() => [
  (
    label: 'equality holds across all four fields',
    run: () {
      final a = _kAttrM1GpA;
      final b = _attr();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    },
    refs: null,
  ),
  (
    label: 'inequality on any differing field',
    run: () {
      expect(_kAttrM1GpA, isNot(equals(_attr(tileKey: 'oldWorld|M1|1|0'))));
      expect(_kAttrM1GpA, isNot(equals(_attr(owningGpId: 'gpB'))));
      expect(_kAttrM1GpA, isNot(equals(_attr(sourceFactionId: 'M2'))));
      expect(_kAttrM1GpA, isNot(equals(_attr(provinceId: 'oldWorld|M2'))));
    },
    refs: null,
  ),
  (
    label: 'toString surfaces every field for trace logs',
    run: () {
      final s = _kAttrM1GpA.toString();
      expect(s, contains('oldWorld|M1|0|0'));
      expect(s, contains('gpA'));
      expect(s, contains('M1'));
    },
    refs: null,
  ),
];

/// One row in [purchasedTileIndexFromGameScenarios] (Refs #3939 slice 64).
typedef PurchasedTileIndexFromGameScenario = ({
  String label,
  Game Function() buildGame,
  void Function(PurchasedTileIndex index) verify,
  String? refs,
});

/// Compact expect-wired row (Refs #3939 slice 59).
PurchasedTileIndexFromGameScenario purchasedTileIndexRow({
  required String label,
  required Game Function() buildGame,
  required PurchasedTileIndexExpectation expect,
  String? refs,
}) => (
  label: label,
  buildGame: buildGame,
  verify: (index) => assertPurchasedTileIndexExpectation(
    index,
    expect,
    gameForDeterminismRerun: expect.deterministicIndexRerun
        ? buildGame()
        : null,
  ),
  refs: refs,
);

/// Canonical scenarios for [PurchasedTileIndex.fromGame].
List<PurchasedTileIndexFromGameScenario>
purchasedTileIndexFromGameScenarios() => [
  purchasedTileIndexRow(
    label: 'AC-D1-1 — empty world yields empty index',
    buildGame: TestFixtures.minimalGame,
    expect: const PurchasedTileIndexExpectation(
      length: 0,
      isEmpty: true,
      isNotEmpty: false,
      attributionForTileKeyNull: 'any',
      attributionsEmpty: true,
    ),
    refs: 'D1-1',
  ),
  purchasedTileIndexRow(
    label: 'AC-D1-2 — minor-owned purchased tile resolves attribution',
    buildGame: minorOwnedPurchasedTileIndexGame,
    expect: const PurchasedTileIndexExpectation(
      length: 1,
      singleAttribution: PurchasedTileAttributionExpectation(
        tileKey: 'oldWorld|M1|0|0',
        owningGpId: 'gpA',
        sourceFactionId: 'M1',
        provinceId: 'oldWorld|M1',
      ),
    ),
    refs: 'D1-2',
  ),
  purchasedTileIndexRow(
    label: 'AC-D1-3 — tribe-owned purchased tile resolves attribution',
    buildGame: tribeOwnedPurchasedTileIndexGame,
    expect: const PurchasedTileIndexExpectation(
      length: 1,
      singleAttribution: PurchasedTileAttributionExpectation(
        tileKey: 'oldWorld|T1|0|0',
        owningGpId: 'gpA',
        sourceFactionId: 'T1',
        provinceId: 'oldWorld|T1',
      ),
    ),
    refs: 'D1-3',
  ),
  purchasedTileIndexRow(
    label: 'AC-D1-4 — GP-owned province excludes attribution (post-conquest)',
    buildGame: gpOwnedProvinceExcludesPurchasedTileGame,
    expect: const PurchasedTileIndexExpectation(
      length: 0,
      attributionForTileKeyNull: 'oldWorld|P1|0|0',
    ),
    refs: 'D1-4',
  ),
  purchasedTileIndexRow(
    label: 'AC-D1-5 — unowned province excludes attribution',
    buildGame: unownedProvincePurchasedTileGame,
    expect: const PurchasedTileIndexExpectation(
      length: 0,
      attributionForTileKeyNull: 'oldWorld|P1|0|0',
    ),
    refs: 'D1-5',
  ),
  purchasedTileIndexRow(
    label: 'AC-D1-6 — unmapped tile key excludes attribution',
    buildGame: unmappedTileKeyPurchasedTileGame,
    expect: const PurchasedTileIndexExpectation(
      length: 0,
      attributionForTileKeysNull: ['oldWorld|M1|9|9', 'oldWorld|M1|0|0'],
    ),
    refs: 'D1-6',
  ),
  purchasedTileIndexRow(
    label: 'AC-D1-7 — determinism: repeated builds return equal attributions',
    buildGame: minorOwnedPurchasedTileIndexGame,
    expect: const PurchasedTileIndexExpectation(
      deterministicIndexRerun: true,
      deterministicRerunTileKey: 'oldWorld|M1|0|0',
    ),
    refs: 'D1-7',
  ),
  purchasedTileIndexRow(
    label: 'mixed minor + tribe purchases coexist in the same index',
    buildGame: mixedMinorTribePurchasedTileGame,
    expect: const PurchasedTileIndexExpectation(
      length: 2,
      attributionsTileKeysContainAll: ['oldWorld|M1|0|0', 'newWorld|T1|0|0'],
      multiAttributions: [
        PurchasedTileAttributionExpectation(
          tileKey: 'oldWorld|M1|0|0',
          owningGpId: 'gpA',
          sourceFactionId: 'M1',
        ),
        PurchasedTileAttributionExpectation(
          tileKey: 'newWorld|T1|0|0',
          owningGpId: 'gpB',
          sourceFactionId: 'T1',
        ),
      ],
    ),
  ),
  purchasedTileIndexRow(
    label: 'empty owningGpId entry is dropped defensively',
    buildGame: emptyOwningGpPurchasedTileGame,
    expect: const PurchasedTileIndexExpectation(length: 0),
  ),
];

/// Builds [PurchasedTileIndex] for one [PurchasedTileIndexFromGameScenario].
PurchasedTileIndex runPurchasedTileIndexFromGameScenario(
  PurchasedTileIndexFromGameScenario scenario,
) {
  return PurchasedTileIndex.fromGame(scenario.buildGame());
}
