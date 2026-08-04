import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

void main() {
  group('filterOrderList', () {
    test('emits OrderRejectedEvent with orderKind when validation rejects', () {
      final events = <GameEvent>[];
      final sink = TurnEventSink(onGameEvent: events.add);
      final results = [OrderValidationResult.rejected('unit_not_found')];
      final idx = <int>[0];
      const orders = [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildRoad,
          targetTileKey: 'oldWorld|p1|0|0',
        ),
      ];

      filterOrderList<WorkOrder>(
        'gp1',
        orders,
        results,
        idx,
        (_, _) {},
        (w) => 'Work order: ${w.target}',
        OrderKind.work,
        sink,
      );

      final rejected = events.whereType<OrderRejectedEvent>().toList();
      expect(rejected, hasLength(1));
      expect(rejected.single.orderKind, OrderKind.work);
      expect(rejected.single.reasonCode, 'unit_not_found');
      expect(rejected.single.orderSummary, 'Work order: $kWorkTargetBuildRoad');
    });

    test('emits recruitWorker orderKind for recruit rejections', () {
      final events = <GameEvent>[];
      final sink = TurnEventSink(onGameEvent: events.add);
      final results = [OrderValidationResult.rejected('tech_locked')];
      final idx = <int>[0];
      const orders = [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)];

      filterOrderList<RecruitWorkerOrder>(
        'gp1',
        orders,
        results,
        idx,
        (_, _) {},
        (r) => 'Recruit worker: ${r.targetTier.id}',
        OrderKind.recruitWorker,
        sink,
      );

      final rejected = events.whereType<OrderRejectedEvent>().toList();
      expect(rejected.single.orderKind, OrderKind.recruitWorker);
    });

    test('emits diplomacy orderKind for diplomatic rejections', () {
      final events = <GameEvent>[];
      final sink = TurnEventSink(onGameEvent: events.add);
      final results = [OrderValidationResult.rejected('insufficient_treasury')];
      final idx = <int>[0];
      const orders = [
        DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'minor1',
          overtureStage: OvertureStage.tradeConsulate,
        ),
      ];

      filterOrderList<DiplomaticOrder>(
        'gp1',
        orders,
        results,
        idx,
        (_, _) {},
        (d) => 'Diplomatic order: ${d.type.name} -> ${d.targetFactionId}',
        OrderKind.diplomacy,
        sink,
      );

      final rejected = events.whereType<OrderRejectedEvent>().toList();
      expect(rejected.single.orderKind, OrderKind.diplomacy);
    });
  });

  group('filterAcceptedOrdersForAllPlayers', () {
    test('strips rejected diplomatic orders and emits diplomacy orderKind', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: kRegionOldWorld,
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      const ow = kRegionOldWorld;
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          const Player(id: 'p1', displayName: 'P1', isHuman: true, treasury: 0),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
      );
      final engine = OrderEngine(
        initialOrders: Orders(
          diplomaticOrdersByPlayerId: {
            'p1': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.establishOverture,
                targetFactionId: 'minor1',
                overtureStage: OvertureStage.tradeConsulate,
              ),
            ],
          },
        ),
        projector: projectOrderEffects,
      );
      final events = <GameEvent>[];
      final filtered = filterAcceptedOrdersForAllPlayers(
        engine: engine,
        game: game,
        topology: topology,
        sink: TurnEventSink(onGameEvent: events.add),
      );

      expect(filtered.diplomaticOrdersByPlayerId['p1'] ?? const [], isEmpty);
      final rejected = events.whereType<OrderRejectedEvent>().toList();
      expect(rejected, hasLength(1));
      expect(rejected.single.orderKind, OrderKind.diplomacy);
    });
  });
}
