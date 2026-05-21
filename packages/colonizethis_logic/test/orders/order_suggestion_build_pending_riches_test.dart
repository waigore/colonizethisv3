import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

/// Build suggestions treat pending riches-to-treasury cash as part of
/// affordability (Refs #2509, SPEC/program/order-suggestions.md § Build orders).
void main() {
  group('suggestBuildOrders pending riches treasury', () {
    test('accepts peasant_levies when treasury is zero but stockpile has spices',
        () {
      final base = TestFixtures.gameWithSingleOwnedProvince(
        ownerPlayerId: 'p1',
        provinceId: 'oldWorld|p1',
        treasury: 0,
        isHuman: false,
      );
      final player = base.players.single;
      final game = base.copyWith(
        players: [
          player.copyWith(
            stockpile: const Stockpile()
                .applyDelta(CommodityCatalog.spices.id, 50)
                .applyDelta(CommodityCatalog.fabric.id, 5),
            workerPool: const WorkerPool(peasants: 5),
          ),
        ],
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [],
      );
      final view = buildPlayerView(game, topology, 'p1');

      final suggestions = suggestBuildOrders(
        view,
        game,
        topology,
        const Orders(),
      );

      expect(
        suggestions.map((o) => o.unitType),
        contains('peasant_levies'),
      );
    });

    test('incremental build probe matches full-pass when riches fund build', () {
      final base = TestFixtures.gameWithSingleOwnedProvince(
        ownerPlayerId: 'p1',
        provinceId: 'oldWorld|p1',
        treasury: 0,
        isHuman: false,
      );
      final player = base.players.single;
      final game = base.copyWith(
        players: [
          player.copyWith(
            stockpile: const Stockpile()
                .applyDelta(CommodityCatalog.spices.id, 50)
                .applyDelta(CommodityCatalog.fabric.id, 5),
            workerPool: const WorkerPool(peasants: 5),
          ),
        ],
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [],
      );
      const basePrefix = Orders();
      const candidate = BuildUnitOrder(
        unitType: 'peasant_levies',
        isMilitary: true,
        spawnProvinceId: 'oldWorld|p1',
      );

      final incremental = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: basePrefix,
      );
      final engine = OrderEngine(initialOrders: basePrefix);
      final fullPass = engine
          .addBuildOrderWithContext(
            game,
            topology,
            'p1',
            candidate,
          )
          .isAccepted;

      expect(incremental.isBuildAccepted(candidate), fullPass);
      expect(incremental.isBuildAccepted(candidate), isTrue);
    });
  });
}
