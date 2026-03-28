import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

List<String> _movementMessages(List<LogEvent> events) => [
      for (final e in events)
        if (e.message.contains('logic: movement')) e.message,
    ];

void main() {
  group('movement logging', () {
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

    test('applyMoveOrdersToRegion emits movement apply summary (info)', () {
      const regionId = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: regionId, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: regionId, type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      final region = RegionData(
        provinces: const [
          Province(id: 'P1', regionId: regionId, ownerId: 'p1'),
          Province(id: 'P2', regionId: regionId, ownerId: 'p2'),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'Regiment',
            ownerId: 'p1',
            locationProvinceId: 'P1',
          ),
        ],
      );

      final orders = {
        'p1': [
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'P2'),
        ],
      };

      applyMoveOrdersToRegion(
        region,
        topology,
        orders,
        regionId: regionId,
      );

      final movement = _movementMessages(capturedEvents);
      expect(
        movement.any(
          (m) =>
              m.contains('logic: movement apply') &&
              m.contains('regionId=$regionId') &&
              m.contains('orders=1') &&
              m.contains('applied=1') &&
              m.contains('ignored=0'),
        ),
        isTrue,
      );
    });

    test('applyMoveOrdersToRegion emits invalid_adjacency at debug when move rejected',
        () {
      const regionId = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: regionId, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: regionId, type: TopologyNodeType.province),
          TopologyNode(id: 'P3', regionId: regionId, type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      final region = RegionData(
        provinces: const [
          Province(id: 'P1', regionId: regionId, ownerId: 'p1'),
          Province(id: 'P2', regionId: regionId, ownerId: 'p2'),
          Province(id: 'P3', regionId: regionId, ownerId: 'p2'),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'Regiment',
            ownerId: 'p1',
            locationProvinceId: 'P1',
          ),
        ],
      );

      final orders = {
        'p1': [
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'P3'),
        ],
      };

      applyMoveOrdersToRegion(
        region,
        topology,
        orders,
        regionId: regionId,
      );

      final movement = _movementMessages(capturedEvents);
      expect(
        movement.any(
          (m) =>
              m.contains('logic: movement ignored') &&
              m.contains('reason=invalid_adjacency'),
        ),
        isTrue,
      );
      expect(
        movement.any(
          (m) =>
              m.contains('logic: movement apply') &&
              m.contains('orders=1') &&
              m.contains('applied=0') &&
              m.contains('ignored=1'),
        ),
        isTrue,
      );
    });
  });
}
