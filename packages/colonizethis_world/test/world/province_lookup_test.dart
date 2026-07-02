// ignore_for_file: deprecated_member_use

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/world/province_owner_cache.dart';
import 'package:colonizethis_world/src/world_constants.dart'
    show kRegionNewWorld, kRegionOldWorld;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

WorldState _world() => TestFixtures.worldStateAtOrdersPhase(
  oldWorld: const RegionData(
    provinces: [
      Province(
        id: 'oldWorld|p1',
        regionId: 'oldWorld',
        ownerId: 'gp1',
        fortLevel: 2,
      ),
      Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp1'),
    ],
  ),
  newWorld: const RegionData(
    provinces: [
      Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'gp2'),
    ],
  ),
  tileKeysByRegionAndProvince: const {
    'oldWorld': {
      'oldWorld|p1': ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
    },
  },
);

const turn = TurnState(phase: TurnPhase.orders, turnNumber: 0);

final pOld = Province(
  id: 'oldWorld|P1',
  regionId: kRegionOldWorld,
  ownerId: 'gp1',
);
final pNew = Province(
  id: 'newWorld|P2',
  regionId: kRegionNewWorld,
  ownerId: 'gp2',
);

final pOld1 = Province(
  id: 'oldWorld|P1',
  regionId: kRegionOldWorld,
  ownerId: 'gp1',
);
final pOld2Owned = Province(
  id: 'oldWorld|P2',
  regionId: kRegionOldWorld,
  ownerId: 'gp2',
);
final pOld2Bare = Province(id: 'oldWorld|P2', regionId: kRegionOldWorld);
final pNew1Gp1 = Province(
  id: 'newWorld|P3',
  regionId: kRegionNewWorld,
  ownerId: 'gp1',
);
final pNew1Gp2 = Province(
  id: 'newWorld|P3',
  regionId: kRegionNewWorld,
  ownerId: 'gp2',
);
final pNew2 = Province(
  id: 'newWorld|P4',
  regionId: kRegionNewWorld,
  ownerId: 'gp2',
);

WorldState makeWorld({
  List<Province> oldProvinces = const [],
  List<Province> newProvinces = const [],
}) {
  return TestFixtures.worldStateAtOrdersPhase(
    turnNumber: 0,
    oldWorld: RegionData(provinces: oldProvinces),
    newWorld: RegionData(provinces: newProvinces),
  );
}

void main() {
group('province-list helpers', () {
    const provinces = [
      Province(id: 'oldWorld|p1', regionId: 'oldWorld', fortLevel: 2),
      Province(id: 'oldWorld|p2', regionId: 'oldWorld', fortLevel: 0),
    ];

    test('provinceListContainsProvinceId', () {
      expect(provinceListContainsProvinceId(provinces, 'oldWorld|p1'), isTrue);
      expect(provinceListContainsProvinceId(provinces, 'oldWorld|x'), isFalse);
    });

    test('decrementFortLevelForProvinceIdIfPresent decrements and clamps', () {
      final next = decrementFortLevelForProvinceIdIfPresent(
        provinces,
        'oldWorld|p1',
      );
      expect(next.firstWhere((p) => p.id == 'oldWorld|p1').fortLevel, 1);
      // Already at 0 stays clamped at 0.
      final clamped = decrementFortLevelForProvinceIdIfPresent(
        provinces,
        'oldWorld|p2',
      );
      expect(clamped.firstWhere((p) => p.id == 'oldWorld|p2').fortLevel, 0);
    });

    test('decrementFortLevelForProvinceIdIfPresent returns same list if absent', () {
      final next = decrementFortLevelForProvinceIdIfPresent(
        provinces,
        'oldWorld|missing',
      );
      expect(next, same(provinces));
    });
  });

  group('standalone lookup functions', () {
    final world = _world();

    test('resolveToFullProvinceId returns prefixed, throws on short id', () {
      expect(resolveToFullProvinceId(world, 'oldWorld|p1'), 'oldWorld|p1');
      // Unprefixed id passed via variable so the throw-behavior is exercised
      // without tripping the unprefixed-province-id-literal AST lint.
      const shortId = 'p1';
      expect(() => resolveToFullProvinceId(world, shortId), throwsStateError);
    });

    test('getProvinceByRegion success and failure modes', () {
      expect(getProvinceByRegion(world, 'oldWorld', 'p1').ownerId, 'gp1');
      expect(
        () => getProvinceByRegion(world, 'badRegion', 'p1'),
        throwsStateError,
      );
      expect(
        () => getProvinceByRegion(world, 'oldWorld', 'missing'),
        throwsStateError,
      );
    });

    test('getProvince resolves a prefixed id', () {
      expect(getProvince(world, 'newWorld|n1').ownerId, 'gp2');
    });

    test('resolveProvinceRowForOwnershipTransfer matches legacy short id', () {
      final legacyWorld = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: const RegionData(
          provinces: [Province(id: 'shortId', regionId: 'oldWorld')],
        ),
      );
      final hit = resolveProvinceRowForOwnershipTransfer(
        legacyWorld,
        'shortId',
      );
      expect(hit!.canonicalProvinceId, 'shortId');
      expect(
        resolveProvinceRowForOwnershipTransfer(legacyWorld, 'nope'),
        isNull,
      );
    });

    test('landTileKeysForProvinceBucket returns a mutable copy of bucket keys', () {
      final keys = landTileKeysForProvinceBucket(
        world,
        'oldWorld',
        'oldWorld|p1',
      );
      expect(keys, ['oldWorld|p1|0|0', 'oldWorld|p1|1|0']);
      // Mutating the result must not affect the source bucket.
      keys.add('mutation');
      expect(
        landTileKeysForProvinceBucket(world, 'oldWorld', 'oldWorld|p1'),
        ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
      );
      expect(
        landTileKeysForProvinceBucket(world, 'oldWorld', 'oldWorld|p2'),
        isEmpty,
      );
    });

    test('landTileKeysForProvinceBucket is strict full-id only by default', () {
      // Legacy/fixture bucket keyed by local id only; the default (strict)
      // lookup must not fall back to it (Refs #3403 Phase 1).
      final legacy = TestFixtures.worldStateAtOrdersPhase(
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'p1': ['oldWorld|p1|0|0'],
          },
        },
      );
      expect(
        landTileKeysForProvinceBucket(legacy, 'oldWorld', 'oldWorld|p1'),
        isEmpty,
      );
    });

    test('landTileKeysForProvinceBucket opt-in fallback resolves local-id bucket', () {
      final legacy = TestFixtures.worldStateAtOrdersPhase(
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'p1': ['oldWorld|p1|0|0'],
          },
        },
      );
      expect(
        landTileKeysForProvinceBucket(
          legacy,
          'oldWorld',
          'oldWorld|p1',
          allowLocalIdFallback: true,
        ),
        ['oldWorld|p1|0|0'],
      );
    });

    test('landTileKeysForProvinceBucket fallback never shadows a full-id bucket', () {
      final mixed = TestFixtures.worldStateAtOrdersPhase(
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'oldWorld|p1': ['oldWorld|p1|0|0'],
            'p1': ['oldWorld|p1|9|9'],
          },
        },
      );
      expect(
        landTileKeysForProvinceBucket(
          mixed,
          'oldWorld',
          'oldWorld|p1',
          allowLocalIdFallback: true,
        ),
        ['oldWorld|p1|0|0'],
      );
    });

    test('landTileKeysForProvinceBucket fallback returns empty when neither bucket exists', () {
      final empty = TestFixtures.worldStateAtOrdersPhase(
        tileKeysByRegionAndProvince: const {'oldWorld': {}},
      );
      expect(
        landTileKeysForProvinceBucket(
          empty,
          'oldWorld',
          'oldWorld|p1',
          allowLocalIdFallback: true,
        ),
        isEmpty,
      );
      expect(
        landTileKeysForProvinceBucket(empty, 'oldWorld', 'oldWorld|p1'),
        isEmpty,
      );
    });
  });

  group('WorldStateProvinceLookup extension', () {
    final world = _world();

    test('tryGetRegionIdForLegacyProvinceKey resolves both regions', () {
      expect(world.tryGetRegionIdForLegacyProvinceKey('oldWorld|p1'), 'oldWorld');
      expect(world.tryGetRegionIdForLegacyProvinceKey('newWorld|n1'), 'newWorld');
      expect(world.tryGetRegionIdForLegacyProvinceKey('ghost'), isNull);
    });

    test('resolveToFullProvinceId throws on short id', () {
      // Unprefixed id passed via variable so the throw-behavior is exercised
      // without tripping the unprefixed-province-id-literal AST lint.
      const shortId = 'p1';
      expect(() => world.resolveToFullProvinceId(shortId), throwsStateError);
      expect(world.resolveToFullProvinceId('oldWorld|p1'), 'oldWorld|p1');
    });

    test('toFullProvinceId prefixes local ids', () {
      expect(world.toFullProvinceId('oldWorld', 'p1'), 'oldWorld|p1');
      expect(world.toFullProvinceId('oldWorld', 'oldWorld|p1'), 'oldWorld|p1');
    });

    test('getProvinceByRegion and getProvince via extension', () {
      expect(world.getProvinceByRegion('oldWorld', 'p1').ownerId, 'gp1');
      expect(() => world.getProvinceByRegion('bad', 'p1'), throwsStateError);
      expect(
        () => world.getProvinceByRegion('oldWorld', 'missing'),
        throwsStateError,
      );
      expect(world.getProvince('oldWorld|p1').ownerId, 'gp1');
    });

    test('updateRegionById throws on unknown region', () {
      expect(
        () => world.updateRegionById('mars', (r) => r),
        throwsStateError,
      );
    });
  });

  group('oldWorldProvinceCountOwnedBy', () {
    test('counts only old-world provinces of the faction', () {
      final game = TestFixtures.singlePlayerGame(
        const Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        gameId: 'g',
        worldState: _world(),
      );
      expect(oldWorldProvinceCountOwnedBy(game, 'gp1'), 2);
      expect(oldWorldProvinceCountOwnedBy(game, 'gp2'), 0);
    });

    // Refs #3393 Phase 6b (slice 5) — behaviour-preserving migration onto
    // `ProvinceOwnerCache.countOwnedByInRegion`. The projection-backed count
    // equals both the prior `world.oldWorld.provinces` owner scan and the
    // cache accessor for the same faction id.
    test('matches the projection accessor and the prior old-world scan', () {
      final world = _world();
      final game = TestFixtures.singlePlayerGame(
        const Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        gameId: 'g',
        worldState: world,
      );
      final cache = ProvinceOwnerCache.of(world);

      int manualOldWorldCount(String id) =>
          world.oldWorld.provinces.where((p) => p.ownerId == id).length;

      for (final id in ['gp1', 'gp2', 'unowned']) {
        expect(
          oldWorldProvinceCountOwnedBy(game, id),
          cache.countOwnedByInRegion(id, kRegionOldWorld),
          reason: 'projection-backed count for $id',
        );
        expect(
          oldWorldProvinceCountOwnedBy(game, id),
          manualOldWorldCount(id),
          reason: 'matches prior old-world owner scan for $id',
        );
      }
    });
  });

  group('WorldStateProvinceLookup.allProvincesById (Refs #2836 item 4)', () {
    test('contains provinces from both regions keyed by id', () {
      final ws = makeWorld(oldProvinces: [pOld], newProvinces: [pNew]);

      expect(ws.allProvincesById.length, 2);
      expect(ws.allProvincesById['oldWorld|P1'], pOld);
      expect(ws.allProvincesById['newWorld|P2'], pNew);
    });

    test('prefers old-world province when both regions share an id', () {
      final dupOld = Province(
        id: 'dup',
        regionId: kRegionOldWorld,
        ownerId: 'gp1',
      );
      final dupNew = Province(
        id: 'dup',
        regionId: kRegionNewWorld,
        ownerId: 'gp2',
      );
      final ws = makeWorld(oldProvinces: [dupOld], newProvinces: [dupNew]);

      expect(ws.allProvincesById['dup']!.ownerId, 'gp1');
    });

    test(
      'returns the identical map across repeated reads for one WorldState',
      () {
        final ws = makeWorld(oldProvinces: [pOld], newProvinces: [pNew]);

        final first = ws.allProvincesById;
        final second = ws.allProvincesById;

        expect(identical(first, second), isTrue);
      },
    );

    test('different WorldState copies receive their own cached map', () {
      final wsA = makeWorld(oldProvinces: [pOld], newProvinces: [pNew]);
      final wsB = wsA.copyWith(turnState: turn);

      expect(identical(wsA.allProvincesById, wsB.allProvincesById), isFalse);
    });

    test('mutation of returned map throws UnsupportedError', () {
      final ws = makeWorld(oldProvinces: [pOld]);

      expect(
        () => ws.allProvincesById['oldWorld|P1'] = pOld,
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('empty regions yield empty map', () {
      final ws = makeWorld();

      expect(ws.allProvincesById, isEmpty);
    });
  });

  group('WorldStateProvinceLookup.provincesForRegion (Refs #2836 AC 5)', () {
    test(
      'returns Old World provinces only when regionId == kRegionOldWorld',
      () {
        final ws = makeWorld(
          oldProvinces: [pOld1, pOld2Owned],
          newProvinces: [pNew1Gp1],
        );

        final result = ws.provincesForRegion(kRegionOldWorld).toList();

        expect(result, [pOld1, pOld2Owned]);
      },
    );

    test(
      'returns New World provinces only when regionId == kRegionNewWorld',
      () {
        final ws = makeWorld(
          oldProvinces: [pOld1, pOld2Owned],
          newProvinces: [pNew1Gp1],
        );

        final result = ws.provincesForRegion(kRegionNewWorld).toList();

        expect(result, [pNew1Gp1]);
      },
    );

    test('returns an empty iterable when the region is unknown', () {
      final ws = makeWorld(
        oldProvinces: [pOld1, pOld2Owned],
        newProvinces: [pNew1Gp1],
      );

      final result = ws.provincesForRegion('mars').toList();

      expect(result, isEmpty);
    });

    test('returns an empty iterable for an empty regionId', () {
      final ws = makeWorld(oldProvinces: [pOld1]);

      final result = ws.provincesForRegion('').toList();

      expect(result, isEmpty);
    });

    test('returns an empty iterable for a region with no provinces', () {
      final ws = makeWorld(oldProvinces: [pOld1]);

      final result = ws.provincesForRegion(kRegionNewWorld).toList();

      expect(result, isEmpty);
    });

    test('returns the same Iterable contents on repeated reads', () {
      final ws = makeWorld(oldProvinces: [pOld1, pOld2Owned]);

      final first = ws.provincesForRegion(kRegionOldWorld).toList();
      final second = ws.provincesForRegion(kRegionOldWorld).toList();

      expect(first, second);
    });
  });

  group(
    'WorldStateProvinceLookup.mutableProvinceListsByRegion '
    '(Refs #2836 AC 5)',
    () {
      test('returns both regions keyed by canonical region ids', () {
        final ws = makeWorld(
          oldProvinces: [pOld1, pOld2Owned],
          newProvinces: [pNew1Gp1, pNew2],
        );

        final result = ws.mutableProvinceListsByRegion();

        expect(result.keys.toSet(), {kRegionOldWorld, kRegionNewWorld});
        expect(result[kRegionOldWorld], [pOld1, pOld2Owned]);
        expect(result[kRegionNewWorld], [pNew1Gp1, pNew2]);
      });

      test('returns empty lists for empty regions', () {
        final ws = makeWorld();

        final result = ws.mutableProvinceListsByRegion();

        expect(result[kRegionOldWorld], isEmpty);
        expect(result[kRegionNewWorld], isEmpty);
      });

      test(
        'returned lists are independent copies — mutating does not change '
        'source WorldState',
        () {
          final ws = makeWorld(
            oldProvinces: [pOld1, pOld2Owned],
            newProvinces: [pNew1Gp1],
          );

          final result = ws.mutableProvinceListsByRegion();
          result[kRegionOldWorld]!.clear();
          result[kRegionNewWorld]!.add(pNew2);

          expect(ws.oldWorld.provinces, [pOld1, pOld2Owned]);
          expect(ws.newWorld.provinces, [pNew1Gp1]);
        },
      );

      test(
        'two successive calls produce independent list copies (no shared '
        'mutable state between calls)',
        () {
          final ws = makeWorld(
            oldProvinces: [pOld1, pOld2Owned],
            newProvinces: [pNew1Gp1],
          );

          final first = ws.mutableProvinceListsByRegion();
          final second = ws.mutableProvinceListsByRegion();

          expect(
            identical(first[kRegionOldWorld], second[kRegionOldWorld]),
            isFalse,
          );
          expect(
            identical(first[kRegionNewWorld], second[kRegionNewWorld]),
            isFalse,
          );

          first[kRegionOldWorld]!.add(pOld1);
          expect(second[kRegionOldWorld], [pOld1, pOld2Owned]);
        },
      );
    },
  );

  group('WorldStateProvinceLookup.regionsInOrder (Refs #3710)', () {
    test('yields old world first, then new world, with their region data', () {
      final ws = makeWorld(oldProvinces: [pOld1], newProvinces: [pNew1Gp2]);

      final entries = ws.regionsInOrder.toList();

      expect(entries.map((e) => e.regionId), [
        kRegionOldWorld,
        kRegionNewWorld,
      ]);
      expect(identical(entries[0].region, ws.oldWorld), isTrue);
      expect(identical(entries[1].region, ws.newWorld), isTrue);
    });

    test('still yields both regions when one has no provinces', () {
      final ws = makeWorld(oldProvinces: [pOld1]);

      final entries = ws.regionsInOrder.toList();

      expect(entries.map((e) => e.regionId), [
        kRegionOldWorld,
        kRegionNewWorld,
      ]);
      expect(entries[1].region.provinces, isEmpty);
    });
  });

  group('cross-region traversal stays consistent with regionsInOrder', () {
    test(
      'allProvinces equals regionsInOrder province concatenation '
      '(old-then-new)',
      () {
        final ws = makeWorld(
          oldProvinces: [pOld1, pOld2Bare],
          newProvinces: [pNew1Gp2],
        );

        final viaRegions = [
          for (final entry in ws.regionsInOrder) ...entry.region.provinces,
        ];

        expect(ws.allProvinces().toList(), viaRegions);
        expect(allProvinces(ws).toList(), viaRegions);
        expect(ws.allProvinces().toList(), [pOld1, pOld2Bare, pNew1Gp2]);
      },
    );

    test('forEachRegion visits regions in regionsInOrder order', () {
      final ws = makeWorld(oldProvinces: [pOld1], newProvinces: [pNew1Gp2]);

      final seen = <String>[];
      ws.forEachRegion((regionId, _) => seen.add(regionId));

      expect(seen, ws.regionsInOrder.map((e) => e.regionId).toList());
      expect(seen, [kRegionOldWorld, kRegionNewWorld]);
    });
  });

}
