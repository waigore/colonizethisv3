
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

/// SPEC: SPEC/game/world-market-first-right-of-refusal.md
/// § Acceptance criteria → Purchased-tile index (D1) ACs D1-1 through D1-7.
void main() {
  group('PurchasedTileAttribution value semantics', () {
    test('equality holds across all four fields', () {
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
    });

    test('inequality on any differing field', () {
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
    });

    test('toString surfaces every field for trace logs', () {
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
    });
  });

  group('PurchasedTileIndex.fromGame', () {
    test('AC-D1-1 — empty world yields empty index', () {
      final game = TestFixtures.minimalGame();
      final index = PurchasedTileIndex.fromGame(game);
      expect(index.length, 0);
      expect(index.isEmpty, isTrue);
      expect(index.isNotEmpty, isFalse);
      expect(index.attributionForTileKey('any'), isNull);
      expect(index.attributions, isEmpty);
    });

    test('AC-D1-2 — minor-owned purchased tile resolves attribution', () {
      final game = _minorOwnedScenario();
      final index = PurchasedTileIndex.fromGame(game);
      expect(index.length, 1);
      final attribution = index.attributionForTileKey('oldWorld|M1|0|0');
      expect(attribution, isNotNull);
      expect(attribution!.owningGpId, 'gpA');
      expect(attribution.sourceFactionId, 'M1');
      expect(attribution.provinceId, 'oldWorld|M1');
      expect(attribution.tileKey, 'oldWorld|M1|0|0');
    });

    test('AC-D1-3 — tribe-owned purchased tile resolves attribution', () {
      const ow = 'oldWorld';
      const tribeProvinceId = '$ow|T1';
      const tileKey = '$ow|T1|0|0';
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'gpA', displayName: 'GP A', isHuman: true)],
        oldWorld: const RegionData(
          provinces: [
            Province(id: tribeProvinceId, regionId: ow, ownerId: 'T1'),
          ],
        ),
        tileKeysByRegionAndProvince: const {
          ow: {
            tribeProvinceId: [tileKey],
          },
        },
        tribes: const [Tribe(id: 'T1', displayName: 'Tribe 1')],
        purchasedTilesByTileKey: const {tileKey: 'gpA'},
      );
      final index = PurchasedTileIndex.fromGame(game);
      expect(index.length, 1);
      final attribution = index.attributionForTileKey(tileKey);
      expect(attribution, isNotNull);
      expect(attribution!.sourceFactionId, 'T1');
      expect(attribution.owningGpId, 'gpA');
      expect(attribution.provinceId, tribeProvinceId);
    });

    test(
      'AC-D1-4 — GP-owned province excludes attribution (post-conquest)',
      () {
        const ow = 'oldWorld';
        const provinceId = '$ow|P1';
        const tileKey = '$ow|P1|0|0';
        // Purchased tile whose containing province is now owned by gpB
        // (e.g. gpA bought the tile then gpB conquered the province).
        final game = TestFixtures.minimalGame(
          players: const [
            Player(id: 'gpA', displayName: 'GP A', isHuman: true),
            Player(id: 'gpB', displayName: 'GP B', isHuman: false),
          ],
          oldWorld: const RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'gpB')],
          ),
          tileKeysByRegionAndProvince: const {
            ow: {
              provinceId: [tileKey],
            },
          },
          purchasedTilesByTileKey: const {tileKey: 'gpA'},
          // No minor/tribe declared for gpB; membership lookup excludes it.
        );
        final index = PurchasedTileIndex.fromGame(game);
        expect(index.length, 0);
        expect(index.attributionForTileKey(tileKey), isNull);
      },
    );

    test('AC-D1-5 — unowned province excludes attribution', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$ow|P1|0|0';
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'gpA', displayName: 'GP A', isHuman: true)],
        oldWorld: const RegionData(
          provinces: [Province(id: provinceId, regionId: ow)],
        ),
        tileKeysByRegionAndProvince: const {
          ow: {
            provinceId: [tileKey],
          },
        },
        purchasedTilesByTileKey: const {tileKey: 'gpA'},
      );
      final index = PurchasedTileIndex.fromGame(game);
      expect(index.length, 0);
      expect(index.attributionForTileKey(tileKey), isNull);
    });

    test('AC-D1-6 — unmapped tile key excludes attribution', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|M1';
      const realTileKey = '$ow|M1|0|0';
      const orphanTileKey = '$ow|M1|9|9';
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'gpA', displayName: 'GP A', isHuman: true)],
        oldWorld: const RegionData(
          provinces: [Province(id: provinceId, regionId: ow, ownerId: 'M1')],
        ),
        tileKeysByRegionAndProvince: const {
          ow: {
            provinceId: [realTileKey],
          },
        },
        minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
        // Orphan tile key has no entry in tileKeysByRegionAndProvince.
        purchasedTilesByTileKey: const {orphanTileKey: 'gpA'},
      );
      final index = PurchasedTileIndex.fromGame(game);
      expect(index.length, 0);
      expect(index.attributionForTileKey(orphanTileKey), isNull);
      expect(index.attributionForTileKey(realTileKey), isNull);
    });

    test(
      'AC-D1-7 — determinism: repeated builds return equal attributions',
      () {
        final game = _minorOwnedScenario();
        final first = PurchasedTileIndex.fromGame(game);
        final second = PurchasedTileIndex.fromGame(game);
        expect(first.length, second.length);
        expect(
          first.attributionForTileKey('oldWorld|M1|0|0'),
          equals(second.attributionForTileKey('oldWorld|M1|0|0')),
        );
      },
    );

    test('mixed minor + tribe purchases coexist in the same index', () {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      const minorProvinceId = '$ow|M1';
      const tribeProvinceId = '$nw|T1';
      const minorTileKey = '$ow|M1|0|0';
      const tribeTileKey = '$nw|T1|0|0';
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'gpA', displayName: 'GP A', isHuman: true),
          Player(id: 'gpB', displayName: 'GP B', isHuman: false),
        ],
        oldWorld: const RegionData(
          provinces: [
            Province(id: minorProvinceId, regionId: ow, ownerId: 'M1'),
          ],
        ),
        newWorld: const RegionData(
          provinces: [
            Province(id: tribeProvinceId, regionId: nw, ownerId: 'T1'),
          ],
        ),
        tileKeysByRegionAndProvince: const {
          ow: {
            minorProvinceId: [minorTileKey],
          },
          nw: {
            tribeProvinceId: [tribeTileKey],
          },
        },
        minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
        tribes: const [Tribe(id: 'T1', displayName: 'Tribe 1')],
        purchasedTilesByTileKey: const {
          minorTileKey: 'gpA',
          tribeTileKey: 'gpB',
        },
      );
      final index = PurchasedTileIndex.fromGame(game);
      expect(index.length, 2);

      final minorAttr = index.attributionForTileKey(minorTileKey);
      expect(minorAttr, isNotNull);
      expect(minorAttr!.owningGpId, 'gpA');
      expect(minorAttr.sourceFactionId, 'M1');

      final tribeAttr = index.attributionForTileKey(tribeTileKey);
      expect(tribeAttr, isNotNull);
      expect(tribeAttr!.owningGpId, 'gpB');
      expect(tribeAttr.sourceFactionId, 'T1');

      // Snapshot iterable surfaces both entries.
      expect(
        index.attributions.map((a) => a.tileKey).toSet(),
        containsAll(<String>[minorTileKey, tribeTileKey]),
      );
    });

    test('empty owningGpId entry is dropped defensively', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|M1';
      const tileKey = '$ow|M1|0|0';
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'gpA', displayName: 'GP A', isHuman: true)],
        oldWorld: const RegionData(
          provinces: [Province(id: provinceId, regionId: ow, ownerId: 'M1')],
        ),
        tileKeysByRegionAndProvince: const {
          ow: {
            provinceId: [tileKey],
          },
        },
        minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
        // Empty owningGpId — should be filtered out (no FRR target).
        purchasedTilesByTileKey: const {tileKey: ''},
      );
      final index = PurchasedTileIndex.fromGame(game);
      expect(index.length, 0);
    });
  });
}

/// Canonical minor-owned purchased-tile scenario used by AC-D1-2 and
/// AC-D1-7. A single tile in `oldWorld|M1` was previously purchased by
/// `gpA` and the province is still owned by minor `M1`.
Game _minorOwnedScenario() {
  const ow = 'oldWorld';
  const minorProvinceId = '$ow|M1';
  const tileKey = '$ow|M1|0|0';
  return TestFixtures.minimalGame(
    players: const [Player(id: 'gpA', displayName: 'GP A', isHuman: true)],
    oldWorld: const RegionData(
      provinces: [Province(id: minorProvinceId, regionId: ow, ownerId: 'M1')],
    ),
    tileKeysByRegionAndProvince: const {
      ow: {
        minorProvinceId: [tileKey],
      },
    },
    minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
    purchasedTilesByTileKey: const {tileKey: 'gpA'},
  );
}
