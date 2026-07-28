import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'support/suggestion/order_suggestion_core_fixtures.dart';

void main() {
  group('development panel assign (Refs #4175 Slice B)', () {
    test('compareDevelopmentImproveTilePriority prefers connected then lower level', () {
      const tileState = TileMapState(
        improvementByTile: {
          'oldWorld|p1|0|0': 1,
          'oldWorld|p1|1|0': 0,
          'oldWorld|p1|2|0': 0,
        },
      );
      const connected = {'oldWorld|p1|0|0', 'oldWorld|p1|1|0'};
      final sorted = sortedDevelopmentImproveTileCandidates(
        tileKeys: const {
          'oldWorld|p1|2|0',
          'oldWorld|p1|0|0',
          'oldWorld|p1|1|0',
        },
        connectedTileKeys: connected,
        tileState: tileState,
      );
      expect(sorted, [
        'oldWorld|p1|1|0',
        'oldWorld|p1|0|0',
        'oldWorld|p1|2|0',
      ]);
    });

    test('idleBuildersForDevelopmentAssign uses stable unit id order', () {
      final setup = OscDualBuilderGrainTiles();
      final idle = idleBuildersForDevelopmentAssign(
        game: setup.game(),
        playerId: OscIds.playerId,
        currentOrders: const Orders(),
      );
      expect(idle.map((u) => u.id).toList(), ['b1', 'b2']);
    });

    test('idleBuildersForDevelopmentAssign excludes pending work units', () {
      final setup = OscDualBuilderGrainTiles();
      final idle = idleBuildersForDevelopmentAssign(
        game: setup.game(),
        playerId: OscIds.playerId,
        currentOrders: setup.ordersReservingTileA(),
      );
      expect(idle.map((u) => u.id).toList(), ['b2']);
    });

    test(
      'selectDevelopmentImproveAssignCandidate picks first builder and reserved tile',
      () {
        final setup = OscDualBuilderGrainTiles();
        final game = setup.game();
        final candidate = selectDevelopmentImproveAssignCandidate(
          game: game,
          playerId: OscIds.playerId,
          currentOrders: setup.ordersReservingTileA(),
          topology: setup.topology(),
          tileMapByRegion: const {},
          commodityTileKeys: {setup.tileA, setup.tileB},
          connectedTileKeys: {setup.tileA, setup.tileB},
        );
        expect(candidate, isNotNull);
        expect(candidate!.builderUnitId, 'b2');
        expect(candidate.targetTileKey, setup.tileB);
      },
    );

    test('resolveDevelopmentAssignRowState disables when materials insufficient', () {
      final setup = OscDualBuilderGrainTiles();
      final brokePlayer = setup.player.copyWith(
        stockpile: const Stockpile(),
      );
      final game = setup.game().copyWith(players: [brokePlayer]);
      final state = resolveDevelopmentAssignRowState(
        game: game,
        playerId: OscIds.playerId,
        currentOrders: const Orders(),
        topology: setup.topology(),
        tileMapByRegion: const {},
        commodityTileKeys: {setup.tileA},
        connectedTileKeys: {setup.tileA},
      );
      expect(state.enabled, isFalse);
      expect(state.disabledReason, 'Insufficient materials');
    });

    test('resolveDevelopmentAssignRowState enables with materials and connectivity', () {
      final setup = OscDualBuilderGrainTiles();
      final state = resolveDevelopmentAssignRowState(
        game: setup.game(),
        playerId: OscIds.playerId,
        currentOrders: const Orders(),
        topology: setup.topology(),
        tileMapByRegion: const {},
        commodityTileKeys: {setup.tileA},
        connectedTileKeys: {setup.tileA},
      );
      expect(state.enabled, isTrue);
      expect(state.candidate?.builderUnitId, 'b1');
      expect(state.candidate?.targetTileKey, setup.tileA);
    });

    test(
      'resolveDevelopmentAssignRowState enables disconnected commodity when materials allow',
      () {
        final setup = OscDualBuilderGrainTiles();
        final state = resolveDevelopmentAssignRowState(
          game: setup.game(),
          playerId: OscIds.playerId,
          currentOrders: const Orders(),
          topology: setup.topology(),
          tileMapByRegion: const {},
          commodityTileKeys: {setup.tileA},
          connectedTileKeys: const {},
        );
        expect(state.enabled, isTrue);
        expect(state.candidate?.targetTileKey, setup.tileA);
        expect(state.candidate?.isCapitalConnected, isFalse);
      },
    );

    test('developmentPanelMaterialShortageCommodityIds flags blocked rows', () {
      final setup = OscDualBuilderGrainTiles();
      final brokePlayer = setup.player.copyWith(
        stockpile: const Stockpile(),
      );
      final game = setup.game().copyWith(players: [brokePlayer]);
      final shortages = developmentPanelMaterialShortageCommodityIds(
        game: game,
        playerId: OscIds.playerId,
        currentOrders: const Orders(),
        topology: setup.topology(),
        tileMapByRegion: const {},
        improvableRows: [
          (commodityId: 'grain', tileKeys: {setup.tileA}),
        ],
        connectedTileKeys: {setup.tileA},
      );
      expect(shortages, {'grain'});
    });
  });
}
