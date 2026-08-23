import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/world_test_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void registerCapitalAndGpFallTerminalGpCases() {
  group('applyGreatPowerFall', () {
    test('transfers GP provinces to conqueror when no port province held', () {
      final game = gpCapitalLossGame(
        id: 'g-gp-fall',
        fallenId: 'p1',
        conquerorId: 'p2',
        capitalProvinceId: 'oldWorld|cap',
        capitalOwnerId: 'p2',
        newWorldProvinces: const [
          Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'p1'),
        ],
        units: [capitalTestUnit('u-p1', 'p1', 'oldWorld|cap')],
        fleets: [capitalTestFleet('f-p1', 'p1')],
      );

      final result = applyGreatPowerFall(game, const {'p1': 'oldWorld|cap'});

      expect(result.worldState.tryGetProvince('newWorld|n1')?.ownerId, 'p2');
      expect(result.worldState.fleets.any((f) => f.ownerId == 'p1'), isFalse);
      expect(
        result.worldState.oldWorld.units.any((u) => u.ownerId == 'p1'),
        isFalse,
      );
    });

    test('does not fall when GP still owns a port province', () {
      final game = gpCapitalLossGame(
        id: 'g-gp-port',
        fallenId: 'p1',
        conquerorId: 'p2',
        capitalProvinceId: 'oldWorld|cap',
        capitalOwnerId: 'p2',
        extraOldWorldProvinces: const [
          Province(id: 'oldWorld|port', regionId: 'oldWorld', ownerId: 'p1'),
        ],
        portsByProvinceSeaboard: const {
          'oldWorld|port|north': 'oldWorld|port|0|0',
        },
      );

      final result = applyGreatPowerFall(game, const {'p1': 'oldWorld|cap'});

      expect(result.worldState.tryGetProvince('oldWorld|port')?.ownerId, 'p1');
    });

    test('skips when capital still owned by the player', () {
      final game = gpCapitalLossGame(
        id: 'g-gp-hold',
        fallenId: 'p1',
        conquerorId: 'p2',
        capitalProvinceId: 'oldWorld|cap',
        capitalOwnerId: 'p1',
      );

      final result = applyGreatPowerFall(game, const {'p1': 'oldWorld|cap'});

      expect(result.worldState.tryGetProvince('oldWorld|cap')?.ownerId, 'p1');
    });

    test('skips when capital province has no owner', () {
      final game = capitalLossGame(
        id: 'g-gp-noowner',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|cap', regionId: 'oldWorld'),
        ],
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final result = applyGreatPowerFall(game, const {'p1': 'oldWorld|cap'});

      expect(result.worldState.tryGetProvince('oldWorld|cap')?.ownerId, isNull);
    });
  });

  group('capital fall ProvinceOwnerCache migration (slice 11)', () {
    test('faction terminal region check matches ownsAnyInRegion', () {
      final game = minorCapitalLossGame(
        id: 'g-slice11-minor',
        minorId: 'm1',
        capitalProvinceId: 'oldWorld|mcap',
        capitalOwnerId: 'p2',
        extraOldWorldProvinces: const [
          Province(id: 'oldWorld|m2', regionId: 'oldWorld', ownerId: 'm1'),
        ],
      );

      final cache = ProvinceOwnerCache.of(game.worldState);
      final legacyAny = game.worldState.oldWorld.provinces.any(
        (p) => p.ownerId == 'm1',
      );
      expect(cache.ownsAnyInRegion('m1', kRegionOldWorld), legacyAny);
      expect(legacyAny, isTrue);

      final held = applyFactionTerminalFall(
        game,
        previousCapitalByMinor: const {'m1': 'oldWorld|mcap'},
        previousCapitalByTribe: const {},
      );
      expect(held.minorNations.single.id, 'm1');
    });

    test('GP fall port check matches provincesOwnedBy port intersection', () {
      final game = gpCapitalLossGame(
        id: 'g-slice11-gp-port',
        fallenId: 'p1',
        conquerorId: 'p2',
        capitalProvinceId: 'oldWorld|cap',
        capitalOwnerId: 'p2',
        extraOldWorldProvinces: const [
          Province(id: 'oldWorld|port', regionId: 'oldWorld', ownerId: 'p1'),
        ],
        portsByProvinceSeaboard: const {
          'oldWorld|port|north': 'oldWorld|port|0|0',
        },
      );

      const playerId = 'p1';
      final portsByProvince = <String>{'oldWorld|port'};
      final legacyHasPort = allProvinces(
        game.worldState,
      ).any((p) => p.ownerId == playerId && portsByProvince.contains(p.id));
      final cache = ProvinceOwnerCache.of(game.worldState);
      final projectionHasPort = cache
          .provincesOwnedBy(playerId)
          .any((p) => portsByProvince.contains(p.id));
      expect(projectionHasPort, legacyHasPort);
      expect(projectionHasPort, isTrue);

      final result = applyGreatPowerFall(game, const {'p1': 'oldWorld|cap'});
      expect(result.worldState.tryGetProvince('oldWorld|port')?.ownerId, 'p1');
    });
  });
}
