import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_fixtures.dart';

/// Characterization baselines for [previewStockpilePhaseDeltasByCommodityForPlayer]
/// (same pipeline as [economyPreviewStockpilePhaseDeltasForPlayer]).
/// Refs #2071 — catch preview drift when unifying cost / phase logic.
String _canonicalPreviewPhaseSnapshot(
  Map<EconomyPreviewStockpilePhase, Map<String, int>> phases,
) {
  final b = StringBuffer();
  for (final phase in EconomyPreviewStockpilePhase.values) {
    final m = phases[phase] ?? {};
    final keys = m.keys.toList()..sort();
    b.write(phase.name);
    b.write('{');
    for (final k in keys) {
      b.write('$k:${m[k]},');
    }
    b.write('}|');
  }
  return b.toString();
}

void main() {
  suppressLogsForTests();

  group('economy preview pipeline characterization', () {
    test('minimal game empty topology yields empty per-phase deltas', () {
      final game = TestFixtures.minimalGame(
        players: [
          const Player(
            id: 'p1',
            displayName: 'A',
            isHuman: true,
            stockpile: Stockpile(),
          ),
        ],
      );
      final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
        game: game,
        topology: const MapTopology(nodes: [], edges: []),
        playerId: 'p1',
      );
      expect(
        _canonicalPreviewPhaseSnapshot(phases),
        'pendingBuildCosts{}|extraction{}|richesToTreasury{}|consumption{}|'
        'production{}|',
      );
    });

    test('pending build_improvement work order snapshot', () {
      const tileKey = 'oldWorld|ow|p1|0|0';
      final tileState = const TileMapState().setImprovement(tileKey, 0);
      final stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.lumber.id, 10)
          .applyDelta(CommodityCatalog.castIron.id, 10);
      final game = TestFixtures.singlePlayerWorkPreviewGame(
        playerStockpile: stockpile,
        units: [
          Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: 'ow|p1',
            tileKey: tileKey,
          ),
        ],
        tileState: tileState,
      );
      final currentOrders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final phases = previewStockpilePhaseDeltasByCommodityForPlayer(
        game: game,
        topology: const MapTopology(nodes: [], edges: []),
        playerId: 'p1',
        currentOrders: currentOrders,
      );
      expect(
        _canonicalPreviewPhaseSnapshot(phases),
        'pendingBuildCosts{castIron:-1,lumber:-1,}|extraction{}|'
        'richesToTreasury{}|consumption{}|production{}|',
      );
    });
  });
}
