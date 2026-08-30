import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:logger/logger.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

import '../world_test_support/world_test_support.dart';

List<String> _armyMoveMessages(List<LogEvent> events) => [
  for (final e in events)
    if (e.message.contains('world:') && e.message.contains('army_move'))
      e.message,
];

void registerMovementLoggingArmyCases() {
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
          ArmyMoveOrder(armyId: 'home', destinationProvinceId: 'oldWorld|p2'),
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
          ArmyMoveOrder(armyId: 'home', destinationProvinceId: 'oldWorld|p2'),
        ],
      }, regionId: 'oldWorld');

      final lines = _armyMoveMessages(capturedEvents);
      expect(lines.any((m) => m.contains('army_move ignored')), isFalse);
      expect(
        lines.any((m) => m.contains('army_move apply')),
        isTrue,
        reason: 'info apply summary still emits at Level.info',
      );
    });
  });
}
