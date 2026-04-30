import 'package:colonizethis_app/features/game/flame/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        PlayerView,
        VisibilityLevel,
        kWorkTargetBuildImprovement,
        kWorkTargetExplore;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('PerPlayerWorkTargetSelectionCache', () {
    WorkTargetSelectionSnapshot snapshotForPlayer(String playerId) {
      return WorkTargetSelectionSnapshot(
        game: ct_models.Game(
          id: 'g_$playerId',
          worldState: const ct_models.WorldState(
            turnState: ct_models.TurnState(
              phase: ct_models.TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: ct_models.RegionData(provinces: [], units: []),
            newWorld: ct_models.RegionData(provinces: [], units: []),
          ),
          players: [
            ct_models.Player(
              id: playerId,
              displayName: playerId,
              isHuman: true,
            ),
          ],
        ),
        playerId: playerId,
        playerView: PlayerView(
          playerId: playerId,
          player: ct_models.Player(
            id: playerId,
            displayName: playerId,
            isHuman: true,
          ),
          ownUnitsById: const {},
          provincesById: const {},
          visibilityByTile: const {'oldWorld|p1|0|0': VisibilityLevel.fogged},
          prospectedTiles: const {},
          diplomacyByOtherId: const {},
        ),
        topology: const MapTopology(nodes: [], edges: []),
        currentOrders: const ct_models.Orders(),
        tileMapByRegion: null,
      );
    }

    test('sorted returns deterministic ordering', () {
      final cache = PerPlayerWorkTargetSelectionCache(
        strategies: {
          kWorkTargetExplore: (_) => {'oldWorld|p1|2|0', 'oldWorld|p1|0|0', 'oldWorld|p1|1|0'},
        },
      );

      cache.refresh(snapshotForPlayer('gp1'));

      expect(
        cache.sorted('gp1', kWorkTargetExplore),
        ['oldWorld|p1|0|0', 'oldWorld|p1|1|0', 'oldWorld|p1|2|0'],
      );
    });

    test('contains returns false for missing membership', () {
      final cache = PerPlayerWorkTargetSelectionCache(
        strategies: {
          kWorkTargetBuildImprovement: (_) => {'oldWorld|p2|1|1'},
        },
      );

      cache.refresh(snapshotForPlayer('gp1'));

      expect(
        cache.contains('gp1', kWorkTargetBuildImprovement, 'oldWorld|p2|2|2'),
        isFalse,
      );
    });

    test('refresh replaces target membership on turn-boundary style update', () {
      var turnNumber = 1;
      final cache = PerPlayerWorkTargetSelectionCache(
        strategies: {
          kWorkTargetExplore: (_) => turnNumber == 1 ? {'oldWorld|p1|0|0'} : {'oldWorld|p1|1|0'},
        },
      );

      final snapshot = snapshotForPlayer('gp1');
      cache.refresh(snapshot);
      expect(cache.get('gp1', kWorkTargetExplore), {'oldWorld|p1|0|0'});

      turnNumber = 2;
      cache.refresh(snapshot);
      expect(cache.get('gp1', kWorkTargetExplore), {'oldWorld|p1|1|0'});
      expect(cache.contains('gp1', kWorkTargetExplore, 'oldWorld|p1|0|0'), isFalse);
    });

    test('refresh keeps cache isolated per player', () {
      final cache = PerPlayerWorkTargetSelectionCache(
        strategies: {
          kWorkTargetExplore: (snapshot) => {'${snapshot.playerId}|tile'},
        },
      );

      cache.refresh(snapshotForPlayer('gp1'));
      cache.refresh(snapshotForPlayer('gp2'));

      expect(cache.get('gp1', kWorkTargetExplore), {'gp1|tile'});
      expect(cache.get('gp2', kWorkTargetExplore), {'gp2|tile'});
    });
  });
}
