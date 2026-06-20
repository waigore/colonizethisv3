import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  const ow = kRegionOldWorld;
  const nw = kRegionNewWorld;
  const aId = '$ow|A';
  const bId = '$ow|B';
  const cId = '$nw|C';

  WorldState buildWorld() => WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(
      provinces: [
        Province(id: aId, regionId: ow, ownerId: 'p1'),
        Province(id: bId, regionId: ow),
      ],
    ),
    newWorld: const RegionData(
      provinces: [Province(id: cId, regionId: nw, ownerId: 'p1')],
    ),
  );

  group('ProvinceOwnerCache.build', () {
    test('provincesOwnedBy returns owned provinces old-world-first in order', () {
      final cache = ProvinceOwnerCache.build(buildWorld());

      final owned = cache.provincesOwnedBy('p1');
      expect(owned.map((p) => p.id).toList(), [aId, cId]);
    });

    test('ownerOf returns owner for owned and null for unowned province', () {
      final cache = ProvinceOwnerCache.build(buildWorld());

      expect(cache.ownerOf(aId), 'p1');
      expect(cache.ownerOf(bId), isNull);
    });

    test('ownerOf returns null for a province absent from both regions', () {
      final cache = ProvinceOwnerCache.build(buildWorld());

      expect(cache.ownerOf('$ow|MISSING'), isNull);
    });

    test('isOwnedBy distinguishes owner, unowned, and wrong owner', () {
      final cache = ProvinceOwnerCache.build(buildWorld());

      expect(cache.isOwnedBy(aId, 'p1'), isTrue);
      expect(cache.isOwnedBy(aId, 'p2'), isFalse);
      expect(cache.isOwnedBy(bId, 'p1'), isFalse);
    });

    test('countOwnedBy counts owned provinces and zero for an absent owner', () {
      final cache = ProvinceOwnerCache.build(buildWorld());

      expect(cache.countOwnedBy('p1'), 2);
      expect(cache.countOwnedBy('p2'), 0);
    });

    test('provincesOwnedByInRegion returns the owner provinces per region', () {
      final cache = ProvinceOwnerCache.build(buildWorld());

      expect(
        cache.provincesOwnedByInRegion('p1', ow).map((p) => p.id).toList(),
        [aId],
      );
      expect(
        cache.provincesOwnedByInRegion('p1', nw).map((p) => p.id).toList(),
        [cId],
      );
    });

    test('provincesOwnedByInRegion is empty for an unowned-in-region owner', () {
      final cache = ProvinceOwnerCache.build(buildWorld());

      expect(cache.provincesOwnedByInRegion('p2', ow), isEmpty);
    });

    test('ownsAnyInRegion reflects per-region ownership', () {
      final cache = ProvinceOwnerCache.build(buildWorld());

      expect(cache.ownsAnyInRegion('p1', ow), isTrue);
      expect(cache.ownsAnyInRegion('p1', nw), isTrue);
      expect(cache.ownsAnyInRegion('p2', ow), isFalse);
    });

    test('countOwnedByInRegion counts per-region owned provinces', () {
      final cache = ProvinceOwnerCache.build(buildWorld());

      expect(cache.countOwnedByInRegion('p1', ow), 1);
      expect(cache.countOwnedByInRegion('p1', nw), 1);
      expect(cache.countOwnedByInRegion('p2', ow), 0);
    });

    test('provincesOwnedByInRegion returns a read-only list', () {
      final cache = ProvinceOwnerCache.build(buildWorld());
      final owned = cache.provincesOwnedByInRegion('p1', ow);

      expect(
        () => owned.add(const Province(id: '$ow|X', regionId: ow)),
        throwsUnsupportedError,
      );
    });

    test('ownerIds lists distinct non-null owners and excludes unowned', () {
      final cache = ProvinceOwnerCache.build(buildWorld());

      expect(cache.ownerIds, ['p1']);
    });

    test('unownedProvinces lists only provinces without an owner', () {
      final cache = ProvinceOwnerCache.build(buildWorld());

      expect(cache.unownedProvinces.map((p) => p.id).toList(), [bId]);
    });

    test('provincesOwnedBy is deterministic across repeated reads', () {
      final cache = ProvinceOwnerCache.build(buildWorld());

      expect(
        cache.provincesOwnedBy('p1').map((p) => p.id).toList(),
        cache.provincesOwnedBy('p1').map((p) => p.id).toList(),
      );
    });

    test('provincesOwnedBy returns an empty list for an unknown owner', () {
      final cache = ProvinceOwnerCache.build(buildWorld());

      expect(cache.provincesOwnedBy('nobody'), isEmpty);
    });

    test('provincesOwnedBy returns a read-only list', () {
      final cache = ProvinceOwnerCache.build(buildWorld());
      final owned = cache.provincesOwnedBy('p1');

      expect(
        () => owned.add(const Province(id: '$ow|X', regionId: ow)),
        throwsUnsupportedError,
      );
    });

    test('ownerIds is a read-only list', () {
      final cache = ProvinceOwnerCache.build(buildWorld());

      expect(() => cache.ownerIds.add('p9'), throwsUnsupportedError);
    });
  });

  group('ProvinceOwnerCache.of', () {
    test('returns the identical cache for the same WorldState instance', () {
      final world = buildWorld();

      expect(
        identical(ProvinceOwnerCache.of(world), ProvinceOwnerCache.of(world)),
        isTrue,
      );
    });

    test('returns a distinct cache for a copyWith-derived WorldState', () {
      final world = buildWorld();
      final next = world.copyWith(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
      );

      expect(
        identical(ProvinceOwnerCache.of(world), ProvinceOwnerCache.of(next)),
        isFalse,
      );
    });
  });
}
