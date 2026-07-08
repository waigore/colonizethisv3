// Table-driven purchased-tile index scenarios (Refs #3856).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import 'purchased_tile_index_test_support.dart';

/// One row in [purchasedTileAttributionSemanticsScenarios].
typedef PurchasedTileAttributionSemanticsScenario = ({
  String label,
  void Function() run,
  String? refs,
});

/// Canonical scenarios for [PurchasedTileAttribution] value semantics.
List<PurchasedTileAttributionSemanticsScenario>
purchasedTileAttributionSemanticsScenarios() => [
  (
    label: 'equality holds across all four fields',
    run: _runAttributionEquality,
    refs: null,
  ),
  (
    label: 'inequality on any differing field',
    run: _runAttributionInequality,
    refs: null,
  ),
  (
    label: 'toString surfaces every field for trace logs',
    run: _runAttributionToString,
    refs: null,
  ),
];

void _runAttributionEquality() {
  const a = PurchasedTileAttribution(
    tileKey: 'oldWorld|M1|0|0',
    owningGpId: 'gpA',
    sourceFactionId: 'M1',
    provinceId: 'oldWorld|M1',
  );
  const b = PurchasedTileAttribution(
    tileKey: 'oldWorld|M1|0|0',
    owningGpId: 'gpA',
    sourceFactionId: 'M1',
    provinceId: 'oldWorld|M1',
  );
  expect(a, equals(b));
  expect(a.hashCode, b.hashCode);
}

void _runAttributionInequality() {
  const base = PurchasedTileAttribution(
    tileKey: 'oldWorld|M1|0|0',
    owningGpId: 'gpA',
    sourceFactionId: 'M1',
    provinceId: 'oldWorld|M1',
  );
  const diffTile = PurchasedTileAttribution(
    tileKey: 'oldWorld|M1|1|0',
    owningGpId: 'gpA',
    sourceFactionId: 'M1',
    provinceId: 'oldWorld|M1',
  );
  const diffOwner = PurchasedTileAttribution(
    tileKey: 'oldWorld|M1|0|0',
    owningGpId: 'gpB',
    sourceFactionId: 'M1',
    provinceId: 'oldWorld|M1',
  );
  const diffSource = PurchasedTileAttribution(
    tileKey: 'oldWorld|M1|0|0',
    owningGpId: 'gpA',
    sourceFactionId: 'M2',
    provinceId: 'oldWorld|M1',
  );
  const diffProvince = PurchasedTileAttribution(
    tileKey: 'oldWorld|M1|0|0',
    owningGpId: 'gpA',
    sourceFactionId: 'M1',
    provinceId: 'oldWorld|M2',
  );
  expect(base, isNot(equals(diffTile)));
  expect(base, isNot(equals(diffOwner)));
  expect(base, isNot(equals(diffSource)));
  expect(base, isNot(equals(diffProvince)));
}

void _runAttributionToString() {
  const a = PurchasedTileAttribution(
    tileKey: 'oldWorld|M1|0|0',
    owningGpId: 'gpA',
    sourceFactionId: 'M1',
    provinceId: 'oldWorld|M1',
  );
  final s = a.toString();
  expect(s, contains('oldWorld|M1|0|0'));
  expect(s, contains('gpA'));
  expect(s, contains('M1'));
}

/// One row in [purchasedTileIndexFromGameScenarios].
typedef PurchasedTileIndexFromGameScenario = ({
  String label,
  Game Function() buildGame,
  void Function(PurchasedTileIndex index) verify,
  String? refs,
});

/// Canonical scenarios for [PurchasedTileIndex.fromGame].
List<PurchasedTileIndexFromGameScenario> purchasedTileIndexFromGameScenarios() =>
    [
      (
        label: 'AC-D1-1 — empty world yields empty index',
        buildGame: TestFixtures.minimalGame,
        verify: _verifyEmptyIndex,
        refs: 'D1-1',
      ),
      (
        label: 'AC-D1-2 — minor-owned purchased tile resolves attribution',
        buildGame: minorOwnedPurchasedTileIndexGame,
        verify: _verifyMinorOwnedAttribution,
        refs: 'D1-2',
      ),
      (
        label: 'AC-D1-3 — tribe-owned purchased tile resolves attribution',
        buildGame: tribeOwnedPurchasedTileIndexGame,
        verify: _verifyTribeOwnedAttribution,
        refs: 'D1-3',
      ),
      (
        label: 'AC-D1-4 — GP-owned province excludes attribution (post-conquest)',
        buildGame: gpOwnedProvinceExcludesPurchasedTileGame,
        verify: _verifyGpOwnedProvinceExcludes,
        refs: 'D1-4',
      ),
      (
        label: 'AC-D1-5 — unowned province excludes attribution',
        buildGame: unownedProvincePurchasedTileGame,
        verify: _verifyUnownedProvinceExcludes,
        refs: 'D1-5',
      ),
      (
        label: 'AC-D1-6 — unmapped tile key excludes attribution',
        buildGame: unmappedTileKeyPurchasedTileGame,
        verify: _verifyUnmappedTileKeyExcludes,
        refs: 'D1-6',
      ),
      (
        label: 'AC-D1-7 — determinism: repeated builds return equal attributions',
        buildGame: minorOwnedPurchasedTileIndexGame,
        verify: _verifyDeterminism,
        refs: 'D1-7',
      ),
      (
        label: 'mixed minor + tribe purchases coexist in the same index',
        buildGame: mixedMinorTribePurchasedTileGame,
        verify: _verifyMixedMinorTribe,
        refs: null,
      ),
      (
        label: 'empty owningGpId entry is dropped defensively',
        buildGame: emptyOwningGpPurchasedTileGame,
        verify: _verifyEmptyOwningGpDropped,
        refs: null,
      ),
    ];

void _verifyEmptyIndex(PurchasedTileIndex index) {
  expect(index.length, 0);
  expect(index.isEmpty, isTrue);
  expect(index.isNotEmpty, isFalse);
  expect(index.attributionForTileKey('any'), isNull);
  expect(index.attributions, isEmpty);
}

void _verifyMinorOwnedAttribution(PurchasedTileIndex index) {
  expect(index.length, 1);
  final attribution = index.attributionForTileKey('oldWorld|M1|0|0');
  expect(attribution, isNotNull);
  expect(attribution!.owningGpId, 'gpA');
  expect(attribution.sourceFactionId, 'M1');
  expect(attribution.provinceId, 'oldWorld|M1');
  expect(attribution.tileKey, 'oldWorld|M1|0|0');
}

void _verifyTribeOwnedAttribution(PurchasedTileIndex index) {
  const tileKey = 'oldWorld|T1|0|0';
  const tribeProvinceId = 'oldWorld|T1';
  expect(index.length, 1);
  final attribution = index.attributionForTileKey(tileKey);
  expect(attribution, isNotNull);
  expect(attribution!.sourceFactionId, 'T1');
  expect(attribution.owningGpId, 'gpA');
  expect(attribution.provinceId, tribeProvinceId);
}

void _verifyGpOwnedProvinceExcludes(PurchasedTileIndex index) {
  const tileKey = 'oldWorld|P1|0|0';
  expect(index.length, 0);
  expect(index.attributionForTileKey(tileKey), isNull);
}

void _verifyUnownedProvinceExcludes(PurchasedTileIndex index) {
  const tileKey = 'oldWorld|P1|0|0';
  expect(index.length, 0);
  expect(index.attributionForTileKey(tileKey), isNull);
}

void _verifyUnmappedTileKeyExcludes(PurchasedTileIndex index) {
  const realTileKey = 'oldWorld|M1|0|0';
  const orphanTileKey = 'oldWorld|M1|9|9';
  expect(index.length, 0);
  expect(index.attributionForTileKey(orphanTileKey), isNull);
  expect(index.attributionForTileKey(realTileKey), isNull);
}

void _verifyDeterminism(PurchasedTileIndex index) {
  final game = minorOwnedPurchasedTileIndexGame();
  final first = PurchasedTileIndex.fromGame(game);
  final second = PurchasedTileIndex.fromGame(game);
  expect(index.length, first.length);
  expect(first.length, second.length);
  expect(
    first.attributionForTileKey('oldWorld|M1|0|0'),
    equals(second.attributionForTileKey('oldWorld|M1|0|0')),
  );
}

void _verifyMixedMinorTribe(PurchasedTileIndex index) {
  const minorTileKey = 'oldWorld|M1|0|0';
  const tribeTileKey = 'newWorld|T1|0|0';
  expect(index.length, 2);

  final minorAttr = index.attributionForTileKey(minorTileKey);
  expect(minorAttr, isNotNull);
  expect(minorAttr!.owningGpId, 'gpA');
  expect(minorAttr.sourceFactionId, 'M1');

  final tribeAttr = index.attributionForTileKey(tribeTileKey);
  expect(tribeAttr, isNotNull);
  expect(tribeAttr!.owningGpId, 'gpB');
  expect(tribeAttr.sourceFactionId, 'T1');

  expect(
    index.attributions.map((a) => a.tileKey).toSet(),
    containsAll(<String>[minorTileKey, tribeTileKey]),
  );
}

void _verifyEmptyOwningGpDropped(PurchasedTileIndex index) {
  expect(index.length, 0);
}

/// Builds [PurchasedTileIndex] for one [PurchasedTileIndexFromGameScenario].
PurchasedTileIndex runPurchasedTileIndexFromGameScenario(
  PurchasedTileIndexFromGameScenario scenario,
) {
  return PurchasedTileIndex.fromGame(scenario.buildGame());
}
