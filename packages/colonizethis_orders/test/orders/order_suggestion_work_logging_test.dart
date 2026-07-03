import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

List<String> _suggestWorkLines(List<LogEvent> events) => [
  for (final e in events)
    if (e.message.contains('suggest_work')) e.message,
];

void main() {
  suppressLogsForTests();
  group('suggestWorkOrders structured logging', () {
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

    test('emits suggest_work summaries for Explorer/Builder/Spy/Merchant', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'Human',
        isHuman: true,
        treasury: 5000,
      );

      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: playerId);

      final explorer = Unit(
        id: 'u_explorer',
        type: kUnitTypeExplorer,
        ownerId: playerId,
        locationProvinceId: p1.id,
        tileKey: '$ow|p1|0|0',
        status: UnitStatus.idle,
      );
      final builder = Unit(
        id: 'u_builder',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: p1.id,
        tileKey: '$ow|p1|0|0',
        status: UnitStatus.idle,
      );
      final spy = Unit(
        id: 'u_spy',
        type: kUnitTypeSpy,
        ownerId: playerId,
        locationProvinceId: p1.id,
        tileKey: '$ow|p1|0|0',
        status: UnitStatus.idle,
      );
      final merchant = Unit(
        id: 'u_merchant',
        type: kUnitTypeMerchant,
        ownerId: playerId,
        locationProvinceId: p1.id,
        tileKey: '$ow|p1|0|0',
        status: UnitStatus.idle,
      );

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [p1, p2],
          units: [explorer, builder, spy, merchant],
        ),
        newWorld: const RegionData(),
        playerVisibilityByTile: {
          playerId: {'$ow|p1|0|0': 'fullyVisible', '$ow|p2|0|0': 'fogged'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            p1.id: ['$ow|p1|0|0'],
            p2.id: ['$ow|p2|0|0'],
          },
        },
        resourceByTileKey: {'$ow|p1|0|0': 'grain'},
      );

      final game = Game(
        id: 'g1',
        worldState: world,
        players: [player],
        minorNations: const [],
        tribes: const [],
      );

      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
      );

      final view = buildPlayerView(game, topology, playerId);

      suggestWorkOrders(view, game, topology, const Orders());

      final lines = _suggestWorkLines(capturedEvents);
      expect(lines, isNotEmpty);
      expect(
        lines.any(
          (m) =>
              m.contains('unitId=u_explorer') &&
              m.contains('target=explore') &&
              m.contains('outcome='),
        ),
        isTrue,
      );
      expect(
        lines.any(
          (m) =>
              m.contains('unitId=u_builder') &&
              m.contains('target=build_improvement') &&
              m.contains('outcome=') &&
              m.contains('reason='),
        ),
        isTrue,
      );
      expect(
        lines.any(
          (m) =>
              m.contains('unitId=u_spy') &&
              m.contains('target=counter_spy') &&
              m.contains('outcome='),
        ),
        isTrue,
      );
      expect(
        lines.any(
          (m) =>
              m.contains('unitId=u_merchant') &&
              m.contains('target=purchase_land') &&
              m.contains('outcome=') &&
              m.contains('reason='),
        ),
        isTrue,
      );
      expect(lines.length, lessThan(80), reason: 'summary-only, no tile spam');
    });

    test(
      'suggestWorkOrders logger lines never emit unbounded full list payload',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final player = const Player(
          id: playerId,
          displayName: 'Human',
          isHuman: true,
          treasury: 5000,
        );

        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final explorer = Unit(
          id: 'u_explorer',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: p1.id,
          tileKey: '$ow|p1|0|0',
          status: UnitStatus.idle,
        );

        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [explorer]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            playerId: {'$ow|p1|0|0': 'fullyVisible', '$ow|p1|0|1': 'unknown'},
          },
          tileKeysByRegionAndProvince: {
            ow: {
              p1.id: ['$ow|p1|0|0', '$ow|p1|0|1'],
            },
          },
          resourceByTileKey: const {'$ow|p1|0|0': 'grain'},
        );

        final game = Game(
          id: 'g1',
          worldState: world,
          players: [player],
          minorNations: const [],
          tribes: const [],
        );

        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );

        final view = buildPlayerView(game, topology, playerId);

        suggestWorkOrders(view, game, topology, const Orders());

        for (final e in capturedEvents) {
          if (e.message.contains('suggestWorkOrders')) {
            expect(
              e.message,
              isNot(contains('full list')),
              reason: 'bounded preview only (Refs #2133)',
            );
          }
        }
      },
    );
  });
}
