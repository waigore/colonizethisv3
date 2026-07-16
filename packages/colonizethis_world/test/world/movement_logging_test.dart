import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:logger/logger.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

import '../world_test_support/world_test_support.dart';

List<String> _civilianMovementMessages(List<LogEvent> events) => [
  for (final e in events)
    if (e.message.contains('world:') && e.message.contains('civilian'))
      e.message,
];

List<String> _armyMoveMessages(List<LogEvent> events) => [
  for (final e in events)
    if (e.message.contains('world:') && e.message.contains('army_move'))
      e.message,
];

void main() {
  group('civilian tile movement logging', () {
    late List<LogEvent> capturedEvents;
    late void Function(LogEvent) listener;

    setUp(() {
      capturedEvents = [];
      listener = capturedEvents.add;
      Logger.addLogListener(listener);
      Logger.level = Level.debug;
    });

    tearDown(() {
      Logger.removeLogListener(listener);
      capturedEvents.clear();
      Logger.level = Level.info;
    });

    test(
      'applyCivilianTileMoveOrdersToWorldRegions emits apply summary (info)',
      () {
        const ow = 'oldWorld';
        final game = TestFixtures.minimalGame(
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: ow, ownerId: 'p1'),
              Province(id: 'oldWorld|P2', regionId: ow, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeMerchant,
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );

        applyCivilianTileMoveOrdersToWorldRegions(game, {
          'p1': [
            const MoveOrder(
              unitId: 'u1',
              destinationTileKey: 'oldWorld|P2|0|0',
            ),
          ],
        });

        final lines = _civilianMovementMessages(capturedEvents);
        expect(
          lines.any(
            (m) =>
                m.contains('civilian tile movement apply') &&
                m.contains('orders=1') &&
                m.contains('applied=1') &&
                m.contains('ignored=0'),
          ),
          isTrue,
        );
      },
    );

    test(
      'applyCivilianTileMoveOrdersToWorldRegions emits unit_not_found at debug',
      () {
        const ow = 'oldWorld';
        final game = TestFixtures.minimalGame(
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'oldWorld|P1', regionId: ow, ownerId: 'p1'),
            ],
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );

        applyCivilianTileMoveOrdersToWorldRegions(game, {
          'p1': [
            const MoveOrder(
              unitId: 'missing',
              destinationTileKey: 'oldWorld|P1|0|0',
            ),
          ],
        });

        final lines = _civilianMovementMessages(capturedEvents);
        expect(
          lines.any(
            (m) =>
                m.contains('civilian movement ignored') &&
                m.contains('reason=unit_not_found') &&
                m.contains('unitId=missing'),
          ),
          isTrue,
        );
        expect(
          lines.any(
            (m) =>
                m.contains('civilian tile movement apply') &&
                m.contains('orders=1') &&
                m.contains('applied=0') &&
                m.contains('ignored=1'),
          ),
          isTrue,
        );
      },
    );

    test('applyCivilianTileMoveOrdersToWorldRegions skips per-order debug work '
        'when Logger.level is info', () {
      Logger.level = Level.info;
      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        oldWorld: const RegionData(
          provinces: [Province(id: 'oldWorld|P1', regionId: ow, ownerId: 'p1')],
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      applyCivilianTileMoveOrdersToWorldRegions(game, {
        'p1': [
          const MoveOrder(
            unitId: 'missing',
            destinationTileKey: 'oldWorld|P1|0|0',
          ),
        ],
      });

      final lines = _civilianMovementMessages(capturedEvents);
      expect(
        lines.any((m) => m.contains('civilian movement ignored')),
        isFalse,
      );
    });
  });

  group('army move apply logging (shared shell; Refs #4038)', () {
    late List<LogEvent> capturedEvents;
    late void Function(LogEvent) listener;
    final topology = prefixedAdjacentProvincesTopology(regionId: 'oldWorld');

    setUp(() {
      capturedEvents = [];
      listener = capturedEvents.add;
      Logger.addLogListener(listener);
      Logger.level = Level.debug;
    });

    tearDown(() {
      Logger.removeLogListener(listener);
      capturedEvents.clear();
      Logger.level = Level.info;
    });

    test('home_army_locked emits debug ignore + info apply summary', () {
      final world = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'p1'),
            Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'p1'),
          ],
        ),
        armies: [
          const Army(
            id: 'home',
            ownerId: 'p1',
            regionId: 'oldWorld',
            stationedProvinceId: 'oldWorld|p1',
            regimentUnitIds: [],
            isHomeArmy: true,
          ),
        ],
      );

      applyArmyMoveOrdersToRegion(world, topology, const {
        'p1': [
          ArmyMoveOrder(
            armyId: 'home',
            destinationProvinceId: 'oldWorld|p2',
          ),
        ],
      }, regionId: 'oldWorld');

      final lines = _armyMoveMessages(capturedEvents);
      expect(
        lines.any(
          (m) =>
              m.contains('army_move ignored') &&
              m.contains('reason=home_army_locked') &&
              m.contains('armyId=home'),
        ),
        isTrue,
      );
      expect(
        lines.any(
          (m) =>
              m.contains('army_move apply') &&
              m.contains('applied=0') &&
              m.contains('ignored=1'),
        ),
        isTrue,
      );
    });

    test('negative: home_army_locked debug line suppressed at info level', () {
      Logger.level = Level.info;
      final world = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'p1'),
            Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'p1'),
          ],
        ),
        armies: [
          const Army(
            id: 'home',
            ownerId: 'p1',
            regionId: 'oldWorld',
            stationedProvinceId: 'oldWorld|p1',
            regimentUnitIds: [],
            isHomeArmy: true,
          ),
        ],
      );

      applyArmyMoveOrdersToRegion(world, topology, const {
        'p1': [
          ArmyMoveOrder(
            armyId: 'home',
            destinationProvinceId: 'oldWorld|p2',
          ),
        ],
      }, regionId: 'oldWorld');

      final lines = _armyMoveMessages(capturedEvents);
      expect(
        lines.any((m) => m.contains('army_move ignored')),
        isFalse,
      );
      expect(
        lines.any((m) => m.contains('army_move apply')),
        isTrue,
        reason: 'info apply summary still emits at Level.info',
      );
    });
  });
}
