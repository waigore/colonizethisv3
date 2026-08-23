// Refs #3393 Phase 6b (slice 4) — behaviour-preserving migration of the
// `colonizethis_ai` per-region owner scans onto `ProvinceOwnerCache`
// (SPEC/program/worldstate-projection.md § Phase 6b). These tests assert the
// per-region accessors reached through the narrow AI contract
// (`package:colonizethis_logic/ai_api.dart`) return exactly the per-region
// owner sets the prior `world.<region>.provinces.any/where` scans produced.

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart'
    show globalNewWorldHasNonGpOwnership;
import 'package:colonizethis_logic/ai_api.dart'
    show ProvinceOwnerCache, kRegionNewWorld;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Set<String> _manualOwnedNewWorldProvinceIds(WorldState world, String id) => {
  for (final p in world.newWorld.provinces)
    if (p.ownerId == id) p.id,
};

Set<String> _projectionOwnedNewWorldProvinceIds(
  WorldState world,
  String id,
) => {
  for (final p in ProvinceOwnerCache.of(
    world,
  ).provincesOwnedByInRegion(id, kRegionNewWorld))
    p.id,
};


void registerProvinceOwnerCacheRegionMigrationTailCases() {

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

    test('projection set is empty for a player owning no NW provinces', () {
      final world = buildWorld();

      // gp3 owns nothing; the OW-only owner is excluded from the NW region set.
      expect(
        _projectionOwnedNewWorldProvinceIds(world, 'gp3'),
        _manualOwnedNewWorldProvinceIds(world, 'gp3'),
      );
      expect(_projectionOwnedNewWorldProvinceIds(world, 'gp3'), isEmpty);
    });
  });

  // Refs #3393 Phase 6b (slice 12) — `globalNewWorldHasNonGpOwnership` scans
  // every NW province once per COLONIAL-lite phase guard. The migration reads
  // unowned NW provinces and non-GP NW owners from `ProvinceOwnerCache`.
  group('globalNewWorldHasNonGpOwnership slice-12 migration', () {
    Game gameWithNwProvinces({
      required List<Province> nwProvinces,
      List<Player> players = const [
        Player(id: 'gp1', displayName: 'GP1', isHuman: false),
        Player(id: 'gp2', displayName: 'GP2', isHuman: false),
      ],
      List<MinorNation> minorNations = const [],
      List<Tribe> tribes = const [],
    }) => Game(
      id: 'slice12-nw-ownership',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 120),
        oldWorld: const RegionData(),
        newWorld: RegionData(provinces: nwProvinces),
      ),
      players: players,
      minorNations: minorNations,
      tribes: tribes,
    );

    bool manualGlobalNewWorldHasNonGpOwnership(Game game) {
      bool isGreatPower(String ownerId) =>
          game.players.any((player) => player.id == ownerId);

      for (final p in game.worldState.newWorld.provinces) {
        final owner = p.ownerId;
        if (owner == null || owner.isEmpty) return true;
        if (!isGreatPower(owner)) return true;
      }
      return false;
    }

    void expectParity(Game game) {
      expect(
        globalNewWorldHasNonGpOwnership(game),
        manualGlobalNewWorldHasNonGpOwnership(game),
      );
    }

    test('true when a tribe owns a NW province', () {
      final game = gameWithNwProvinces(
        nwProvinces: const [
          Province(id: 'newWorld|a', regionId: 'newWorld', ownerId: 'tribe1'),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
      );
      expectParity(game);
      expect(globalNewWorldHasNonGpOwnership(game), isTrue);
    });

    test('true when a NW province is unowned', () {
      final game = gameWithNwProvinces(
        nwProvinces: const [
          Province(id: 'newWorld|a', regionId: 'newWorld'),
        ],
      );
      expectParity(game);
      expect(globalNewWorldHasNonGpOwnership(game), isTrue);
    });

    test('false when every NW province is GP-owned', () {
      final game = gameWithNwProvinces(
        nwProvinces: const [
          Province(id: 'newWorld|a', regionId: 'newWorld', ownerId: 'gp1'),
          Province(id: 'newWorld|b', regionId: 'newWorld', ownerId: 'gp2'),
        ],
      );
      expectParity(game);
      expect(globalNewWorldHasNonGpOwnership(game), isFalse);
    });
  });

  // Refs #3393 Phase 6b (slice 13) — `planDevelopCivilian` seeds its
  // owned-province set by scanning both regions
  // (`[oldWorld, newWorld].provinces.where((p) => p.ownerId == playerId)`).
  // The migration replaces that scan with
  // `ProvinceOwnerCache.provincesOwnedBy(playerId)` (all regions). These tests
  // pin the projection set equals the prior both-region owner scan.
  group('planDevelopCivilian owned-province slice-13 migration', () {
    WorldState buildWorld() => const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 145),
      oldWorld: RegionData(
        provinces: [
          Province(id: 'oldWorld|a', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(id: 'oldWorld|b', regionId: 'oldWorld', ownerId: 'gp2'),
          Province(id: 'oldWorld|c', regionId: 'oldWorld'),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          Province(id: 'newWorld|a', regionId: 'newWorld', ownerId: 'gp1'),
          Province(id: 'newWorld|b', regionId: 'newWorld', ownerId: 'gp2'),
        ],
      ),
    );

    Set<String> manualOwnedProvinceIds(WorldState world, String id) => {
      for (final region in <RegionData>[world.oldWorld, world.newWorld])
        for (final p in region.provinces)
          if (p.ownerId == id) p.id,
    };

    Set<String> projectionOwnedProvinceIds(WorldState world, String id) => {
      for (final p in ProvinceOwnerCache.of(world).provincesOwnedBy(id)) p.id,
    };

    test('projection set equals the prior both-region owner scan', () {
      final world = buildWorld();

      expect(
        projectionOwnedProvinceIds(world, 'gp1'),
        manualOwnedProvinceIds(world, 'gp1'),
      );
      expect(projectionOwnedProvinceIds(world, 'gp1'), {
        'oldWorld|a',
        'newWorld|a',
      });
    });

    test('projection set is empty for a player owning no provinces', () {
      final world = buildWorld();

      // gp3 owns nothing; unowned provinces (null ownerId) never match an id.
      expect(
        projectionOwnedProvinceIds(world, 'gp3'),
        manualOwnedProvinceIds(world, 'gp3'),
      );
      expect(projectionOwnedProvinceIds(world, 'gp3'), isEmpty);
    });
  });
}
