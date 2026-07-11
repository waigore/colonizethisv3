part of 'capital_test.dart';

void _capital_and_gp_fall_terminal_testTests() {
  group('applyFactionTerminalFall (Minor)', () {
    test('transfers provinces and assets to conqueror and removes faction', () {
      final game = capitalLossGame(
        id: 'g-minor-fall',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'p2'),
        ],
        newWorldProvinces: const [
          Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'm1'),
        ],
        units: [_unit('u-m', 'm1', 'oldWorld|mcap')],
        fleets: [_fleet('f-m', 'm1')],
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        minorNations: const [MinorNation(id: 'm1')],
      );

      final result = applyFactionTerminalFall(
        game,
        previousCapitalByMinor: const {'m1': 'oldWorld|mcap'},
        previousCapitalByTribe: const {},
      );

      expect(result.minorNations, isEmpty);
      expect(result.worldState.tryGetProvince('newWorld|n1')?.ownerId, 'p2');
      expect(
        result.worldState.oldWorld.units.any((u) => u.ownerId == 'm1'),
        isFalse,
      );
      expect(result.worldState.fleets.any((f) => f.ownerId == 'm1'), isFalse);
    });

    test('does not fall when faction still owns capital province', () {
      final game = capitalLossGame(
        id: 'g-minor-hold',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'm1'),
        ],
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        minorNations: const [MinorNation(id: 'm1')],
      );

      final result = applyFactionTerminalFall(
        game,
        previousCapitalByMinor: const {'m1': 'oldWorld|mcap'},
        previousCapitalByTribe: const {},
      );

      expect(result.minorNations.single.id, 'm1');
    });

    test('does not fall when faction still owns a province in the region', () {
      final game = capitalLossGame(
        id: 'g-minor-region',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'p2'),
          Province(id: 'oldWorld|m2', regionId: 'oldWorld', ownerId: 'm1'),
        ],
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        minorNations: const [MinorNation(id: 'm1')],
      );

      final result = applyFactionTerminalFall(
        game,
        previousCapitalByMinor: const {'m1': 'oldWorld|mcap'},
        previousCapitalByTribe: const {},
      );

      expect(result.minorNations.single.id, 'm1');
    });

    test('skips when previous capital province is missing', () {
      final game = capitalLossGame(
        id: 'g-minor-missing',
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        minorNations: const [MinorNation(id: 'm1')],
      );

      final result = applyFactionTerminalFall(
        game,
        previousCapitalByMinor: const {'m1': 'oldWorld|ghost'},
        previousCapitalByTribe: const {},
      );

      expect(result.minorNations.single.id, 'm1');
    });

    test('skips faction not present in the game', () {
      final game = capitalLossGame(
        id: 'g-minor-absent',
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
      );

      final result = applyFactionTerminalFall(
        game,
        previousCapitalByMinor: const {'mX': 'oldWorld|mcap'},
        previousCapitalByTribe: const {},
      );

      expect(result.minorNations, isEmpty);
    });
  });

  group('applyFactionTerminalFall (Tribe)', () {
    test('transfers tribe provinces to conqueror and removes tribe', () {
      final game = capitalLossGame(
        id: 'g-tribe-fall',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|t2', regionId: 'oldWorld', ownerId: 't1'),
        ],
        newWorldProvinces: const [
          Province(id: 'newWorld|tcap', regionId: 'newWorld', ownerId: 'p2'),
        ],
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        tribes: const [Tribe(id: 't1')],
      );

      final result = applyFactionTerminalFall(
        game,
        previousCapitalByMinor: const {},
        previousCapitalByTribe: const {'t1': 'newWorld|tcap'},
      );

      expect(result.tribes, isEmpty);
      expect(result.worldState.tryGetProvince('oldWorld|t2')?.ownerId, 'p2');
    });
  });

  group('applyGreatPowerFall', () {
    test('transfers GP provinces to conqueror when no port province held', () {
      final game = capitalLossGame(
        id: 'g-gp-fall',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p2'),
        ],
        newWorldProvinces: const [
          Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'p1'),
        ],
        units: [_unit('u-p1', 'p1', 'oldWorld|cap')],
        fleets: [_fleet('f-p1', 'p1')],
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
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
      final game = capitalLossGame(
        id: 'g-gp-port',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p2'),
          Province(id: 'oldWorld|port', regionId: 'oldWorld', ownerId: 'p1'),
        ],
        portsByProvinceSeaboard: const {
          'oldWorld|port|north': 'oldWorld|port|0|0',
        },
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );

      final result = applyGreatPowerFall(game, const {'p1': 'oldWorld|cap'});

      expect(result.worldState.tryGetProvince('oldWorld|port')?.ownerId, 'p1');
    });

    test('skips when capital still owned by the player', () {
      final game = capitalLossGame(
        id: 'g-gp-hold',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p1'),
        ],
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
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
    test(
      'faction terminal region check matches ownsAnyInRegion',
      () {
        final game = capitalLossGame(
          id: 'g-slice11-minor',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|mcap',
              regionId: 'oldWorld',
              ownerId: 'p2',
            ),
            Province(
              id: 'oldWorld|m2',
              regionId: 'oldWorld',
              ownerId: 'm1',
            ),
          ],
          players: const [
            Player(id: 'p2', displayName: 'P2', isHuman: true),
          ],
          minorNations: const [MinorNation(id: 'm1')],
        );

        final cache = ProvinceOwnerCache.of(game.worldState);
        final legacyAny = game.worldState.oldWorld.provinces.any(
          (p) => p.ownerId == 'm1',
        );
        expect(
          cache.ownsAnyInRegion('m1', kRegionOldWorld),
          legacyAny,
        );
        expect(legacyAny, isTrue);

        final held = applyFactionTerminalFall(
          game,
          previousCapitalByMinor: const {'m1': 'oldWorld|mcap'},
          previousCapitalByTribe: const {},
        );
        expect(held.minorNations.single.id, 'm1');
      },
    );

    test(
      'GP fall port check matches provincesOwnedBy port intersection',
      () {
        final game = capitalLossGame(
          id: 'g-slice11-gp-port',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|cap',
              regionId: 'oldWorld',
              ownerId: 'p2',
            ),
            Province(
              id: 'oldWorld|port',
              regionId: 'oldWorld',
              ownerId: 'p1',
            ),
          ],
          portsByProvinceSeaboard: const {
            'oldWorld|port|north': 'oldWorld|port|0|0',
          },
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: false),
          ],
        );

        const playerId = 'p1';
        final portsByProvince = <String>{'oldWorld|port'};
        final legacyHasPort = allProvinces(game.worldState).any(
          (p) => p.ownerId == playerId && portsByProvince.contains(p.id),
        );
        final cache = ProvinceOwnerCache.of(game.worldState);
        final projectionHasPort = cache.provincesOwnedBy(playerId).any(
          (p) => portsByProvince.contains(p.id),
        );
        expect(projectionHasPort, legacyHasPort);
        expect(projectionHasPort, isTrue);

        final result = applyGreatPowerFall(
          game,
          const {'p1': 'oldWorld|cap'},
        );
        expect(
          result.worldState.tryGetProvince('oldWorld|port')?.ownerId,
          'p1',
        );
      },
    );
  });
}
