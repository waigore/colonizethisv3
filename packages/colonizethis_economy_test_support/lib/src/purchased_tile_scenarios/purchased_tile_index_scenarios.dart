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
class PurchasedTileIndexFromGameScenario {
  const PurchasedTileIndexFromGameScenario({
    required this.label,
    required this.buildGame,
    required this.verify,
    this.refs,
  });

  PurchasedTileIndexFromGameScenario.expect({
    required String label,
    required Game Function() buildGame,
    required PurchasedTileIndexExpectation expect,
    String? refs,
  }) : this(
          label: label,
          buildGame: buildGame,
          verify: (index) =>
              assertPurchasedTileIndexExpectation(index, expect),
          refs: refs,
        );

  final String label;
  final Game Function() buildGame;
  final void Function(PurchasedTileIndex index) verify;
  final String? refs;
}

/// Canonical scenarios for [PurchasedTileIndex.fromGame].
List<PurchasedTileIndexFromGameScenario> purchasedTileIndexFromGameScenarios() =>
    [
      PurchasedTileIndexFromGameScenario.expect(
        label: 'AC-D1-1 — empty world yields empty index',
        buildGame: TestFixtures.minimalGame,
        expect: PurchasedTileIndexExpectation(
          length: 0,
          isEmpty: true,
          isNotEmpty: false,
          attributionForTileKeyNull: 'any',
          custom: _verifyEmptyIndexAttributions,
        ),
        refs: 'D1-1',
      ),
      PurchasedTileIndexFromGameScenario.expect(
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
      PurchasedTileIndexFromGameScenario.expect(
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
      PurchasedTileIndexFromGameScenario.expect(
        label: 'AC-D1-4 — GP-owned province excludes attribution (post-conquest)',
        buildGame: gpOwnedProvinceExcludesPurchasedTileGame,
        expect: const PurchasedTileIndexExpectation(
          length: 0,
          attributionForTileKeyNull: 'oldWorld|P1|0|0',
        ),
        refs: 'D1-4',
      ),
      PurchasedTileIndexFromGameScenario.expect(
        label: 'AC-D1-5 — unowned province excludes attribution',
        buildGame: unownedProvincePurchasedTileGame,
        expect: const PurchasedTileIndexExpectation(
          length: 0,
          attributionForTileKeyNull: 'oldWorld|P1|0|0',
        ),
        refs: 'D1-5',
      ),
      PurchasedTileIndexFromGameScenario.expect(
        label: 'AC-D1-6 — unmapped tile key excludes attribution',
        buildGame: unmappedTileKeyPurchasedTileGame,
        expect: PurchasedTileIndexExpectation(
          length: 0,
          custom: _verifyUnmappedTileKeyExcludes,
        ),
        refs: 'D1-6',
      ),
      PurchasedTileIndexFromGameScenario.expect(
        label: 'AC-D1-7 — determinism: repeated builds return equal attributions',
        buildGame: minorOwnedPurchasedTileIndexGame,
        expect: PurchasedTileIndexExpectation(
          custom: _verifyIndexDeterminism,
        ),
        refs: 'D1-7',
      ),
      PurchasedTileIndexFromGameScenario.expect(
        label: 'mixed minor + tribe purchases coexist in the same index',
        buildGame: mixedMinorTribePurchasedTileGame,
        expect: PurchasedTileIndexExpectation(
          length: 2,
          attributionsTileKeysContainAll: [
            'oldWorld|M1|0|0',
            'newWorld|T1|0|0',
          ],
          custom: _verifyMixedMinorTribeAttributions,
        ),
      ),
      PurchasedTileIndexFromGameScenario.expect(
        label: 'empty owningGpId entry is dropped defensively',
        buildGame: emptyOwningGpPurchasedTileGame,
        expect: const PurchasedTileIndexExpectation(length: 0),
      ),
    ];

void _verifyEmptyIndexAttributions(PurchasedTileIndex index) {
  expect(index.attributions, isEmpty);
}

void _verifyUnmappedTileKeyExcludes(PurchasedTileIndex index) {
  expect(index.attributionForTileKey('oldWorld|M1|9|9'), isNull);
  expect(index.attributionForTileKey('oldWorld|M1|0|0'), isNull);
}

void _verifyIndexDeterminism(PurchasedTileIndex index) {
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

void _verifyMixedMinorTribeAttributions(PurchasedTileIndex index) {
  const minorTileKey = 'oldWorld|M1|0|0';
  const tribeTileKey = 'newWorld|T1|0|0';

  final minorAttr = index.attributionForTileKey(minorTileKey);
  expect(minorAttr, isNotNull);
  expect(minorAttr!.owningGpId, 'gpA');
  expect(minorAttr.sourceFactionId, 'M1');

  final tribeAttr = index.attributionForTileKey(tribeTileKey);
  expect(tribeAttr, isNotNull);
  expect(tribeAttr!.owningGpId, 'gpB');
  expect(tribeAttr.sourceFactionId, 'T1');
}

/// Builds [PurchasedTileIndex] for one [PurchasedTileIndexFromGameScenario].
PurchasedTileIndex runPurchasedTileIndexFromGameScenario(
  PurchasedTileIndexFromGameScenario scenario,
) {
  return PurchasedTileIndex.fromGame(scenario.buildGame());
}
