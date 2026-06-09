import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/capital_and_gp_fall.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_test/test.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// Exercises terminal fall transfer for Great Powers, Minor Nations, and
/// Tribes in `lib/src/world/capital_and_gp_fall_terminal.dart`.
/// SPEC/game/capital-and-connectivity § terminal fall.
Unit _unit(String id, String ownerId, String provinceId) => Unit(
  id: id,
  type: 'grenadiers',
  ownerId: ownerId,
  locationProvinceId: provinceId,
);

Fleet _fleet(String id, String ownerId) =>
    Fleet(id: id, ownerId: ownerId, seaZoneId: 's1', regionId: 'oldWorld');

void main() {
  group('applyFactionTerminalFall (Minor)', () {
    test('transfers provinces and assets to conqueror and removes faction', () {
      final game = Game(
        id: 'g-minor-fall',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'p2'),
            ],
            units: [_unit('u-m', 'm1', 'oldWorld|mcap')],
          ),
          newWorld: const RegionData(
            provinces: [
              Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'm1'),
            ],
          ),
          fleets: [_fleet('f-m', 'm1')],
        ),
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
      final game = Game(
        id: 'g-minor-hold',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'm1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
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
      final game = Game(
        id: 'g-minor-region',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'p2'),
              Province(id: 'oldWorld|m2', regionId: 'oldWorld', ownerId: 'm1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
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
      final game = Game(
        id: 'g-minor-missing',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
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
      final game = Game(
        id: 'g-minor-absent',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
        minorNations: const [],
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
      final game = Game(
        id: 'g-tribe-fall',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|t2', regionId: 'oldWorld', ownerId: 't1'),
            ],
          ),
          newWorld: const RegionData(
            provinces: [
              Province(id: 'newWorld|tcap', regionId: 'newWorld', ownerId: 'p2'),
            ],
          ),
        ),
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
      final game = Game(
        id: 'g-gp-fall',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p2'),
            ],
            units: [_unit('u-p1', 'p1', 'oldWorld|cap')],
          ),
          newWorld: const RegionData(
            provinces: [
              Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'p1'),
            ],
          ),
          fleets: [_fleet('f-p1', 'p1')],
        ),
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
      final game = Game(
        id: 'g-gp-port',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p2'),
              Province(id: 'oldWorld|port', regionId: 'oldWorld', ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
          portsByProvinceSeaboard: {'oldWorld|port|north': 'oldWorld|port|0|0'},
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );

      final result = applyGreatPowerFall(game, const {'p1': 'oldWorld|cap'});

      expect(result.worldState.tryGetProvince('oldWorld|port')?.ownerId, 'p1');
    });

    test('skips when capital still owned by the player', () {
      final game = Game(
        id: 'g-gp-hold',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final result = applyGreatPowerFall(game, const {'p1': 'oldWorld|cap'});

      expect(result.worldState.tryGetProvince('oldWorld|cap')?.ownerId, 'p1');
    });

    test('skips when capital province has no owner', () {
      final game = Game(
        id: 'g-gp-noowner',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|cap', regionId: 'oldWorld'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      final result = applyGreatPowerFall(game, const {'p1': 'oldWorld|cap'});

      expect(result.worldState.tryGetProvince('oldWorld|cap')?.ownerId, isNull);
    });
  });
}
