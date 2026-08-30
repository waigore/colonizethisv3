// Lazy assign-row cache resolves per visible row (Refs #4687 Slice B).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'support/suggestion/order_suggestion_core_fixtures.dart';

void main() {
  suppressLogsForTests();
  const scopeA = DevelopmentPanelScopeRow(
    scopeKey: 'oldWorld|p1',
    provinceId: 'oldWorld|p1',
    displayName: 'P1',
    improvableCommodities: [
      DevelopmentImprovableCommodityRow(
        commodityId: 'grain',
        tileKeys: ['oldWorld|p1|0|0'],
      ),
    ],
  );
  const scopeB = DevelopmentPanelScopeRow(
    scopeKey: 'oldWorld|p2',
    provinceId: 'oldWorld|p2',
    displayName: 'P2',
    improvableCommodities: [
      DevelopmentImprovableCommodityRow(
        commodityId: 'iron',
        tileKeys: ['oldWorld|p2|0|0'],
      ),
    ],
  );

  test(
    'lazy assign cache resolves only requested scope commodities (Refs #4687 Slice B)',
    () {
      final s = OscDualBuilderGrainTiles();
      final cache = buildLazyDevelopmentPanelAssignRowStateCache(
        ownedScopes: const [scopeA, scopeB],
        purchasedScopes: const [],
        game: s.game(),
        playerId: OscIds.playerId,
        currentOrders: const Orders(),
        topology: s.topology(),
        tileMapByRegion: const {},
        connectedTileKeys: {s.tileA, s.tileB},
      );

      expect(cache.byScopeCommodityKey, isEmpty);

      cache.rowStateFor('oldWorld|p1', 'grain');
      expect(cache.byScopeCommodityKey, hasLength(1));
      expect(
        cache.byScopeCommodityKey.containsKey('oldWorld|p1|grain'),
        isTrue,
      );
      expect(
        cache.byScopeCommodityKey.containsKey('oldWorld|p2|iron'),
        isFalse,
      );
    },
  );

  test(
    'eager assign cache still precomputes all rows (Refs #4175 Slice E)',
    () {
      final s = OscDualBuilderGrainTiles();
      final cache = buildDevelopmentPanelAssignRowStateCache(
        ownedScopes: const [scopeA, scopeB],
        purchasedScopes: const [],
        game: s.game(),
        playerId: OscIds.playerId,
        currentOrders: const Orders(),
        topology: s.topology(),
        tileMapByRegion: const {},
        connectedTileKeys: {s.tileA, s.tileB},
      );

      expect(cache.byScopeCommodityKey, hasLength(2));
    },
  );
}
