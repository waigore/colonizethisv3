// Refs #3393 Phase 6b (slice 4) — behaviour-preserving migration of the
// `colonizethis_ai` per-region owner scans onto `ProvinceOwnerCache`
// (SPEC/program/worldstate-projection.md § Phase 6b). These tests assert the
// per-region accessors reached through the narrow AI contract
// (`package:colonizethis_logic/ai_api.dart`) return exactly the per-region
// owner sets the prior `world.<region>.provinces.any/where` scans produced.

import 'package:colonizethis_logic/ai_api.dart'
    show ProvinceOwnerCache, kRegionNewWorld, kRegionOldWorld;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('ProvinceOwnerCache per-region AI migration', () {
    WorldState buildWorld() => WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|a', regionId: 'oldWorld', ownerId: 'minor1'),
          Province(id: 'oldWorld|b', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(id: 'newWorld|a', regionId: 'newWorld', ownerId: 'p1'),
          Province(id: 'newWorld|b', regionId: 'newWorld', ownerId: 'p1'),
          Province(id: 'newWorld|c', regionId: 'newWorld', ownerId: 'minor2'),
        ],
      ),
    );

    bool manualOwnsOldWorld(WorldState world, String id) =>
        world.oldWorld.provinces.any((p) => p.ownerId == id);

    int manualNewWorldCount(WorldState world, String id) =>
        world.newWorld.provinces.where((p) => p.ownerId == id).length;

    test('ownsAnyInRegion(oldWorld) matches the prior oldWorld.any scan', () {
      final world = buildWorld();
      final cache = ProvinceOwnerCache.of(world);

      expect(
        cache.ownsAnyInRegion('minor1', kRegionOldWorld),
        manualOwnsOldWorld(world, 'minor1'),
      );
      expect(cache.ownsAnyInRegion('minor1', kRegionOldWorld), isTrue);

      // minor2 owns only a new-world province, so it owns no old-world province.
      expect(
        cache.ownsAnyInRegion('minor2', kRegionOldWorld),
        manualOwnsOldWorld(world, 'minor2'),
      );
      expect(cache.ownsAnyInRegion('minor2', kRegionOldWorld), isFalse);
    });

    test('countOwnedByInRegion(newWorld) matches the prior newWorld count', () {
      final world = buildWorld();
      final cache = ProvinceOwnerCache.of(world);

      expect(
        cache.countOwnedByInRegion('p1', kRegionNewWorld),
        manualNewWorldCount(world, 'p1'),
      );
      expect(cache.countOwnedByInRegion('p1', kRegionNewWorld), 2);

      expect(
        cache.countOwnedByInRegion('gp1', kRegionNewWorld),
        manualNewWorldCount(world, 'gp1'),
      );
      expect(cache.countOwnedByInRegion('gp1', kRegionNewWorld), 0);
    });
  });
}
