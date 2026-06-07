import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:logger/logger.dart';

List<String> _civilianMovementMessages(List<LogEvent> events) => [
      for (final e in events)
        if (e.message.contains('world:') && e.message.contains('civilian'))
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

    test('applyCivilianTileMoveOrdersToWorldRegions emits apply summary (info)', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
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
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      applyCivilianTileMoveOrdersToWorldRegions(
        game,
        {
          'p1': [
            const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
          ],
        },
      );

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
    });

    test('applyCivilianTileMoveOrdersToWorldRegions emits unit_not_found at debug',
        () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: ow, ownerId: 'p1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      applyCivilianTileMoveOrdersToWorldRegions(
        game,
        {
          'p1': [
            const MoveOrder(unitId: 'missing', destinationTileKey: 'oldWorld|P1|0|0'),
          ],
        },
      );

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
    });

    test(
      'applyCivilianTileMoveOrdersToWorldRegions skips per-order debug work '
      'when Logger.level is info',
      () {
        Logger.level = Level.info;
        const ow = 'oldWorld';
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'oldWorld|P1', regionId: ow, ownerId: 'p1'),
              ],
              units: const [],
            ),
            newWorld: const RegionData(),
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );

        applyCivilianTileMoveOrdersToWorldRegions(
          game,
          {
            'p1': [
              const MoveOrder(unitId: 'missing', destinationTileKey: 'oldWorld|P1|0|0'),
            ],
          },
        );

        final lines = _civilianMovementMessages(capturedEvents);
        expect(
          lines.any((m) => m.contains('civilian movement ignored')),
          isFalse,
        );
      },
    );
  });
}
