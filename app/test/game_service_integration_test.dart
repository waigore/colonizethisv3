import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

import '../lib/core/services/game_service.dart';

void main() {
  group('GameService integration', () {
    late Box<dynamic> box;
    late GameService service;

    setUp(() async {
      Hive.init('./.dart_tool/test_hive');
      box = await Hive.openBox<dynamic>('games_integration');
      service = GameService(box, GameSaveAdapter());
    });

    tearDown(() async {
      await box.close();
    });

    test('nextTurn persists updated game including Phase 2 fields', () {
      final game = service.createNewGame(id: 'g1');

      // Build minimal topology with two adjacent provinces.
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          const TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [
          const TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      final orders = Orders(
        moveOrdersByPlayerId: const {},
      );

      final updated = service.nextTurn(game, orders: orders, topology: topology);

      // Save/load round-trip via GameService to ensure Phase 2 fields survive.
      final loaded = service.loadGame(updated.id);
      expect(loaded, isNotNull);
      expect(loaded!.worldState.turnState.turnNumber, updated.worldState.turnState.turnNumber);
      expect(loaded.players.first.stockpile.quantities, updated.players.first.stockpile.quantities);
      expect(loaded.players.first.workerPool, updated.players.first.workerPool);
    });
  });
}

