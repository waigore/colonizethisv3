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

/// Old (pre-migration) `anyMinorOwnsOldWorld` predicate from
/// `computeDiplomaticCandidateScores`: a nested O(provinces x minors) scan.
bool _manualAnyMinorOwnsOldWorld(Game game) =>
    game.worldState.oldWorld.provinces.any(
      (p) =>
          p.ownerId != null &&
          p.ownerId!.isNotEmpty &&
          game.minorNations.any((m) => m.id == p.ownerId),
    );

/// New (slice 7) `anyMinorOwnsOldWorld` predicate: projection-backed.
bool _projectionAnyMinorOwnsOldWorld(Game game) => game.minorNations.any(
  (m) => ProvinceOwnerCache.of(
    game.worldState,
  ).ownsAnyInRegion(m.id, kRegionOldWorld),
);

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

  group('anyMinorOwnsOldWorld slice-7 migration', () {
    Game gameWith({
      required String oldWorldOwner,
      required String newWorldMinorOwner,
    }) => Game(
      id: 'g-slice7',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: oldWorldOwner.isEmpty ? null : oldWorldOwner,
            ),
            const Province(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              ownerId: 'gp1',
            ),
          ],
        ),
        newWorld: RegionData(
          provinces: [
            Province(
              id: 'newWorld|n1',
              regionId: 'newWorld',
              ownerId: newWorldMinorOwner,
            ),
          ],
        ),
      ),
      players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
      minorNations: const [
        MinorNation(id: 'minor1', displayName: 'M1'),
        MinorNation(id: 'minor2', displayName: 'M2'),
      ],
    );

    test('returns true when a minor owns an old-world province', () {
      final game = gameWith(
        oldWorldOwner: 'minor1',
        newWorldMinorOwner: 'minor2',
      );

      expect(_projectionAnyMinorOwnsOldWorld(game), isTrue);
      expect(
        _projectionAnyMinorOwnsOldWorld(game),
        _manualAnyMinorOwnsOldWorld(game),
      );
    });

    test('returns false when only a non-minor owns old-world provinces', () {
      // Old-world provinces are owned by gp1 only; minor2 owns a new-world
      // province but no old-world province.
      final game = gameWith(oldWorldOwner: 'gp1', newWorldMinorOwner: 'minor2');

      expect(_projectionAnyMinorOwnsOldWorld(game), isFalse);
      expect(
        _projectionAnyMinorOwnsOldWorld(game),
        _manualAnyMinorOwnsOldWorld(game),
      );
    });

    test('returns false for an empty/unowned old-world province', () {
      // `oldWorld|p1` is unowned (null); the other old-world province is gp1's.
      final game = gameWith(oldWorldOwner: '', newWorldMinorOwner: 'minor2');

      expect(_projectionAnyMinorOwnsOldWorld(game), isFalse);
      expect(
        _projectionAnyMinorOwnsOldWorld(game),
        _manualAnyMinorOwnsOldWorld(game),
      );
    });
  });

  // Refs #3393 Phase 6b (slice 10) — `planColonialCivilian` iterates the active
  // player's owned New World provinces. The migration replaces the
  // `world.newWorld.provinces.where((p) => p.ownerId == playerId)` scan with
  // `ProvinceOwnerCache.provincesOwnedByInRegion(playerId, kRegionNewWorld)`.
  // These tests pin the projection set equals the prior per-region owner scan.
  group('planColonialCivilian owned-NW-province slice-10 migration', () {
    WorldState buildWorld() => const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: 'oldWorld|a', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          Province(id: 'newWorld|a', regionId: 'newWorld', ownerId: 'gp1'),
          Province(id: 'newWorld|b', regionId: 'newWorld', ownerId: 'gp2'),
          Province(id: 'newWorld|c', regionId: 'newWorld', ownerId: 'gp1'),
        ],
      ),
    );

    Set<String> manualOwnedNewWorldProvinceIds(WorldState world, String id) => {
      for (final p in world.newWorld.provinces)
        if (p.ownerId == id) p.id,
    };

    Set<String> projectionOwnedNewWorldProvinceIds(
      WorldState world,
      String id,
    ) => {
      for (final p in ProvinceOwnerCache.of(
        world,
      ).provincesOwnedByInRegion(id, kRegionNewWorld))
        p.id,
    };

    test(
      'projection set equals the prior newWorld owner scan for an owner',
      () {
        final world = buildWorld();

        expect(
          projectionOwnedNewWorldProvinceIds(world, 'gp1'),
          manualOwnedNewWorldProvinceIds(world, 'gp1'),
        );
        expect(projectionOwnedNewWorldProvinceIds(world, 'gp1'), {
          'newWorld|a',
          'newWorld|c',
        });
      },
    );

    test('projection set is empty for a player owning no NW provinces', () {
      final world = buildWorld();

      // gp3 owns nothing; the OW-only owner is excluded from the NW region set.
      expect(
        projectionOwnedNewWorldProvinceIds(world, 'gp3'),
        manualOwnedNewWorldProvinceIds(world, 'gp3'),
      );
      expect(projectionOwnedNewWorldProvinceIds(world, 'gp3'), isEmpty);
    });
  });
}
