import 'package:colonizethis_app/features/game/flame/game_map_area_state_logic.dart';
import 'package:colonizethis_app/features/game/flame/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        PlayerView,
        VisibilityLevel,
        kWorkTargetCounterSpy,
        kWorkTargetPurchaseLand,
        kWorkTargetStealTech;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('GameMapAreaStateLogic cache-first spy/merchant (Refs #2029)', () {
    ct_models.Game minimalGame() => ct_models.Game(
      id: 'g_spy_merchant_cache',
      worldState: const ct_models.WorldState(
        turnState: ct_models.TurnState(
          phase: ct_models.TurnPhase.orders,
          turnNumber: 1,
        ),
        oldWorld: ct_models.RegionData(provinces: [], units: []),
        newWorld: ct_models.RegionData(provinces: [], units: []),
      ),
      players: const [
        ct_models.Player(id: 'gp1', displayName: 'Human', isHuman: true),
      ],
    );

    PlayerView viewForGp1() => PlayerView(
      playerId: 'gp1',
      player: ct_models.Player(id: 'gp1', displayName: 'gp1', isHuman: true),
      ownUnitsById: const {},
      provincesById: const {},
      visibilityByTile: const {'oldWorld|p1|0|0': VisibilityLevel.fogged},
      prospectedTiles: const {},
      diplomacyByOtherId: const {},
    );

    WorkTargetSelectionSnapshot snapshot() => WorkTargetSelectionSnapshot(
      game: minimalGame(),
      playerId: 'gp1',
      playerView: viewForGp1(),
      topology: const MapTopology(),
      currentOrders: const ct_models.Orders(),
      tileMapByRegion: null,
    );

    test('resolveValidTileKeys returns post-filter cache for steal_tech, '
        'counter_spy, and purchase_land', () {
      const stealTile = 'oldWorld|gp2_cap|0|0';
      const counterTile = 'oldWorld|owned|1|1';
      const purchaseTile = 'oldWorld|minor|2|2';

      final cache = PerPlayerWorkTargetSelectionCache(
        strategies: {
          kWorkTargetStealTech: (_) => {stealTile},
          kWorkTargetCounterSpy: (_) => {counterTile},
          kWorkTargetPurchaseLand: (_) => {purchaseTile},
        },
      );
      cache.refresh(snapshot());

      final game = minimalGame();
      const topology = MapTopology();
      const orders = ct_models.Orders();

      for (final entry in <MapEntry<String, String>>[
        MapEntry(kWorkTargetStealTech, stealTile),
        MapEntry(kWorkTargetCounterSpy, counterTile),
        MapEntry(kWorkTargetPurchaseLand, purchaseTile),
      ]) {
        final resolved =
            GameMapAreaStateLogic.resolveValidTileKeysForCivilianWorkSelection(
              workTarget: entry.key,
              workTargetSelectionCache: cache,
              humanPlayerId: 'gp1',
              selectedUnitId: 'u_sel',
              game: game,
              currentOrders: orders,
              playerView: viewForGp1(),
              topology: topology,
              tileMapByRegion: null,
            );
        expect(resolved, {entry.value}, reason: entry.key);
      }
    });

    test('resolveValidTileKeys subtracts stale spy/merchant tiles from pending '
        'same-family work orders', () {
      const tileKept = 'oldWorld|p1|0|0';
      const tileStale = 'oldWorld|p1|1|0';

      final cache = PerPlayerWorkTargetSelectionCache(
        strategies: {
          kWorkTargetStealTech: (_) => {tileKept, tileStale},
          kWorkTargetCounterSpy: (_) => {tileKept, tileStale},
          kWorkTargetPurchaseLand: (_) => {tileKept, tileStale},
        },
      );
      cache.refresh(snapshot());

      final game = minimalGame();
      const topology = MapTopology();
      final orders = ct_models.Orders(
        workOrdersByPlayerId: {
          'gp1': const [
            ct_models.WorkOrder(
              unitId: 'u_other',
              target: kWorkTargetPurchaseLand,
              targetTileKey: tileStale,
            ),
          ],
        },
      );

      for (final workTarget in <String>[
        kWorkTargetStealTech,
        kWorkTargetCounterSpy,
        kWorkTargetPurchaseLand,
      ]) {
        final resolved =
            GameMapAreaStateLogic.resolveValidTileKeysForCivilianWorkSelection(
              workTarget: workTarget,
              workTargetSelectionCache: cache,
              humanPlayerId: 'gp1',
              selectedUnitId: 'u_sel',
              game: game,
              currentOrders: orders,
              playerView: viewForGp1(),
              topology: topology,
              tileMapByRegion: null,
            );
        expect(resolved, const {
          tileKept,
        }, reason: 'stale subtraction for $workTarget');
      }
    });

    test('resolveValidTileKeys uses live pipeline for unknown work targets '
        '(non-cache-first regression guard)', () {
      final cache = PerPlayerWorkTargetSelectionCache();
      cache.refresh(snapshot());

      final resolved =
          GameMapAreaStateLogic.resolveValidTileKeysForCivilianWorkSelection(
            workTarget: '__not_cache_first__',
            workTargetSelectionCache: cache,
            humanPlayerId: 'gp1',
            selectedUnitId: 'u_any',
            game: minimalGame(),
            currentOrders: const ct_models.Orders(),
            playerView: viewForGp1(),
            topology: const MapTopology(),
            tileMapByRegion: null,
          );
      expect(resolved, isEmpty);
    });
  });
}
